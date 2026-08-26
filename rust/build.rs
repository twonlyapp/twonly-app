use std::io::Result;
fn main() -> Result<()> {
    println!("cargo:rerun-if-changed=../pubspec.yaml");
    if let Ok(pubspec) = std::fs::read_to_string("../pubspec.yaml") {
        if let Some(version) = pubspec
            .lines()
            .find_map(|line| line.strip_prefix("version: "))
        {
            println!(
                "cargo:rustc-env=TWONLY_APP_VERSION={}",
                version.split('+').next().unwrap_or(version)
            );
        }
    }
    let websocket_proto_root = "src/api/proto";
    let websocket_protos = [
        "src/api/proto/api/websocket/client_to_server.proto",
        "src/api/proto/api/websocket/server_to_client.proto",
        "src/api/proto/api/websocket/error.proto",
    ];
    for proto in websocket_protos {
        println!("cargo:rerun-if-changed={proto}");
    }
    prost_build::Config::new()
        .include_file("websocket_protocol.rs")
        .compile_protos(&websocket_protos, &[websocket_proto_root])?;

    prost_build::compile_protos(&["src/user_discovery/types.proto"], &["src/"])?;
    prost_build::Config::new()
        .include_file("client_messages.rs")
        .compile_protos(
            &[
                "../lib/src/model/protobuf/client/messages.proto",
                "../lib/src/model/protobuf/client/data.proto",
                "../lib/src/model/protobuf/client/push_notification.proto",
                "../lib/src/model/protobuf/client/groups.proto",
            ],
            &["../lib/src/model/protobuf/client/"],
        )?;
    prost_build::compile_protos(
        &["src/api/proto/api/http/http_requests.proto"],
        &["src/api/proto/"],
    )?;
    Ok(())
}
