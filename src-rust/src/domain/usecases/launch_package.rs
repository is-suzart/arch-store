use std::process::Command;
use std::sync::Arc;

pub struct LaunchPackageUseCase {
    pub alpm_repo: Arc<crate::data::alpm_repository::AlpmPackageRepository>,
    #[allow(dead_code)]
    pub flatpak_repo: Arc<crate::data::flatpak_repository::FlatpakPackageRepository>,
}

impl LaunchPackageUseCase {
    pub fn new(
        alpm_repo: Arc<crate::data::alpm_repository::AlpmPackageRepository>,
        flatpak_repo: Arc<crate::data::flatpak_repository::FlatpakPackageRepository>,
    ) -> Self {
        Self { alpm_repo, flatpak_repo }
    }

    pub async fn execute(&self, pkg_type: &str, pkg_name: &str) {
        match pkg_type {
            "flatpak" => {
                let _ = Command::new("flatpak")
                    .args(["run", pkg_name])
                    .spawn();
            }
            "pacman" | "aur" => {
                // Try to find the .desktop exec for this package
                if let Some(exec) = self.alpm_repo.get_desktop_exec(pkg_name).await {
                    // Strip field codes like %U, %F, etc.
                    let clean: String = exec
                        .split_whitespace()
                        .filter(|p| !p.starts_with('%'))
                        .collect::<Vec<_>>()
                        .join(" ");
                    if !clean.is_empty() {
                        let parts: Vec<&str> = clean.split_whitespace().collect();
                        let _ = Command::new(parts[0])
                            .args(&parts[1..])
                            .spawn();
                    }
                }
            }
            _ => {}
        }
    }
}
