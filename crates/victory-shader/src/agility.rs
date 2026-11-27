//! The D3D12 Agility SDK exports: which D3D12 runtime the host uses.
//!
//! Windows 10's in-box runtime stops at shader model 6.5 and refuses root
//! signatures that index the descriptor heaps directly (flags 0x400, 0x800),
//! which every translated pipeline uses. D3D12 looks for these two exports on
//! the process's executable; when they name a runtime newer than the system's,
//! it loads `D3D12Core.dll` from `D3D12SDKPath` (relative to the executable)
//! instead. `cargo xtask agility` puts it beside both `victory.exe` and the
//! `cargo test` executables, which also create D3D12 devices.
//!
//! This module is shared by the application and GPU tests so the symbols are
//! defined once. Their build scripts export the symbols on MSVC.

#![allow(non_upper_case_globals)]

/// The runtime's SDK version: the minor number of the
/// `Microsoft.Direct3D.D3D12` package `cargo xtask agility` fetches
/// (1.620.2). Keep the two in step. User override on 2026-11-26: 620 replaces
/// the earlier 614 pin despite the RDNA2 device-removal report
/// (Marvisak/VIctory#746); pre-override evidence used 614.
#[unsafe(no_mangle)]
#[used]
pub static D3D12SDKVersion: u32 = 620;

/// A C string pointer D3D12 reads once at device creation.
#[repr(transparent)]
pub struct SdkPath(*const std::ffi::c_char);

// SAFETY: points at a static, immutable C string.
unsafe impl Sync for SdkPath {}

/// Where `D3D12Core.dll` is, relative to the executable.
#[unsafe(no_mangle)]
#[used]
pub static D3D12SDKPath: SdkPath = SdkPath(c".\\D3D12\\".as_ptr());

/// The folder `D3D12SDKPath` names, beside the running executable.
pub fn runtime_dir() -> Option<std::path::PathBuf> {
    Some(std::env::current_exe().ok()?.parent()?.join("D3D12"))
}
