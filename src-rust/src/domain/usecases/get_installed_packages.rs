use std::sync::Arc;
use crate::domain::{entities::Package, repositories::PackageRepository};
use crate::config::AppConfig;

pub struct GetInstalledPackagesUseCase {
    pub alpm_repo: Arc<dyn PackageRepository>,
    pub flatpak_repo: Arc<dyn PackageRepository>,
}

impl GetInstalledPackagesUseCase {
    pub fn new(
        alpm_repo: Arc<dyn PackageRepository>,
        flatpak_repo: Arc<dyn PackageRepository>,
    ) -> Self {
        Self { alpm_repo, flatpak_repo }
    }

    pub async fn execute(&self, config: &AppConfig) -> Vec<Package> {
        let alpm_fut = self.alpm_repo.get_installed();
        let flatpak_fut = async {
            if config.enable_flatpak {
                self.flatpak_repo.get_installed().await
            } else {
                vec![]
            }
        };

        let (alpm, flatpak) = tokio::join!(alpm_fut, flatpak_fut);
        let mut results = alpm;
        results.extend(flatpak);
        results
    }
}
