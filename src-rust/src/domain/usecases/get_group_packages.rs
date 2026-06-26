use std::sync::Arc;
use crate::domain::entities::Package;

pub struct GetGroupPackagesUseCase {
    pub alpm_repo: Arc<crate::data::alpm_repository::AlpmPackageRepository>,
}

impl GetGroupPackagesUseCase {
    pub fn new(alpm_repo: Arc<crate::data::alpm_repository::AlpmPackageRepository>) -> Self {
        Self { alpm_repo }
    }

    pub async fn execute(&self, group_name: &str) -> Vec<Package> {
        self.alpm_repo.get_packages_by_group(group_name).await
    }
}
