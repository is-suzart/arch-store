use std::collections::HashSet;
use async_trait::async_trait;
use serde::Deserialize;
use crate::domain::entities::Package;
use crate::domain::repositories::PackageRepository;
use crate::data::alpm_repository::AlpmPackageRepository;

pub struct AurPackageRepository {
    client: reqwest::Client,
    helper: String,
}

impl AurPackageRepository {
    pub fn new() -> Self {
        let helper = if which("yay") { "yay".into() } else if which("paru") { "paru".into() } else { "yay".into() };
        Self {
            client: reqwest::Client::builder()
                .timeout(std::time::Duration::from_secs(10))
                .build()
                .expect("Failed to build reqwest client"),
            helper,
        }
    }

    pub async fn get_updatable(&self, alpm_repo: &AlpmPackageRepository) -> Vec<Package> {
        // Find foreign (AUR) packages by checking against sync dbs
        let foreign = self.get_foreign_packages(alpm_repo).await;
        if foreign.is_empty() {
            return vec![];
        }

        let mut updates = vec![];
        for chunk in foreign.chunks(50) {
            let args: String = chunk.iter()
                .map(|(name, _)| format!("arg[]={}", urlencoding_encode(name)))
                .collect::<Vec<_>>()
                .join("&");

            let url = format!("https://aur.archlinux.org/rpc/?v=5&type=info&{}", args);
            if let Ok(resp) = self.client.get(&url).send().await {
                if let Ok(data) = resp.json::<AurInfoResponse>().await {
                    for aur_pkg in data.results {
                        let name = &aur_pkg.name;
                        if let Some((_, local_ver)) = chunk.iter().find(|(n, _)| n == name) {
                            if alpm_vercmp_lt(local_ver, &aur_pkg.version) {
                                let icon = alpm_repo.get_installed_icon_sync(name);
                                updates.push(Package {
                                    name: name.clone(),
                                    title: name.clone(),
                                    desc: aur_pkg.description.unwrap_or_default(),
                                    version: aur_pkg.version.clone(),
                                    pkg_type: "aur".to_string(),
                                    installed: true,
                                    installed_version: local_ver.clone(),
                                    icon,
                                });
                            }
                        }
                    }
                }
            }
        }
        updates
    }

    async fn get_foreign_packages(&self, _alpm_repo: &AlpmPackageRepository) -> Vec<(String, String)> {
        // We need to read the local db and compare with sync dbs — do in spawn_blocking
        let root = "/".to_string();
        let db_path = "/var/lib/pacman".to_string();
        tokio::task::spawn_blocking(move || {
            let Ok(handle) = alpm::Alpm::new(root.as_str(), db_path.as_str()) else { return vec![]; };
            for dbname in ["core", "extra", "multilib"] {
                let _ = handle.register_syncdb(dbname, alpm::SigLevel::DATABASE_OPTIONAL);
            }
            let mut foreign = vec![];
            for pkg in handle.localdb().pkgs() {
                let in_sync = handle.syncdbs().into_iter().any(|db| db.pkg(pkg.name()).is_ok());
                if !in_sync {
                    foreign.push((pkg.name().to_string(), pkg.version().to_string()));
                }
            }
            foreign
        })
        .await
        .unwrap_or_default()
    }
}

#[async_trait]
impl PackageRepository for AurPackageRepository {
    async fn search(&self, query: &str) -> Vec<Package> {
        let normalized = query.trim().to_lowercase().replace(' ', "-");
        let mut seen = HashSet::new();
        let mut results = vec![];

        for q in [normalized.as_str(), query.trim()] {
            let url = format!(
                "https://aur.archlinux.org/rpc/?v=5&type=search&by=name-desc&arg={}",
                urlencoding_encode(q)
            );
            if let Ok(resp) = self.client.get(&url).send().await {
                if let Ok(data) = resp.json::<AurSearchResponse>().await {
                    for pkg in data.results {
                        let name = pkg.name.clone();
                        if seen.contains(&name) { continue; }
                        seen.insert(name.clone());

                        results.push(Package {
                            name: name.clone(),
                            title: name.clone(),
                            desc: pkg.description.unwrap_or_default(),
                            version: pkg.version,
                            pkg_type: "aur".to_string(),
                            installed: false,
                            installed_version: String::new(),
                            icon: String::new(),
                        });

                        if results.len() >= 30 { break; }
                    }
                }
            }
            if results.len() >= 30 { break; }
        }
        results
    }

    async fn get_installed(&self) -> Vec<Package> {
        // AUR doesn't have its own concept of "installed" beyond what ALPM knows
        vec![]
    }

    async fn get_install_command(&self, pkg_name: &str) -> Vec<String> {
        vec![
            self.helper.clone(),
            "--sudoflags".into(), "-A".into(),
            "--noconfirm".into(), "-S".into(), pkg_name.to_string(),
        ]
    }

    async fn get_uninstall_command(&self, pkg_name: &str) -> Vec<String> {
        vec![
            self.helper.clone(),
            "--sudoflags".into(), "-A".into(),
            "--noconfirm".into(), "-Rns".into(), pkg_name.to_string(),
        ]
    }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

fn which(cmd: &str) -> bool {
    std::process::Command::new("which")
        .arg(cmd)
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

fn urlencoding_encode(s: &str) -> String {
    s.chars()
        .flat_map(|c| {
            if c.is_ascii_alphanumeric() || "-_.~".contains(c) {
                vec![c]
            } else {
                format!("%{:02X}", c as u32).chars().collect()
            }
        })
        .collect()
}

fn alpm_vercmp_lt(a: &str, b: &str) -> bool {
    // Use alpm::vercmp when available; fall back to simple string compare
    // alpm crate exposes vercmp as a free function
    matches!(alpm::vercmp(a, b), std::cmp::Ordering::Less)
}

// ─── AUR RPC response types ──────────────────────────────────────────────────

#[derive(Deserialize)]
struct AurSearchResponse {
    results: Vec<AurPkgEntry>,
}

#[derive(Deserialize)]
struct AurInfoResponse {
    results: Vec<AurPkgInfo>,
}

#[derive(Deserialize)]
struct AurPkgEntry {
    #[serde(rename = "Name")]
    name: String,
    #[serde(rename = "Version")]
    version: String,
    #[serde(rename = "Description")]
    description: Option<String>,
}

#[derive(Deserialize)]
struct AurPkgInfo {
    #[serde(rename = "Name")]
    name: String,
    #[serde(rename = "Version")]
    version: String,
    #[serde(rename = "Description")]
    description: Option<String>,
}
