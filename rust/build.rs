use std::io::Result;
fn main() -> Result<()> {
    // The version the server compares against its minimum version setting.
    // A build that cannot determine it has to fail here rather than ship a
    // placeholder, which the server would read as an ancient client.
    println!("cargo:rerun-if-changed=../pubspec.yaml");
    let pubspec =
        std::fs::read_to_string("../pubspec.yaml").expect("could not read ../pubspec.yaml");
    let version = pubspec
        .lines()
        .find_map(|line| line.strip_prefix("version: "))
        .map(|version| version.split('+').next().unwrap_or(version).trim())
        .expect("no `version:` entry in ../pubspec.yaml");
    println!("cargo:rustc-env=TWONLY_APP_VERSION={version}");
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

    prost_build::compile_protos(&["models/user_discovery.proto"], &["src/"])?;
    let client_proto_root = "src/api/proto/client";
    let client_protos = [
        "src/api/proto/client/transport.proto",
        "src/api/proto/client/groups.proto",
        "src/api/proto/client/messages.proto",
        "src/api/proto/client/data.proto",
    ];
    for proto in &client_protos {
        println!("cargo:rerun-if-changed={proto}");
    }
    prost_build::Config::new()
        .include_file("client_messages.rs")
        .compile_protos(&client_protos, &[client_proto_root])?;
    println!("cargo:rerun-if-changed=src/api/proto/api/http/http_requests.proto");
    prost_build::compile_protos(
        &["src/api/proto/api/http/http_requests.proto"],
        &["src/api/proto/"],
    )?;
    Ok(())
}
