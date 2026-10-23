//! Shared HTTP TLS configuration. Keep the bundled WebPKI roots and ring
//! provider used before reqwest 0.13, including on Android background threads.

use std::sync::{Arc, OnceLock};

pub(crate) fn client_builder() -> reqwest::ClientBuilder {
    static TLS: OnceLock<rustls::ClientConfig> = OnceLock::new();

    let tls = TLS.get_or_init(|| {
        let roots = rustls::RootCertStore {
            roots: webpki_roots::TLS_SERVER_ROOTS.to_vec(),
        };

        rustls::ClientConfig::builder_with_provider(Arc::new(
            rustls::crypto::ring::default_provider(),
        ))
        .with_safe_default_protocol_versions()
        .expect("ring supports the default TLS versions")
        .with_root_certificates(roots)
        .with_no_client_auth()
    });

    reqwest::Client::builder().tls_backend_preconfigured(tls.clone())
}

#[cfg(test)]
mod tests {
    use std::io::{BufRead, BufReader, Read, Write};
    use std::time::Duration;

    #[test]
    fn builds_without_a_global_crypto_provider_or_platform_initialization() {
        super::client_builder().build().unwrap();
    }

    #[tokio::test]
    async fn configured_client_sends_binary_bodies_and_preserves_error_responses() {
        let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        let server = std::thread::spawn(move || {
            let (socket, _) = listener.accept().unwrap();
            socket
                .set_read_timeout(Some(Duration::from_secs(5)))
                .unwrap();
            let mut stream = BufReader::new(socket);
            let mut request = String::new();
            stream.read_line(&mut request).unwrap();
            assert_eq!(request, "POST /protobuf HTTP/1.1\r\n");

            loop {
                let mut header = String::new();
                assert_ne!(stream.read_line(&mut header).unwrap(), 0);
                if header == "\r\n" {
                    break;
                }
            }

            let mut body = [0_u8; 4];
            stream.read_exact(&mut body).unwrap();
            assert_eq!(body, [0, 128, 255, 1]);
            stream.get_mut().write_all(
                b"HTTP/1.1 409 Conflict\r\nContent-Length: 8\r\nConnection: close\r\n\r\nconflict",
            ).unwrap();
        });

        let response = super::client_builder()
            .timeout(Duration::from_secs(5))
            .build()
            .unwrap()
            .post(format!("http://{address}/protobuf"))
            .body(vec![0, 128, 255, 1])
            .send()
            .await
            .unwrap();

        assert_eq!(response.status(), reqwest::StatusCode::CONFLICT);
        assert_eq!(response.bytes().await.unwrap().as_ref(), b"conflict");
        server.join().unwrap();
    }
}

/// Credentials for uploads from either Flutter or an OS-owned runtime.
pub(crate) async fn authentication_headers(
    ctx: &crate::context::Context,
) -> crate::error::Result<std::collections::HashMap<String, String>> {
    use crate::error::TwonlyError;
    use base64::Engine as _;
    let user = crate::user_config::UserConfig::load_required_from(ctx)?;
    let mut headers = std::collections::HashMap::new();
    if user.can_use_login_token_for_auth {
        let login_token = ctx.key_manager.lock().await.main_key.get_login_token();
        headers.insert("x-twonly-user-id".into(), format!("{:016X}", user.user_id));
        headers.insert("x-twonly-login-token".into(), hex::encode(login_token));
    } else {
        let encoded = ctx
            .secure_storage
            .read("api_auth_token")?
            .ok_or_else(|| TwonlyError::Generic("API auth token is not defined".into()))?;
        let auth_token = base64::engine::general_purpose::STANDARD
            .decode(encoded)
            .map_err(|error| {
                TwonlyError::Generic(format!("invalid stored API auth token: {error}"))
            })?;
        headers.insert("x-twonly-auth-token".into(), hex::encode(auth_token));
    }
    Ok(headers)
}
