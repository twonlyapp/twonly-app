use std::io::Result;
fn main() -> Result<()> {
    prost_build::compile_protos(&["src/user_discovery/types.proto"], &["src/"])?;
    prost_build::compile_protos(&["src/passwordless_recovery/types.proto"], &["src/"])?;
    Ok(())
}
