use std::collections::HashSet;
use alpm::{Alpm, SigLevel};
use async_trait::async_trait;
use crate::domain::entities::Package;
use crate::domain::repositories::PackageRepository;

pub struct AlpmPackageRepository {
    db_path: String,
    root: String,
}

impl AlpmPackageRepository {
    pub fn new() -> Self {
        Self {
            root: "/".to_string(),
            db_path: "/var/lib/pacman".to_string(),
        }
    }

    fn open_handle(&self) -> anyhow::Result<Alpm> {
        let handle = Alpm::new(self.root.as_str(), self.db_path.as_str())?;
        Ok(handle)
    }

    fn open_handle_with_syncs(&self) -> anyhow::Result<Alpm> {
        let handle = self.open_handle()?;
        for dbname in ["core", "extra", "multilib"] {
            let _ = handle.register_syncdb(dbname, SigLevel::DATABASE_OPTIONAL);
        }
        Ok(handle)
    }

    fn get_icon_from_desktop(&self, file_path: &str) -> String {
        if let Ok(content) = std::fs::read_to_string(file_path) {
            for line in content.lines() {
                if let Some(icon) = line.strip_prefix("Icon=") {
                    return icon.trim().to_string();
                }
            }
        }
        String::new()
    }

    fn get_exec_from_desktop(&self, file_path: &str) -> Option<String> {
        if let Ok(content) = std::fs::read_to_string(file_path) {
            for line in content.lines() {
                if let Some(exec) = line.strip_prefix("Exec=") {
                    return Some(exec.trim().to_string());
                }
            }
        }
        None
    }

    /// In alpm v5, `file.name()` returns `&[u8]`, so we convert to str.
    fn bytes_to_str(b: &[u8]) -> &str {
        std::str::from_utf8(b).unwrap_or("")
    }

    fn find_desktop_file(&self, handle: &Alpm, pkg_name: &str) -> Option<String> {
        let localdb = handle.localdb();
        if let Ok(pkg) = localdb.pkg(pkg_name) {
            for file in pkg.files().files() {
                let path = Self::bytes_to_str(file.name());
                if path.contains("usr/share/applications/") && path.ends_with(".desktop") {
                    return Some(format!("/{}", path));
                }
            }
        }
        None
    }

    pub fn is_installed_sync(&self, pkg_name: &str) -> bool {
        match self.open_handle() {
            Ok(handle) => handle.localdb().pkg(pkg_name).is_ok(),
            Err(_) => false,
        }
    }

    pub fn get_installed_version_sync(&self, pkg_name: &str) -> String {
        match self.open_handle() {
            Ok(handle) => handle
                .localdb()
                .pkg(pkg_name)
                .map(|p| p.version().to_string())
                .unwrap_or_default(),
            Err(_) => String::new(),
        }
    }

    pub fn get_installed_icon_sync(&self, pkg_name: &str) -> String {
        match self.open_handle_with_syncs() {
            Ok(handle) => {
                if let Some(path) = self.find_desktop_file(&handle, pkg_name) {
                    return self.get_icon_from_desktop(&path);
                }
                String::new()
            }
            Err(_) => String::new(),
        }
    }

    /// Returns the Exec= field from the .desktop file of a package.
    pub async fn get_desktop_exec(&self, pkg_name: &str) -> Option<String> {
        let this = Self::new();
        let name = pkg_name.to_string();
        tokio::task::spawn_blocking(move || {
            match this.open_handle_with_syncs() {
                Ok(handle) => {
                    if let Some(path) = this.find_desktop_file(&handle, &name) {
                        return this.get_exec_from_desktop(&path);
                    }
                    None
                }
                Err(_) => None,
            }
        })
        .await
        .unwrap_or(None)
    }

    /// Returns all ALPM groups from sync databases.
    pub async fn get_alpm_groups(&self) -> Vec<String> {
        let this = Self::new();
        tokio::task::spawn_blocking(move || {
            let mut groups = HashSet::new();
            if let Ok(handle) = this.open_handle_with_syncs() {
                for db in handle.syncdbs() {
                    for pkg in db.pkgs() {
                        for group in pkg.groups() {
                            groups.insert(group.to_string());
                        }
                    }
                }
            }
            let mut v: Vec<String> = groups.into_iter().filter(|g| !g.is_empty()).collect();
            v.sort();
            v
        })
        .await
        .unwrap_or_default()
    }

    pub async fn get_updatable(&self) -> Vec<Package> {
        let this = Self::new();
        tokio::task::spawn_blocking(move || {
            let mut updates = vec![];
            let Ok(handle) = this.open_handle_with_syncs() else { return updates; };
            let localdb = handle.localdb();

            for pkg in localdb.pkgs() {
                for db in handle.syncdbs() {
                    if let Ok(sync_pkg) = db.pkg(pkg.name()) {
                        if alpm::vercmp(pkg.version().as_str(), sync_pkg.version().as_str()).is_lt() {
                            let icon = this.get_installed_icon_sync(pkg.name());
                            updates.push(Package {
                                name: pkg.name().to_string(),
                                title: pkg.name().to_string(),
                                desc: pkg.desc().unwrap_or("").to_string(),
                                version: sync_pkg.version().to_string(),
                                pkg_type: "pacman".to_string(),
                                installed: true,
                                installed_version: pkg.version().to_string(),
                                icon,
                            });
                            break;
                        }
                    }
                }
            }
            updates
        })
        .await
        .unwrap_or_default()
    }

    pub async fn get_packages_by_group(&self, group_name: &str) -> Vec<Package> {
        let this = Self::new();
        let group = group_name.to_string();
        tokio::task::spawn_blocking(move || {
            let mut results = vec![];
            let mut seen = HashSet::new();
            let Ok(handle) = this.open_handle_with_syncs() else { return results; };

            for db in handle.syncdbs() {
                for pkg in db.pkgs() {
                    if pkg.groups().into_iter().any(|g| g == group) {
                        if !seen.insert(pkg.name().to_string()) {
                            continue;
                        }
                        let installed = handle.localdb().pkg(pkg.name()).is_ok();
                        let installed_version = if installed {
                            handle
                                .localdb()
                                .pkg(pkg.name())
                                .map(|p| p.version().to_string())
                                .unwrap_or_default()
                        } else {
                            String::new()
                        };
                        let icon = if installed {
                            this.get_installed_icon_sync(pkg.name())
                        } else {
                            String::new()
                        };
                        results.push(Package {
                            name: pkg.name().to_string(),
                            title: pkg.name().to_string(),
                            desc: pkg.desc().unwrap_or("").to_string(),
                            version: pkg.version().to_string(),
                            pkg_type: "pacman".to_string(),
                            installed,
                            installed_version,
                            icon,
                        });
                    }
                }
            }
            results
        })
        .await
        .unwrap_or_default()
    }
}

#[async_trait]
impl PackageRepository for AlpmPackageRepository {
    async fn search(&self, query: &str) -> Vec<Package> {
        let this = Self::new();
        let q = query.to_lowercase();
        tokio::task::spawn_blocking(move || {
            let mut results = vec![];
            let mut seen = HashSet::new();
            let Ok(handle) = this.open_handle_with_syncs() else { return results; };

            for db in handle.syncdbs() {
                for pkg in db.search(std::iter::once(q.as_str())).unwrap_or_default() {
                    if !seen.insert(pkg.name().to_string()) {
                        continue;
                    }
                    let installed = handle.localdb().pkg(pkg.name()).is_ok();
                    let installed_version = if installed {
                        handle
                            .localdb()
                            .pkg(pkg.name())
                            .map(|p| p.version().to_string())
                            .unwrap_or_default()
                    } else {
                        String::new()
                    };
                    let icon = if installed {
                        this.get_installed_icon_sync(pkg.name())
                    } else {
                        String::new()
                    };
                    results.push(Package {
                        name: pkg.name().to_string(),
                        title: pkg.name().to_string(),
                        desc: pkg.desc().unwrap_or("").to_string(),
                        version: pkg.version().to_string(),
                        pkg_type: "pacman".to_string(),
                        installed,
                        installed_version,
                        icon,
                    });
                }
            }
            results
        })
        .await
        .unwrap_or_default()
    }

    async fn get_installed(&self) -> Vec<Package> {
        let this = Self::new();
        tokio::task::spawn_blocking(move || {
            let mut installed = vec![];
            let Ok(handle) = this.open_handle_with_syncs() else { return installed; };
            let localdb = handle.localdb();

            for pkg in localdb.pkgs() {
                // Only include packages with a .desktop file (GUI apps)
                let desktop_path = this.find_desktop_file(&handle, pkg.name());
                let Some(path) = desktop_path else { continue; };

                let icon = this.get_icon_from_desktop(&path);
                let is_official = handle.syncdbs().into_iter().any(|db| db.pkg(pkg.name()).is_ok());
                let pkg_type = if is_official { "pacman" } else { "aur" };

                installed.push(Package {
                    name: pkg.name().to_string(),
                    title: pkg.name().to_string(),
                    desc: pkg.desc().unwrap_or("").to_string(),
                    version: pkg.version().to_string(),
                    pkg_type: pkg_type.to_string(),
                    installed: true,
                    installed_version: pkg.version().to_string(),
                    icon,
                });
            }
            installed
        })
        .await
        .unwrap_or_default()
    }

    async fn get_install_command(&self, pkg_name: &str) -> Vec<String> {
        vec![
            "sudo".into(), "-A".into(), "pacman".into(),
            "-S".into(), "--noconfirm".into(), pkg_name.to_string(),
        ]
    }

    async fn get_uninstall_command(&self, pkg_name: &str) -> Vec<String> {
        vec![
            "sudo".into(), "-A".into(), "pacman".into(),
            "-Rns".into(), "--noconfirm".into(), pkg_name.to_string(),
        ]
    }
}
