use std::sync::Arc;
use crate::domain::{entities::Package, repositories::FeaturedRepository};

pub struct GetFeaturedPackagesUseCase {
    pub appstream_repo: Arc<dyn FeaturedRepository>,
}
impl GetFeaturedPackagesUseCase {
    pub fn new(appstream_repo: Arc<dyn FeaturedRepository>) -> Self {
        Self { appstream_repo }
    }
    pub async fn execute(&self) -> Vec<Package> {
        self.appstream_repo.get_featured_packages().await
    }
}
