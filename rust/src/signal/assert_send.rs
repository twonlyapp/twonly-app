/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use std::future::Future;
use std::pin::Pin;
use std::task::{Context, Poll};

pub struct AssertSendFuture<F>(F);

unsafe impl<F> Send for AssertSendFuture<F> {}
unsafe impl<F> Sync for AssertSendFuture<F> {}

impl<F: Future> Future for AssertSendFuture<F> {
    type Output = F::Output;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        unsafe { self.map_unchecked_mut(|s| &mut s.0) }.poll(cx)
    }
}

pub trait AssertSendFutureExt: Sized + Future {
    fn assert_send(self) -> AssertSendFuture<Self> {
        AssertSendFuture(self)
    }
}

impl<F: Future> AssertSendFutureExt for F {}
