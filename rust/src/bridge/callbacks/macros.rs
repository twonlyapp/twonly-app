#[macro_export]
macro_rules! callback_generator {
    (
        $struct_name:ident {
            $(
                $sub_struct_name:ident $sub_struct_field:ident {
                    $(
                        $fn_name:ident : ($($input:ty),*) => $output:ty
                    ),* $(,)?
                }
            ),* $(,)?
        }
    ) => {
        // 1. Generate the Nested Sub-Structs
        $(
            pub(crate) struct $sub_struct_name {
                $(
                    pub(crate) $fn_name: Arc<dyn Fn($($input),*) -> DartFnFuture<$output> + Send + Sync + 'static>,
                )*
            }
        )*

        // 2. Generate the Main Container Struct
        pub(crate) struct $struct_name {
            $(
                pub(crate) $sub_struct_field: $sub_struct_name,
            )*
        }

        // 3. Generate the Automated Init Function
        paste::paste! {
            pub fn init_flutter_callbacks(
                $(
                    $(
                        // Parameters: sub-struct_field + _ + fn_name
                        [<$sub_struct_field _ $fn_name>]: impl Fn($($input),*) -> DartFnFuture<$output> + Send + Sync + 'static,
                    )*
                )*
            ) {
                let callbacks = $struct_name {
                    $(
                        $sub_struct_field: $sub_struct_name {
                            $(
                                $fn_name: Arc::new([<$sub_struct_field _ $fn_name>]),
                            )*
                        },
                    )*
                };

                // Use the static global strictly named FLUTTER_CALLBACKS
                FLUTTER_CALLBACKS.set(callbacks).unwrap_or_else(|_| {
                    println!("Callbacks were already initialized!");
                });
            }
        }
    };
}
