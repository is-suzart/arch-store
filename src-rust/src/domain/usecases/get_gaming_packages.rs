use std::sync::Arc;
use crate::domain::{entities::Package, repositories::FeaturedRepository};

pub struct GetGamingPackagesUseCase {
    pub appstream_repo: Arc<dyn FeaturedRepository>,
}
impl GetGamingPackagesUseCase {
    pub fn new(appstream_repo: Arc<dyn FeaturedRepository>) -> Self {
        Self { appstream_repo }
    }
    pub async fn execute(&self) -> Vec<Package> {
        self.appstream_repo.get_gaming_packages().await
    }
}
