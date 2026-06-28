use std::collections::HashMap;
use std::path::PathBuf;
use async_trait::async_trait;
use crate::domain::entities::{HeroApp, Package};
use crate::domain::repositories::FeaturedRepository;
use crate::data::alpm_repository::AlpmPackageRepository;
use crate::data::flatpak_repository::FlatpakPackageRepository;

/// Calls `appstreamcli dump <app_id>` to get raw XML metadata.
fn appstreamcli_dump(app_id: &str) -> Option<String> {
    let out = std::process::Command::new("appstreamcli")
        .args(["dump", app_id])
        .output()
        .ok()?;
    if !out.status.success() { return None; }
    Some(String::from_utf8_lossy(&out.stdout).to_string())
}

/// Generic helper to extract the contents of simple tags (optionally with attributes)
fn extract_tag_with_attrs(xml: &str, tag: &str) -> String {
    let tag_open = format!("<{tag}");
    if let Some(start) = xml.find(&tag_open) {
        let abs_start = start;
        if let Some(tag_end) = xml[abs_start..].find('>') {
            let val_start = abs_start + tag_end + 1;
            let tag_close = format!("</{tag}>");
            if let Some(end) = xml[val_start..].find(&tag_close) {
                return xml[val_start..val_start + end].trim().to_string();
            }
        }
    }
    String::new()
}

/// Extract all `<icon>` tags and identify their type (stock, cached, remote) and value
fn extract_icons(xml: &str) -> Vec<(String, String)> {
    let mut icons = Vec::new();
    let mut pos = 0;
    while let Some(start) = xml[pos..].find("<icon") {
        let abs_start = pos + start;
        if let Some(tag_end) = xml[abs_start..].find('>') {
            let abs_tag_end = abs_start + tag_end;
            let tag_attrs = &xml[abs_start..abs_tag_end];
            let icon_type = if tag_attrs.contains("type=\"stock\"") {
                "stock"
            } else if tag_attrs.contains("type=\"cached\"") {
                "cached"
            } else if tag_attrs.contains("type=\"remote\"") {
                "remote"
            } else {
                ""
            };
            if let Some(end_idx) = xml[abs_tag_end..].find("</icon>") {
                let abs_end_idx = abs_tag_end + end_idx;
                let val = xml[abs_tag_end + 1 .. abs_end_idx].trim().to_string();
                icons.push((icon_type.to_string(), val));
                pos = abs_end_idx + "</icon>".len();
            } else {
                pos = abs_tag_end + 1;
            }
        } else {
            pos = abs_start + 1;
        }
    }
    icons
}

/// Find the first `<image type="source">` tag and return its URL
fn extract_first_source_image(xml: &str) -> String {
    let mut pos = 0;
    while let Some(start) = xml[pos..].find("<image") {
        let abs_start = pos + start;
        if let Some(tag_end) = xml[abs_start..].find('>') {
            let abs_tag_end = abs_start + tag_end;
            let tag_attrs = &xml[abs_start..abs_tag_end];
            if tag_attrs.contains("type=\"source\"") {
                if let Some(end_idx) = xml[abs_tag_end..].find("</image>") {
                    let abs_end_idx = abs_tag_end + end_idx;
                    return xml[abs_tag_end + 1 .. abs_end_idx].trim().to_string();
                }
            }
            pos = abs_tag_end + 1;
        } else {
            pos = abs_start + 1;
        }
    }
    String::new()
}

/// Parse primary colors from the `<branding>` tag if available
fn extract_branding_colors(xml: &str, fallback_light: &str, fallback_dark: &str) -> (String, String) {
    let mut light = fallback_light.to_string();
    let mut dark = fallback_dark.to_string();
    let mut pos = 0;
    while let Some(start) = xml[pos..].find("<color") {
        let abs_start = pos + start;
        if let Some(tag_end) = xml[abs_start..].find('>') {
            let abs_tag_end = abs_start + tag_end;
            let tag_attrs = &xml[abs_start..abs_tag_end];
            if tag_attrs.contains("type=\"primary\"") {
                if let Some(end_idx) = xml[abs_tag_end..].find("</color>") {
                    let abs_end_idx = abs_tag_end + end_idx;
                    let val = xml[abs_tag_end + 1 .. abs_end_idx].trim().to_string();
                    if !val.is_empty() {
                        if tag_attrs.contains("scheme_preference=\"light\"") {
                            light = val;
                        } else if tag_attrs.contains("scheme_preference=\"dark\"") {
                            dark = val;
                        }
                    }
                    pos = abs_end_idx + "</color>".len();
                    continue;
                }
            }
            pos = abs_tag_end + 1;
        } else {
            pos = abs_start + 1;
        }
    }
    (light, dark)
}

/// Searches `appstreamcli search <pkg_name>` to find the correct `app_id` (Identificador)
/// for a given pacman package name (`Pacote`).
fn find_app_id_by_pkgname(pkg_name: &str) -> Option<String> {
    let out = std::process::Command::new("appstreamcli")
        .args(["search", pkg_name])
        .output()
        .ok()?;
    if !out.status.success() { return None; }
    let text = String::from_utf8_lossy(&out.stdout);
    for block in text.split("---") {
        let mut current_id = None;
        let mut matches_pkg = false;
        for line in block.lines() {
            let line = line.trim();
            if let Some((key, val)) = line.split_once(':') {
                let key = key.trim();
                let val = val.trim();
                if key == "Identificador" {
                    let id = val.split_whitespace().next().unwrap_or(val);
                    current_id = Some(id.to_string());
                } else if key == "Pacote" {
                    if val == pkg_name || val.split(':').last() == Some(pkg_name) {
                        matches_pkg = true;
                    }
                }
            }
        }
        if matches_pkg {
            if let Some(id) = current_id {
                return Some(id);
            }
        }
    }
    None
}

pub struct AppStreamFeaturedRepository {
    alpm_repo: std::sync::Arc<AlpmPackageRepository>,
    #[allow(dead_code)]
    flatpak_repo: std::sync::Arc<FlatpakPackageRepository>,
    data_dir: PathBuf,
}

impl AppStreamFeaturedRepository {
    pub fn new(
        alpm_repo: std::sync::Arc<AlpmPackageRepository>,
        flatpak_repo: std::sync::Arc<FlatpakPackageRepository>,
    ) -> Self {
        // data/ directory lives next to the binary (or relative to workspace root)
        let data_dir = std::env::current_exe()
            .ok()
            .and_then(|p| p.parent().map(|p| p.to_path_buf()))
            .unwrap_or_else(|| PathBuf::from("."))
            .join("data");
        Self { alpm_repo, flatpak_repo, data_dir }
    }

    pub fn set_data_dir(mut self, path: PathBuf) -> Self {
        self.data_dir = path;
        self
    }

    fn load_app_ids(&self, filename: &str, fallback: &[&str]) -> Vec<String> {
        let path = self.data_dir.join(filename);
        if path.exists() {
            if let Ok(text) = std::fs::read_to_string(&path) {
                if let Ok(ids) = serde_json::from_str::<Vec<String>>(&text) {
                    return ids;
                }
            }
        }
        fallback.iter().map(|s| s.to_string()).collect()
    }

    async fn resolve_package(&self, app_id: &str) -> Option<Package> {
        let app_id = app_id.to_string();
        let alpm = self.alpm_repo.clone();

        tokio::task::spawn_blocking(move || {
            if let Some(xml) = appstreamcli_dump(&app_id) {
                let pkg_name = extract_tag_with_attrs(&xml, "pkgname");
                let pkg_name_opt = if pkg_name.is_empty() { None } else { Some(pkg_name) };

                let title = {
                    let t = extract_tag_with_attrs(&xml, "name");
                    if t.is_empty() { app_id.clone() } else { t }
                };
                let desc = extract_tag_with_attrs(&xml, "summary");

                let icons = extract_icons(&xml);
                let mut icon = String::new();
                if let Some((_, val)) = icons.iter().find(|(t, _)| t == "stock") {
                    icon = val.clone();
                } else if let Some((_, val)) = icons.first() {
                    icon = val.clone();
                }
                if icon.ends_with(".png") || icon.ends_with(".svg") || icon.ends_with(".xpm") {
                    if let Some((stem, _)) = icon.rsplit_once('.') {
                        icon = stem.to_string();
                    }
                }
                if icon.is_empty() {
                    icon = pkg_name_opt.clone().unwrap_or_else(|| app_id.clone());
                }

                if let Some(pkg_name) = pkg_name_opt {
                    // pacman package
                    let installed = alpm.is_installed_sync(&pkg_name);
                    let installed_version = alpm.get_installed_version_sync(&pkg_name);
                    let version = if !installed_version.is_empty() {
                        installed_version.clone()
                    } else {
                        get_sync_version(&pkg_name).unwrap_or_else(|| "latest".into())
                    };
                    Some(Package {
                        name: pkg_name,
                        title,
                        desc,
                        version,
                        pkg_type: "pacman".to_string(),
                        installed,
                        installed_version,
                        icon,
                    })
                } else {
                    // flatpak component
                    let fp_id = {
                        let id = extract_tag_with_attrs(&xml, "id");
                        if id.is_empty() { app_id.clone() } else { id }
                    };
                    let installed_flatpaks = flatpak_list_sync();
                    let installed = installed_flatpaks.contains_key(&fp_id);
                    let installed_version = installed_flatpaks.get(&fp_id).cloned().unwrap_or_default();
                    let version = if !installed_version.is_empty() { installed_version.clone() } else { "latest".into() };
                    Some(Package {
                        name: fp_id,
                        title,
                        desc,
                        version,
                        pkg_type: "flatpak".to_string(),
                        installed,
                        installed_version,
                        icon,
                    })
                }
            } else {
                // Fallback: treat app_id as a pacman/AUR package name directly
                let installed = alpm.is_installed_sync(&app_id);
                let installed_version = alpm.get_installed_version_sync(&app_id);
                let version = if !installed_version.is_empty() {
                    installed_version.clone()
                } else {
                    get_sync_version(&app_id).unwrap_or_else(|| "latest".into())
                };

                let (pkg_type, desc) = if installed {
                    let is_official = check_official_sync(&app_id);
                    let t = if is_official { "pacman" } else { "aur" };
                    (t.to_string(), "Pacote de sistema instalado.".to_string())
                } else if version != "latest" {
                    ("pacman".to_string(), String::new())
                } else {
                    ("aur".to_string(), "Ferramenta/Biblioteca do sistema (AUR)".to_string())
                };

                let title = app_id
                    .replace("-bin", "")
                    .replace("-git", "")
                    .replace('-', " ")
                    .split_whitespace()
                    .map(capitalize)
                    .collect::<Vec<_>>()
                    .join(" ");

                Some(Package {
                    name: app_id.clone(),
                    title,
                    desc,
                    version,
                    pkg_type,
                    installed,
                    installed_version,
                    icon: "package".to_string(),
                })
            }
        })
        .await
        .unwrap_or(None)
    }

    async fn resolve_hero(&self, app_id: &str, fallback_light: &str, fallback_dark: &str) -> Option<HeroApp> {
        let app_id = app_id.to_string();
        let fl = fallback_light.to_string();
        let fd = fallback_dark.to_string();
        let alpm = self.alpm_repo.clone();

        tokio::task::spawn_blocking(move || {
            let xml = appstreamcli_dump(&app_id)?;

            let hero_image = extract_first_source_image(&xml);
            let (brand_light, brand_dark) = extract_branding_colors(&xml, &fl, &fd);

            let pkg_name = extract_tag_with_attrs(&xml, "pkgname");
            let pkg_name_opt = if pkg_name.is_empty() { None } else { Some(pkg_name) };

            let title = {
                let t = extract_tag_with_attrs(&xml, "name");
                if t.is_empty() { app_id.clone() } else { t }
            };
            let desc = extract_tag_with_attrs(&xml, "summary");

            let icons = extract_icons(&xml);
            let mut icon = String::new();
            if let Some((_, val)) = icons.iter().find(|(t, _)| t == "stock") {
                icon = val.clone();
            } else if let Some((_, val)) = icons.first() {
                icon = val.clone();
            }
            if icon.ends_with(".png") || icon.ends_with(".svg") || icon.ends_with(".xpm") {
                if let Some((stem, _)) = icon.rsplit_once('.') {
                    icon = stem.to_string();
                }
            }
            if icon.is_empty() {
                icon = app_id.clone();
            }

            let (name, pkg_type, installed, installed_version, version) = if let Some(pkg_name) = pkg_name_opt {
                let installed = alpm.is_installed_sync(&pkg_name);
                let iv = alpm.get_installed_version_sync(&pkg_name);
                let ver = if !iv.is_empty() { iv.clone() } else {
                    get_sync_version(&pkg_name).unwrap_or_else(|| "latest".into())
                };
                (pkg_name, "pacman".to_string(), installed, iv, ver)
            } else {
                let fp_id = {
                    let id = extract_tag_with_attrs(&xml, "id");
                    if id.is_empty() { app_id.clone() } else { id }
                };
                let installed_flatpaks = flatpak_list_sync();
                let installed = installed_flatpaks.contains_key(&fp_id);
                let iv = installed_flatpaks.get(&fp_id).cloned().unwrap_or_default();
                let ver = if !iv.is_empty() { iv.clone() } else { "latest".into() };
                (fp_id, "flatpak".to_string(), installed, iv, ver)
            };

            Some(HeroApp {
                name,
                title,
                desc,
                version,
                pkg_type,
                installed,
                installed_version,
                icon,
                hero_image,
                brand_color_light: brand_light,
                brand_color_dark: brand_dark,
            })
        })
        .await
        .unwrap_or(None)
    }

}

// ─── Blocking helpers (called inside spawn_blocking) ──────────────────────────

fn flatpak_list_sync() -> HashMap<String, String> {
    let out = std::process::Command::new("flatpak")
        .args(["list", "--app", "--columns=application,version"])
        .output();
    let mut map = HashMap::new();
    if let Ok(o) = out {
        for line in String::from_utf8_lossy(&o.stdout).lines() {
            let parts: Vec<&str> = line.splitn(2, '\t').collect();
            if parts.len() == 2 {
                map.insert(parts[0].trim().to_string(), parts[1].trim().to_string());
            }
        }
    }
    map
}

fn get_sync_version(pkg_name: &str) -> Option<String> {
    let handle = alpm::Alpm::new("/", "/var/lib/pacman").ok()?;
    for dbname in ["core", "extra", "multilib"] {
        let _ = handle.register_syncdb(dbname, alpm::SigLevel::DATABASE_OPTIONAL);
    }
    for db in handle.syncdbs() {
        if let Ok(pkg) = db.pkg(pkg_name) {
            return Some(pkg.version().to_string());
        }
    }
    None
}

fn check_official_sync(pkg_name: &str) -> bool {
    let Ok(handle) = alpm::Alpm::new("/", "/var/lib/pacman") else { return false; };
    for dbname in ["core", "extra", "multilib"] {
        let _ = handle.register_syncdb(dbname, alpm::SigLevel::DATABASE_OPTIONAL);
    }
    handle.syncdbs().into_iter().any(|db| db.pkg(pkg_name).is_ok())
}

fn capitalize(s: &str) -> String {
    let mut c = s.chars();
    match c.next() {
        None => String::new(),
        Some(f) => f.to_uppercase().collect::<String>() + c.as_str(),
    }
}

// ─── FeaturedRepository impl ──────────────────────────────────────────────────

#[async_trait]
impl FeaturedRepository for AppStreamFeaturedRepository {
    async fn get_featured_packages(&self) -> Vec<Package> {
        let ids = self.load_app_ids("featured_apps.json", &[
            "org.mozilla.firefox", "com.visualstudio.code", "org.kde.kdenlive",
            "org.gimp.GIMP", "org.videolan.VLC", "org.inkscape.Inkscape",
            "org.blender.Blender", "com.valvesoftware.Steam",
            "org.libreoffice.LibreOffice", "org.telegram.desktop",
        ]);
        let futures: Vec<_> = ids.iter().map(|id| self.resolve_package(id)).collect();
        let resolved = futures_util::future::join_all(futures).await;
        resolved.into_iter().flatten().collect()
    }

    async fn get_gaming_packages(&self) -> Vec<Package> {
        let ids = self.load_app_ids("gaming_apps.json", &[
            "com.valvesoftware.Steam", "net.lutris.Lutris", "goverlay",
            "gamemode", "mangohud", "com.discordapp.Discord",
            "com.heroicgameslauncher.hgl", "hydra-games-launcher-bin",
            "wine", "winetricks", "protontricks", "net.davidotek.pupgui2",
        ]);
        let futures: Vec<_> = ids.iter().map(|id| self.resolve_package(id)).collect();
        let resolved = futures_util::future::join_all(futures).await;
        resolved.into_iter().flatten().collect()
    }

    async fn get_development_packages(&self) -> Vec<Package> {
        let ids = self.load_app_ids("development_apps.json", &[
            "code", "visual-studio-code-bin", "neovim", "dev.zed.Zed",
            "jetbrains-toolbox", "gnome-builder", "nodejs", "fnm", "npm",
            "yarn", "pnpm", "bun", "docker", "docker-compose", "podman",
            "io.podman_desktop.PodmanDesktop", "distrobox",
            "rest.insomnia.Insomnia", "com.getpostman.Postman",
            "rustup", "cargo", "go", "python", "git", "github-cli",
            "lazygit", "zellij",
        ]);
        let futures: Vec<_> = ids.iter().map(|id| self.resolve_package(id)).collect();
        let resolved = futures_util::future::join_all(futures).await;
        resolved.into_iter().flatten().collect()
    }

    async fn get_hero_apps(&self) -> Vec<HeroApp> {
        let hero_ids = [
            ("com.valvesoftware.Steam",     "#c6d0f5", "#1b2838"),
            ("org.libreoffice.LibreOffice", "#c6d0f5", "#18A303"),
            ("net.lutris.Lutris",           "#f4b8e4", "#cc5500"),
            ("com.heroicgameslauncher.hgl", "#ac9aac", "#1c202c"),
            ("com.visualstudio.code",       "#c6d0f5", "#0078d4"),
            ("org.gimp.GIMP",              "#f4b8e4", "#4e3e6e"),
        ];
        let futures: Vec<_> = hero_ids.iter().map(|(id, fl, fd)| self.resolve_hero(id, fl, fd)).collect();
        let resolved = futures_util::future::join_all(futures).await;
        resolved.into_iter().flatten().collect()
    }

    async fn get_gaming_hero_apps(&self) -> Vec<HeroApp> {
        let hero_ids = [
            ("com.valvesoftware.Steam",     "#c6d0f5", "#1b2838"),
            ("net.lutris.Lutris",           "#f4b8e4", "#cc5500"),
            ("com.heroicgameslauncher.hgl", "#ac9aac", "#1c202c"),
        ];
        let futures: Vec<_> = hero_ids.iter().map(|(id, fl, fd)| self.resolve_hero(id, fl, fd)).collect();
        let resolved = futures_util::future::join_all(futures).await;
        resolved.into_iter().flatten().collect()
    }

    async fn get_development_hero_apps(&self) -> Vec<HeroApp> {
        let hero_ids = [
            ("com.visualstudio.code", "#c6d0f5", "#0078d4"),
            ("dev.zed.Zed",           "#f4b8e4", "#cc5500"),
            ("org.gnome.Builder",     "#cba6f7", "#1a1a24"),
        ];
        let futures: Vec<_> = hero_ids.iter().map(|(id, fl, fd)| self.resolve_hero(id, fl, fd)).collect();
        let resolved = futures_util::future::join_all(futures).await;
        resolved.into_iter().flatten().collect()
    }

    async fn get_app_hero_image(&self, name: &str, pkg_type: &str) -> String {
        let name = name.to_string();
        let pkg_type = pkg_type.to_string();

        tokio::task::spawn_blocking(move || {
            let app_id = if pkg_type == "flatpak" {
                name.clone()
            } else {
                if let Some(id) = find_app_id_by_pkgname(&name) {
                    id
                } else {
                    name.clone()
                }
            };

            if let Some(xml) = appstreamcli_dump(&app_id) {
                return extract_first_source_image(&xml);
            }
            String::new()
        })
        .await
        .unwrap_or_default()
    }
}
