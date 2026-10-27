//! Convert the pinned source ONNX to the portable NNEF artifact shipped on
//! Android.

use sha2::{Digest, Sha256};
use std::io::Cursor;
use std::path::Path;
use tract_onnx::prelude::*;

fn main() -> anyhow::Result<()> {
    let directory = Path::new(env!("CARGO_MANIFEST_DIR")).join("models");

    let source = std::fs::read(directory.join("u2netp.onnx"))?;

    anyhow::ensure!(
        hex::encode(Sha256::digest(&source))
            == "309c8469258dda742793dce0ebea8e6dd393174f89934733ecc8b14c76f4ddd8",
        "source ONNX digest does not match the pinned model",
    );

    // Keep this architecture-independent: runtime optimization chooses kernels
    // on the actual Android CPU after loading the portable typed graph.
    let model = tract_onnx::onnx()
        .model_for_read(&mut Cursor::new(source))?
        .into_typed()?
        .into_decluttered()?;

    let mut bytes = Vec::new();

    tract_nnef::nnef().write_to_tar_with_config(&model, &mut bytes, false, true)?;

    let output = directory.join("u2netp.nnef.tar");

    std::fs::write(&output, &bytes)?;

    println!("{}: {} bytes", output.display(), bytes.len());

    println!("SHA-256: {}", hex::encode(Sha256::digest(&bytes)));

    Ok(())
}
