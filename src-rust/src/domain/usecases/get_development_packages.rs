use std::sync::Arc;
use crate::domain::{entities::Package, repositories::FeaturedRepository};

pub struct GetDevelopmentPackagesUseCase {
    pub appstream_repo: Arc<dyn FeaturedRepository>,
}
impl GetDevelopmentPackagesUseCase {
    pub fn new(appstream_repo: Arc<dyn FeaturedRepository>) -> Self {
        Self { appstream_repo }
    }
    pub async fn execute(&self) -> Vec<Package> {
        self.appstream_repo.get_development_packages().await
    }
}
