fn main() {
    // The D3D12 Agility SDK exports (victory_shader::agility): D3D12 finds
    // them on the executable. /INCLUDE pulls the symbols out of the rlib;
    // only the MSVC linker takes /EXPORT on a binary.
    if std::env::var("CARGO_CFG_TARGET_ENV").as_deref() == Ok("msvc") {
        for name in ["D3D12SDKVersion", "D3D12SDKPath"] {
            println!("cargo:rustc-link-arg-bins=/INCLUDE:{name}");
            println!("cargo:rustc-link-arg-bins=/EXPORT:{name},DATA");
        }
    }
}
