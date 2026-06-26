use serde::{Deserialize, Serialize};

/// Representa um pacote de qualquer fonte (pacman, AUR, Flatpak).
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Package {
    pub name: String,
    pub title: String,
    pub desc: String,
    pub version: String,
    /// "pacman", "aur" ou "flatpak"
    #[serde(rename = "type")]
    pub pkg_type: String,
    pub installed: bool,
    #[serde(rename = "installedVersion")]
    pub installed_version: String,
    pub icon: String,
}

/// Pacote enriquecido com dados de hero image e branding (carrosséis da UI).
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct HeroApp {
    pub name: String,
    pub title: String,
    pub desc: String,
    pub version: String,
    #[serde(rename = "type")]
    pub pkg_type: String,
    pub installed: bool,
    #[serde(rename = "installedVersion")]
    pub installed_version: String,
    pub icon: String,
    pub hero_image: String,
    pub brand_color_light: String,
    pub brand_color_dark: String,
}

/// Grupo de pacotes ALPM (ex: "gnome", "kde-system").
#[derive(Debug, Clone, Serialize, Deserialize)]
#[allow(dead_code)]
pub struct PackageGroup {
    pub name: String,
    pub label: String,
}
