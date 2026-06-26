use std::sync::Arc;
use crate::domain::entities::Package;
use crate::config::AppConfig;

/// Aggregates update information from ALPM, AUR, and Flatpak repositories.
/// Uses concrete types because the updatable methods are not part of the base trait.
pub struct GetUpdatablePackagesUseCase {
    pub alpm_repo: Arc<crate::data::alpm_repository::AlpmPackageRepository>,
    pub aur_repo: Arc<crate::data::aur_repository::AurPackageRepository>,
    pub flatpak_repo: Arc<crate::data::flatpak_repository::FlatpakPackageRepository>,
}

impl GetUpdatablePackagesUseCase {
    pub fn new(
        alpm_repo: Arc<crate::data::alpm_repository::AlpmPackageRepository>,
        aur_repo: Arc<crate::data::aur_repository::AurPackageRepository>,
        flatpak_repo: Arc<crate::data::flatpak_repository::FlatpakPackageRepository>,
    ) -> Self {
        Self { alpm_repo, aur_repo, flatpak_repo }
    }

    pub async fn execute(&self, config: &AppConfig) -> Vec<Package> {
        let alpm_fut = self.alpm_repo.get_updatable();
        let aur_fut = async {
            if config.enable_aur {
                self.aur_repo.get_updatable(&self.alpm_repo).await
            } else {
                vec![]
            }
        };
        let flatpak_fut = async {
            if config.enable_flatpak {
                self.flatpak_repo.get_updatable().await
            } else {
                vec![]
            }
        };

        let (alpm, aur, flatpak) = tokio::join!(alpm_fut, aur_fut, flatpak_fut);
        let mut all = alpm;
        all.extend(aur);
        all.extend(flatpak);
        all
    }
}
