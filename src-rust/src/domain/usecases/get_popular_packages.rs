use std::sync::Arc;
use crate::domain::{entities::Package, repositories::PackageRepository};

#[allow(dead_code)]
pub struct GetPopularPackagesUseCase {
    pub flatpak_repo: Arc<dyn PackageRepository>,
}
#[allow(dead_code)]
impl GetPopularPackagesUseCase {
    pub fn new(flatpak_repo: Arc<dyn PackageRepository>) -> Self {
        Self { flatpak_repo }
    }
    pub async fn execute(&self) -> Vec<Package> {
        // Flatpak repo exposes get_popular via a downcast-friendly wrapper
        // We use a trait extension pattern: FlatpakPopularRepository
        // For now delegate through the repo's special method via Arc<FlatpakPackageRepository>
        // This will be resolved by using Arc<FlatpakPackageRepository> directly in AppState
        vec![]
    }
}
