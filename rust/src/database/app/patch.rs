/// A present wrapper with a null value explicitly clears a nullable column.
/// An absent wrapper leaves the column unchanged.
#[derive(Debug, Clone)]

pub struct NullableInt {
    pub value: Option<i64>,
}

#[derive(Debug, Clone)]

pub struct NullableText {
    pub value: Option<String>,
}

#[derive(Debug, Clone)]

pub struct NullableBytes {
    pub value: Option<Vec<u8>>,
}

#[derive(Debug, Clone)]

pub struct NullableReal {
    pub value: Option<f64>,
}
