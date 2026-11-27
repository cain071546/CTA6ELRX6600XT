//! Reusable host presets, chosen with `VICTORY_PROFILE`.
//!
//! The defaults in this fork were measured on a 24 GB card. A preset sets
//! only the switches that were sized for that much VRAM, and leaves an
//! explicitly set switch alone: `-More @{VICTORY_TEXTURE_STAGE_MB='128'}`
//! still wins over the preset. `play.ps1 -Profile low-vram` sets
//! `VICTORY_PROFILE` for a run; direct launchers can set it themselves.

use std::ffi::{OsStr, OsString};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) enum Profile {
    Default,
    LowVram,
}

/// The 24 GB-era defaults that are too large for an 8 GB card. Each name is
/// also read where its switch is used; see the table in README.md.
pub(crate) const LOW_VRAM: &[(&str, &str)] = &[
    // A scene's first minutes no longer try to upload 192 MiB every frame.
    ("VICTORY_TEXTURE_STAGE_MB", "96"),
    // Drop idle texture copies after five seconds, not ten minutes.
    ("VICTORY_TEXTURE_KEEP", "0"),
    // Keep the 3 GiB the texture queue leaves for render targets: this is a
    // reservation, so lowering it would let textures fill the card past its
    // budget instead of saving VRAM. On an 8 GB card that overcommit removed
    // the device in the world.
    ("VICTORY_CARD_ROOM_FOR_TARGETS_MB", "3072"),
    // By-address copies are a cap, so this one really can be lowered.
    ("VICTORY_MEMORY_CARD_MB", "1024"),
    // RDNA2 lost the device during first-run library load/compile bursts with
    // many loads in flight; one load/compile at a time kept the same run up.
    ("VICTORY_LIBRARY_LOCK", "1"),
    // VICTORY_KEEP_FREED is deliberately not set to 0: reads past views can
    // then fault memory the driver gave back, losing the device.
];

/// `low-vram` (also `low_vram` or `low`) selects the preset; unset or
/// `default` keeps the measured defaults.
pub(crate) fn parse(value: Option<&OsStr>) -> Option<Profile> {
    match value?
        .to_string_lossy()
        .trim()
        .to_ascii_lowercase()
        .as_str()
    {
        "default" => Some(Profile::Default),
        "low-vram" | "low_vram" | "low" => Some(Profile::LowVram),
        _ => None,
    }
}

pub(crate) fn active() -> Profile {
    parse(std::env::var_os("VICTORY_PROFILE").as_deref()).unwrap_or(Profile::Default)
}

pub(crate) fn name(profile: Profile) -> &'static str {
    match profile {
        Profile::Default => "default",
        Profile::LowVram => "low-vram",
    }
}

/// Apply the preset before the command starts any threads. Explicit values
/// are kept, so a preset is a set of defaults rather than a forced override.
fn value_for(profile: Profile, key: &str, current: Option<&OsStr>) -> Option<OsString> {
    if profile != Profile::LowVram {
        return None;
    }
    let (_, value) = LOW_VRAM.iter().find(|(name, _)| *name == key)?;
    Some(current.map_or_else(|| OsString::from(value), OsStr::to_os_string))
}

pub(crate) fn apply_from_env() {
    let raw = std::env::var_os("VICTORY_PROFILE");
    let Some(profile) = parse(raw.as_deref()) else {
        if let Some(raw) = raw {
            eprintln!(
                "VIctory: ignoring VICTORY_PROFILE={}; use 'default' or 'low-vram'",
                raw.to_string_lossy()
            );
        }
        return;
    };
    for &(key, _) in LOW_VRAM {
        if let Some(value) = value_for(profile, key, std::env::var_os(key).as_deref()) {
            // SAFETY: main calls this before the command starts any threads;
            // every later read of these switches happens after this returns.
            unsafe { std::env::set_var(key, value) };
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_preset_names() {
        assert_eq!(parse(None), None);
        assert_eq!(parse(Some(OsStr::new("default"))), Some(Profile::Default));
        assert_eq!(
            parse(Some(OsStr::new(" LOW-VRAM "))),
            Some(Profile::LowVram)
        );
        assert_eq!(parse(Some(OsStr::new("low_vram"))), Some(Profile::LowVram));
        assert_eq!(parse(Some(OsStr::new("high-vram"))), None);
    }

    #[test]
    fn low_vram_replaces_the_large_card_defaults() {
        let get = |key| value_for(Profile::LowVram, key, None).unwrap();
        assert_eq!(get("VICTORY_TEXTURE_STAGE_MB"), "96");
        assert_eq!(get("VICTORY_TEXTURE_KEEP"), "0");
        assert_eq!(get("VICTORY_CARD_ROOM_FOR_TARGETS_MB"), "3072");
        assert_eq!(get("VICTORY_MEMORY_CARD_MB"), "1024");
        assert_eq!(get("VICTORY_LIBRARY_LOCK"), "1");
        assert!(value_for(Profile::LowVram, "VICTORY_D3D12_ADAPTER", None).is_none());
        assert!(value_for(Profile::LowVram, "VICTORY_KEEP_FREED", None).is_none());
    }

    #[test]
    fn explicit_switches_win_over_the_preset() {
        let got = value_for(
            Profile::LowVram,
            "VICTORY_TEXTURE_STAGE_MB",
            Some(OsStr::new("128")),
        )
        .unwrap();
        assert_eq!(got, "128");
    }

    #[test]
    fn the_default_preset_changes_nothing() {
        for &(key, _) in LOW_VRAM {
            assert_eq!(value_for(Profile::Default, key, None), None);
        }
    }
}
