package io.crates.keyring

import android.content.Context

class Keyring {
    companion object {
        init {
            // Replace with the name of your compiled Rust library
            System.loadLibrary("rust_lib_twonly")
        }
        // The underlying Rust crate provides the implementation for this
        external fun initializeNdkContext(context: Context)
    }
}
