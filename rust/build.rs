use std::io::Result;
fn main() -> Result<()> {
    prost_build::compile_protos(&["src/user_discovery/types.proto"], &["src/"])?;
    prost_build::Config::new()
        .include_file("client_messages.rs")
        .compile_protos(
            &["../lib/src/model/protobuf/client/messages.proto"],
            &["../lib/src/model/protobuf/client/"],
        )?;
    Ok(())
}
