use std::path::PathBuf;
use serde::{Deserialize, Serialize};

fn default_theme_mode() -> String {
    "catppuccin".to_string()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub theme_flavor: String,
    #[serde(default = "default_theme_mode")]
    pub theme_mode: String,
    pub enable_aur: bool,
    pub enable_flatpak: bool,
    pub check_updates_startup: bool,
    pub language: String,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            theme_flavor: "mocha".into(),
            theme_mode: "catppuccin".into(),
            enable_aur: true,
            enable_flatpak: true,
            check_updates_startup: true,
            language: "system".into(),
        }
    }
}

pub fn config_path() -> PathBuf {
    dirs_path().join("config.json")
}

fn dirs_path() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    PathBuf::from(home).join(".config").join("arch-store")
}

pub fn load_config() -> AppConfig {
    let path = config_path();
    if path.exists() {
        if let Ok(text) = std::fs::read_to_string(&path) {
            if let Ok(cfg) = serde_json::from_str::<AppConfig>(&text) {
                return cfg;
            }
        }
    }
    AppConfig::default()
}

pub fn save_config(cfg: &AppConfig) -> anyhow::Result<()> {
    let dir = dirs_path();
    std::fs::create_dir_all(&dir)?;
    let text = serde_json::to_string_pretty(cfg)?;
    std::fs::write(config_path(), text)?;
    Ok(())
}
