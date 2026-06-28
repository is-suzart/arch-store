use std::sync::Arc;
use crate::domain::repositories::PackageRepository;
use crate::config::AppConfig;

pub struct UninstallPackageUseCase {
    pub alpm_repo: Arc<dyn PackageRepository>,
    pub aur_repo: Arc<dyn PackageRepository>,
    pub flatpak_repo: Arc<dyn PackageRepository>,
}

impl UninstallPackageUseCase {
    pub fn new(
        alpm_repo: Arc<dyn PackageRepository>,
        aur_repo: Arc<dyn PackageRepository>,
        flatpak_repo: Arc<dyn PackageRepository>,
    ) -> Self {
        Self { alpm_repo, aur_repo, flatpak_repo }
    }

    pub async fn execute(&self, pkg_type: &str, pkg_name: &str, config: &AppConfig) -> Option<Vec<String>> {
        match pkg_type {
            "pacman" => Some(self.alpm_repo.get_uninstall_command(pkg_name).await),
            "aur"    => {
                if config.enable_aur {
                    Some(self.aur_repo.get_uninstall_command(pkg_name).await)
                } else {
                    None
                }
            }
            "flatpak" => {
                if config.enable_flatpak {
                    Some(self.flatpak_repo.get_uninstall_command(pkg_name).await)
                } else {
                    None
                }
            }
            _ => None,
        }
    }
}
