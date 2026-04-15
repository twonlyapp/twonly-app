use std::io::Result;
fn main() -> Result<()> {
    prost_build::compile_protos(
        &[
            "src/user_discovery/types.proto",
            "src/key_verification/types.proto",
        ],
        &["src/"],
    )?;
    Ok(())
}
