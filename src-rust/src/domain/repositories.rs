use async_trait::async_trait;
use crate::domain::entities::{HeroApp, Package};

/// Repositório genérico de pacotes (pacman/AUR/Flatpak).
#[async_trait]
pub trait PackageRepository: Send + Sync {
    async fn search(&self, query: &str) -> Vec<Package>;
    async fn get_installed(&self) -> Vec<Package>;
    async fn get_install_command(&self, pkg_name: &str) -> Vec<String>;
    async fn get_uninstall_command(&self, pkg_name: &str) -> Vec<String>;
}

/// Repositório de pacotes destaque / curados (AppStream).
#[async_trait]
pub trait FeaturedRepository: Send + Sync {
    async fn get_featured_packages(&self) -> Vec<Package>;
    async fn get_gaming_packages(&self) -> Vec<Package>;
    async fn get_development_packages(&self) -> Vec<Package>;

    async fn get_hero_apps(&self) -> Vec<HeroApp>;
    async fn get_gaming_hero_apps(&self) -> Vec<HeroApp>;
    async fn get_development_hero_apps(&self) -> Vec<HeroApp>;

    async fn get_app_hero_image(&self, name: &str, pkg_type: &str) -> String;
}
