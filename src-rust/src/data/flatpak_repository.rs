use std::collections::HashMap;
use async_trait::async_trait;
use serde::Deserialize;
use crate::domain::entities::Package;
use crate::domain::repositories::PackageRepository;

pub struct FlatpakPackageRepository {
    client: reqwest::Client,
}

impl FlatpakPackageRepository {
    pub fn new() -> Self {
        Self {
            client: reqwest::Client::builder()
                .timeout(std::time::Duration::from_secs(10))
                .build()
                .expect("Failed to build reqwest client"),
        }
    }

    /// Returns a map of { app_id -> version } for all installed flatpaks.
    pub async fn get_installed_flatpaks(&self) -> HashMap<String, String> {
        tokio::task::spawn_blocking(|| {
            let output = std::process::Command::new("flatpak")
                .args(["list", "--app", "--columns=application,version"])
                .output();

            let mut map = HashMap::new();
            if let Ok(out) = output {
                let text = String::from_utf8_lossy(&out.stdout);
                for line in text.lines() {
                    let parts: Vec<&str> = line.splitn(2, '\t').collect();
                    if parts.len() == 2 {
                        map.insert(parts[0].trim().to_string(), parts[1].trim().to_string());
                    }
                }
            }
            map
        })
        .await
        .unwrap_or_default()
    }

    #[allow(dead_code)]
    pub async fn is_installed(&self, app_id: &str) -> bool {
        self.get_installed_flatpaks().await.contains_key(app_id)
    }

    pub async fn get_popular(&self) -> Vec<Package> {
        let installed = self.get_installed_flatpaks().await;
        let url = "https://flathub.org/api/v2/collection/popular";
        match self.client.get(url).send().await {
            Ok(resp) => {
                if let Ok(data) = resp.json::<FlathubCollectionResponse>().await {
                    data.hits.into_iter().take(12).filter_map(|hit| {
                        let app_id = hit.app_id.or(hit.id)?;
                        let is_installed = installed.contains_key(&app_id);
                        Some(Package {
                            installed_version: if is_installed {
                                installed.get(&app_id).cloned().unwrap_or_default()
                            } else {
                                String::new()
                            },
                            name: app_id.clone(),
                            title: hit.name.unwrap_or_else(|| app_id.clone()),
                            desc: hit.summary.unwrap_or_default(),
                            version: hit.version.unwrap_or_else(|| "latest".into()),
                            pkg_type: "flatpak".to_string(),
                            installed: is_installed,
                            icon: hit.icon.unwrap_or_default(),
                        })
                    }).collect()
                } else {
                    vec![]
                }
            }
            Err(e) => {
                eprintln!("Error fetching popular flatpaks: {}", e);
                vec![]
            }
        }
    }

    pub async fn get_updatable(&self) -> Vec<Package> {
        // flatpak remote-ls with update check is slow; use `flatpak update --dry-run`
        tokio::task::spawn_blocking(|| {
            let output = std::process::Command::new("flatpak")
                .args(["update", "--dry-run", "--app", "--columns=application,version"])
                .output();

            let mut updates = vec![];
            if let Ok(out) = output {
                let text = String::from_utf8_lossy(&out.stdout);
                for line in text.lines() {
                    let parts: Vec<&str> = line.splitn(2, '\t').collect();
                    if parts.len() == 2 {
                        let app_id = parts[0].trim().to_string();
                        let new_version = parts[1].trim().to_string();
                        updates.push(Package {
                            name: app_id.clone(),
                            title: app_id.clone(),
                            desc: String::new(),
                            version: new_version,
                            pkg_type: "flatpak".to_string(),
                            installed: true,
                            installed_version: String::new(),
                            icon: String::new(),
                        });
                    }
                }
            }
            updates
        })
        .await
        .unwrap_or_default()
    }
}

#[async_trait]
impl PackageRepository for FlatpakPackageRepository {
    async fn search(&self, query: &str) -> Vec<Package> {
        let installed = self.get_installed_flatpaks().await;
        let payload = serde_json::json!({"query": query});

        match self.client
            .post("https://flathub.org/api/v2/search")
            .json(&payload)
            .send()
            .await
        {
            Ok(resp) => {
                if let Ok(data) = resp.json::<FlathubSearchResponse>().await {
                    data.hits.into_iter().take(30).filter_map(|hit| {
                        let app_id = hit.app_id.or(hit.id)?;
                        let is_installed = installed.contains_key(&app_id);
                        Some(Package {
                            installed_version: if is_installed {
                                installed.get(&app_id).cloned().unwrap_or_default()
                            } else {
                                String::new()
                            },
                            name: app_id.clone(),
                            title: hit.name.unwrap_or_else(|| app_id.clone()),
                            desc: hit.summary.unwrap_or_default(),
                            version: hit.version.unwrap_or_default(),
                            pkg_type: "flatpak".to_string(),
                            installed: is_installed,
                            icon: hit.icon.unwrap_or_default(),
                        })
                    }).collect()
                } else {
                    vec![]
                }
            }
            Err(e) => {
                eprintln!("Flatpak search error: {}", e);
                vec![]
            }
        }
    }

    async fn get_installed(&self) -> Vec<Package> {
        tokio::task::spawn_blocking(|| {
            let output = std::process::Command::new("flatpak")
                .args([
                    "list", "--app",
                    "--columns=application,name,description,version",
                ])
                .output();

            let mut pkgs = vec![];
            if let Ok(out) = output {
                let text = String::from_utf8_lossy(&out.stdout);
                for line in text.lines() {
                    let parts: Vec<&str> = line.splitn(4, '\t').collect();
                    if parts.is_empty() { continue; }
                    let app_id = parts[0].trim().to_string();
                    let title   = parts.get(1).map(|s| s.trim().to_string()).unwrap_or_else(|| app_id.clone());
                    let desc    = parts.get(2).map(|s| s.trim().to_string()).unwrap_or_default();
                    let version = parts.get(3).map(|s| s.trim().to_string()).unwrap_or_default();
                    pkgs.push(Package {
                        name: app_id.clone(),
                        title,
                        desc,
                        version: version.clone(),
                        pkg_type: "flatpak".to_string(),
                        installed: true,
                        installed_version: version,
                        icon: String::new(),
                    });
                }
            }
            pkgs
        })
        .await
        .unwrap_or_default()
    }

    async fn get_install_command(&self, pkg_name: &str) -> Vec<String> {
        vec![
            "sh".into(), "-c".into(),
            format!(
                "flatpak remote-add --user --if-not-exists flathub \
                 https://flathub.org/repo/flathub.flatpakrepo && \
                 flatpak install --user -y flathub '{}'",
                pkg_name
            ),
        ]
    }

    async fn get_uninstall_command(&self, pkg_name: &str) -> Vec<String> {
        vec!["flatpak".into(), "uninstall".into(), "--user".into(), "-y".into(), pkg_name.to_string()]
    }
}

// ─── Flathub API types ───────────────────────────────────────────────────────

#[derive(Deserialize)]
struct FlathubSearchResponse {
    hits: Vec<FlathubHit>,
}

#[derive(Deserialize)]
struct FlathubCollectionResponse {
    hits: Vec<FlathubHit>,
}

#[derive(Deserialize)]
struct FlathubHit {
    app_id: Option<String>,
    id: Option<String>,
    name: Option<String>,
    summary: Option<String>,
    version: Option<String>,
    icon: Option<String>,
}
