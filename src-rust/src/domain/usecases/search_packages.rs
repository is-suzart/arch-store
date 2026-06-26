use std::sync::Arc;
use crate::domain::{entities::Package, repositories::PackageRepository};
use crate::config::AppConfig;

pub struct SearchPackagesUseCase {
    pub alpm_repo: Arc<dyn PackageRepository>,
    pub aur_repo: Arc<dyn PackageRepository>,
    pub flatpak_repo: Arc<dyn PackageRepository>,
}

impl SearchPackagesUseCase {
    pub fn new(
        alpm_repo: Arc<dyn PackageRepository>,
        aur_repo: Arc<dyn PackageRepository>,
        flatpak_repo: Arc<dyn PackageRepository>,
    ) -> Self {
        Self { alpm_repo, aur_repo, flatpak_repo }
    }

    pub async fn execute(&self, query: &str, config: &AppConfig) -> Vec<Package> {
        if query.trim().len() < 3 {
            return vec![];
        }

        let alpm_fut = self.alpm_repo.search(query);
        let aur_fut = async {
            if config.enable_aur {
                self.aur_repo.search(query).await
            } else {
                vec![]
            }
        };
        let flatpak_fut = async {
            if config.enable_flatpak {
                self.flatpak_repo.search(query).await
            } else {
                vec![]
            }
        };

        let (alpm, aur, flatpak) = tokio::join!(alpm_fut, aur_fut, flatpak_fut);

        let mut results = alpm;
        results.extend(aur);
        results.extend(flatpak);
        results
    }
}
