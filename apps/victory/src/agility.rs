//! The D3D12 Agility SDK: which D3D12 runtime the host uses.
//!
//! The exports live in `victory_shader::agility` so the application and the
//! GPU test executables define them only once. `build.rs` puts them on this
//! executable, which makes D3D12 load `D3D12Core.dll` from `D3D12SDKPath`;
//! `cargo xtask agility` puts it there. See the shared module for details.

pub use victory_shader::agility::{D3D12SDKVersion, runtime_dir};
