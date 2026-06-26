#![allow(non_snake_case)]
// presentation/backend.rs
//
// O QObject Rust que substitui o backend.py do Python.
// Exposto ao QML via módulo "ArchStore 1.0".
//
// Uso no QML:
//   import ArchStore 1.0
//   Backend { id: backend }
//
// Todos os métodos que retornam listas retornam JSON string.
// No QML use:  backend.getFeaturedPackages()  → JSON.parse(...) já feito pelo helper parseList()
//

use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};

use crate::config::{load_config, save_config, AppConfig};
use crate::data::{
    alpm_repository::AlpmPackageRepository,
    appstream_repository::AppStreamFeaturedRepository,
    aur_repository::AurPackageRepository,
    flatpak_repository::FlatpakPackageRepository,
};
use crate::domain::repositories::FeaturedRepository;
use crate::domain::usecases::{
    get_development_packages::GetDevelopmentPackagesUseCase,
    get_featured_packages::GetFeaturedPackagesUseCase,
    get_gaming_packages::GetGamingPackagesUseCase,
    get_group_packages::GetGroupPackagesUseCase,
    get_installed_packages::GetInstalledPackagesUseCase,
    get_updatable_packages::GetUpdatablePackagesUseCase,
    install_package::InstallPackageUseCase,
    launch_package::LaunchPackageUseCase,
    search_packages::SearchPackagesUseCase,
    uninstall_package::UninstallPackageUseCase,
};

// ─── Backing Rust struct ──────────────────────────────────────────────────────

pub struct BackendRust {
    alpm_repo: Arc<AlpmPackageRepository>,
    #[allow(dead_code)]
    aur_repo: Arc<AurPackageRepository>,
    flatpak_repo: Arc<FlatpakPackageRepository>,
    appstream_repo: Arc<AppStreamFeaturedRepository>,

    search_uc: Arc<SearchPackagesUseCase>,
    installed_uc: Arc<GetInstalledPackagesUseCase>,
    install_uc: Arc<InstallPackageUseCase>,
    uninstall_uc: Arc<UninstallPackageUseCase>,
    featured_uc: Arc<GetFeaturedPackagesUseCase>,
    gaming_uc: Arc<GetGamingPackagesUseCase>,
    development_uc: Arc<GetDevelopmentPackagesUseCase>,
    updatable_uc: Arc<GetUpdatablePackagesUseCase>,
    group_uc: Arc<GetGroupPackagesUseCase>,
    launch_uc: Arc<LaunchPackageUseCase>,

    config: Arc<Mutex<AppConfig>>,
    rt: Arc<tokio::runtime::Runtime>,
    search_version: Arc<AtomicUsize>,
    featured_cache: Mutex<Option<String>>,
    popular_cache: Mutex<Option<String>>,
    hero_cache: Mutex<Option<String>>,
    gaming_cache: Mutex<Option<String>>,
    gaming_hero_cache: Mutex<Option<String>>,
    dev_cache: Mutex<Option<String>>,
    dev_hero_cache: Mutex<Option<String>>,
    active_process_pid: Arc<Mutex<Option<u32>>>,
}

impl Default for BackendRust {
    fn default() -> Self {
        let rt = Arc::new(
            tokio::runtime::Builder::new_multi_thread()
                .enable_all()
                .build()
                .expect("Failed to create Tokio runtime"),
        );

        let alpm_repo = Arc::new(AlpmPackageRepository::new());
        let aur_repo = Arc::new(AurPackageRepository::new());
        let flatpak_repo = Arc::new(FlatpakPackageRepository::new());
        let appstream_repo = Arc::new(
            AppStreamFeaturedRepository::new(alpm_repo.clone(), flatpak_repo.clone())
                .set_data_dir(std::path::PathBuf::from("data")),
        );

        let search_uc = Arc::new(SearchPackagesUseCase::new(
            alpm_repo.clone(), aur_repo.clone(), flatpak_repo.clone(),
        ));
        let installed_uc = Arc::new(GetInstalledPackagesUseCase::new(
            alpm_repo.clone(), flatpak_repo.clone(),
        ));
        let install_uc = Arc::new(InstallPackageUseCase::new(
            alpm_repo.clone(), aur_repo.clone(), flatpak_repo.clone(),
        ));
        let uninstall_uc = Arc::new(UninstallPackageUseCase::new(
            alpm_repo.clone(), aur_repo.clone(), flatpak_repo.clone(),
        ));
        let featured_uc = Arc::new(GetFeaturedPackagesUseCase::new(appstream_repo.clone()));
        let gaming_uc = Arc::new(GetGamingPackagesUseCase::new(appstream_repo.clone()));
        let development_uc = Arc::new(GetDevelopmentPackagesUseCase::new(appstream_repo.clone()));
        let updatable_uc = Arc::new(GetUpdatablePackagesUseCase::new(
            alpm_repo.clone(), aur_repo.clone(), flatpak_repo.clone(),
        ));
        let group_uc = Arc::new(GetGroupPackagesUseCase::new(alpm_repo.clone()));
        let launch_uc = Arc::new(LaunchPackageUseCase::new(alpm_repo.clone(), flatpak_repo.clone()));

        Self {
            alpm_repo, aur_repo, flatpak_repo, appstream_repo,
            search_uc, installed_uc, install_uc, uninstall_uc,
            featured_uc, gaming_uc, development_uc, updatable_uc,
            group_uc, launch_uc,
            config: Arc::new(Mutex::new(load_config())),
            rt,
            search_version: Arc::new(AtomicUsize::new(0)),
            featured_cache: Mutex::new(None),
            popular_cache: Mutex::new(None),
            hero_cache: Mutex::new(None),
            gaming_cache: Mutex::new(None),
            gaming_hero_cache: Mutex::new(None),
            dev_cache: Mutex::new(None),
            dev_hero_cache: Mutex::new(None),
            active_process_pid: Arc::new(Mutex::new(None)),
        }
    }
}

// ─── cxx-qt bridge ────────────────────────────────────────────────────────────

#[cxx_qt::bridge]
pub mod ffi {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        type Backend = super::BackendRust;

        // ── Signals ──────────────────────────────────────────────────────────
        /// Linha de stdout do processo de install/uninstall
        #[qsignal]
        fn logReceived(self: Pin<&mut Backend>, line: QString);

        /// Resultado final da ação (true = sucesso)
        #[qsignal]
        fn actionFinished(self: Pin<&mut Backend>, success: bool);

        /// Resultados de busca como JSON string (array de objetos Package)
        #[qsignal]
        fn searchResultsReady(self: Pin<&mut Backend>, results: QString);

        /// Estado de carregamento da busca
        #[qsignal]
        fn searchLoadingChanged(self: Pin<&mut Backend>, loading: bool);

        // ── Busca ─────────────────────────────────────────────────────────────
        /// Busca com debounce de 500ms para campo de texto
        #[qinvokable]
        fn searchTextChanged(self: Pin<&mut Backend>, query: QString);

        /// Busca imediata sem debounce
        #[qinvokable]
        fn searchImmediately(self: Pin<&mut Backend>, query: QString);

        // ── Listagens (retornam JSON string) ──────────────────────────────────
        #[qinvokable]
        fn getInstalledPackages(self: Pin<&mut Backend>) -> QString;

        #[qinvokable]
        fn getFeaturedPackages(self: Pin<&mut Backend>) -> QString;

        #[qinvokable]
        fn getPopularPackages(self: Pin<&mut Backend>) -> QString;

        #[qinvokable]
        fn getGamingPackages(self: Pin<&mut Backend>) -> QString;

        #[qinvokable]
        fn getDevelopmentPackages(self: Pin<&mut Backend>) -> QString;

        #[qinvokable]
        fn getHeroApps(self: Pin<&mut Backend>) -> QString;

        #[qinvokable]
        fn getGamingHeroApps(self: Pin<&mut Backend>) -> QString;

        #[qinvokable]
        fn getDevelopmentHeroApps(self: Pin<&mut Backend>) -> QString;

        #[qinvokable]
        fn getAppHeroImage(self: Pin<&mut Backend>, name: QString, pkg_type: QString) -> QString;

        #[qinvokable]
        fn getUpdatablePackages(self: Pin<&mut Backend>) -> QString;

        #[qinvokable]
        fn getAlpmGroups(self: Pin<&mut Backend>) -> QString;

        #[qinvokable]
        fn getGroupPackages(self: Pin<&mut Backend>, group_name: QString) -> QString;

        // ── Ações ─────────────────────────────────────────────────────────────
        #[qinvokable]
        fn installPackage(self: Pin<&mut Backend>, pkg_type: QString, pkg_name: QString);

        #[qinvokable]
        fn uninstallPackage(self: Pin<&mut Backend>, pkg_type: QString, pkg_name: QString);

        #[qinvokable]
        fn updateCategory(self: Pin<&mut Backend>, category: QString);

        #[qinvokable]
        fn launchPackage(self: Pin<&mut Backend>, pkg_type: QString, pkg_name: QString);

        #[qinvokable]
        fn clearCache(self: Pin<&mut Backend>);

        #[qinvokable]
        fn cancelActiveOperation(self: Pin<&mut Backend>);

        // ── Config ────────────────────────────────────────────────────────────
        #[qinvokable]
        fn getConfigBool(self: Pin<&mut Backend>, key: QString) -> bool;

        #[qinvokable]
        fn getConfigStr(self: Pin<&mut Backend>, key: QString) -> QString;

        #[qinvokable]
        fn setConfigBool(self: Pin<&mut Backend>, key: QString, value: bool);

        #[qinvokable]
        fn setConfigStr(self: Pin<&mut Backend>, key: QString, value: QString);
    }

    impl cxx_qt::Threading for Backend {}
}

// ─── Implementações ───────────────────────────────────────────────────────────

use core::pin::Pin;
use cxx_qt::Threading;
use cxx_qt_lib::QString;
use crate::domain::entities::{HeroApp, Package};

fn pkg_to_json(pkg: &Package) -> serde_json::Value {
    serde_json::json!({
        "name": pkg.name,
        "title": pkg.title,
        "desc": pkg.desc,
        "version": pkg.version,
        "type": pkg.pkg_type,
        "installed": pkg.installed,
        "installedVersion": pkg.installed_version,
        "icon": pkg.icon,
    })
}

fn hero_to_json(h: &HeroApp) -> serde_json::Value {
    serde_json::json!({
        "name": h.name,
        "title": h.title,
        "desc": h.desc,
        "version": h.version,
        "type": h.pkg_type,
        "installed": h.installed,
        "installedVersion": h.installed_version,
        "icon": h.icon,
        "hero_image": h.hero_image,
        "brand_color_light": h.brand_color_light,
        "brand_color_dark": h.brand_color_dark,
    })
}

fn pkgs_to_qstr(pkgs: &[Package]) -> QString {
    let arr: Vec<_> = pkgs.iter().map(pkg_to_json).collect();
    QString::from(serde_json::to_string(&arr).unwrap_or_else(|_| "[]".into()).as_str())
}

fn heroes_to_qstr(heroes: &[HeroApp]) -> QString {
    let arr: Vec<_> = heroes.iter().map(hero_to_json).collect();
    QString::from(serde_json::to_string(&arr).unwrap_or_else(|_| "[]".into()).as_str())
}

fn resolve_askpass_path() -> Option<String> {
    let candidates = [
        "../askpass.sh",
        "askpass.sh",
        "/usr/share/arch-store/askpass.sh",
    ];

    if let Ok(exe) = std::env::current_exe() {
        if let Some(exe_dir) = exe.parent() {
            for c in &candidates {
                let full = exe_dir.join(c);
                if full.exists() {
                    return Some(full.to_string_lossy().to_string());
                }
            }
        }
    }

    for c in &candidates {
        if std::path::Path::new(c).exists() {
            if let Ok(p) = std::fs::canonicalize(c) {
                return Some(p.to_string_lossy().to_string());
            }
        }
    }

    None
}

/// Executa um comando em background e emite logReceived + actionFinished via qt_thread
fn stream_command(
    cmd: Vec<String>,
    qt_thread: cxx_qt::CxxQtThread<ffi::Backend>,
    active_process_pid: Arc<Mutex<Option<u32>>>,
) {
    std::thread::spawn(move || {
        if cmd.is_empty() {
            let _ = qt_thread.queue(|mut b| { b.as_mut().actionFinished(false); });
            return;
        }

        let mut command = std::process::Command::new(&cmd[0]);
        command.args(&cmd[1..])
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped());

        if let Some(askpass) = resolve_askpass_path() {
            command.env("SUDO_ASKPASS", &askpass);
            command.env("SSH_ASKPASS", &askpass);
        }

        let child = command.spawn();

        let mut child = match child {
            Ok(c) => c,
            Err(e) => {
                let msg = e.to_string();
                let _ = qt_thread.queue(move |mut b| {
                    b.as_mut().logReceived(QString::from(msg.as_str()));
                    b.as_mut().actionFinished(false);
                });
                return;
            }
        };

        let pid = child.id();
        if let Ok(mut guard) = active_process_pid.lock() {
            *guard = Some(pid);
        }

        let stdout = child.stdout.take();
        let stderr = child.stderr.take();

        if let Some(stdout) = stdout {
            let qt = qt_thread.clone();
            std::thread::spawn(move || {
                use std::io::BufRead;
                for line in std::io::BufReader::new(stdout).lines().map_while(Result::ok) {
                    let _ = qt.queue(move |mut b| {
                        b.as_mut().logReceived(QString::from(line.as_str()));
                    });
                }
            });
        }

        if let Some(stderr) = stderr {
            let qt = qt_thread.clone();
            std::thread::spawn(move || {
                use std::io::BufRead;
                for line in std::io::BufReader::new(stderr).lines().map_while(Result::ok) {
                    let _ = qt.queue(move |mut b| {
                        b.as_mut().logReceived(QString::from(line.as_str()));
                    });
                }
            });
        }

        let success = child.wait().map(|s| s.success()).unwrap_or(false);

        if let Ok(mut guard) = active_process_pid.lock() {
            if *guard == Some(pid) {
                *guard = None;
            }
        }

        let _ = qt_thread.queue(move |mut b| {
            b.as_mut().actionFinished(success);
        });
    });
}

impl ffi::Backend {
    // ── Busca ────────────────────────────────────────────────────────────────

    fn searchTextChanged(self: Pin<&mut Self>, query: QString) {
        let version = self.search_version.fetch_add(1, Ordering::SeqCst) + 1;
        let current_version = self.search_version.clone();
        let qt_thread = self.qt_thread();
        let rt = self.rt.clone();
        let search_uc = self.search_uc.clone();
        let config = self.config.lock().unwrap().clone();
        let query_str = query.to_string();

        let qt_load = qt_thread.clone();
        let _ = qt_load.queue(|mut b| { b.as_mut().searchLoadingChanged(true); });

        std::thread::spawn(move || {
            rt.block_on(async {
                tokio::time::sleep(std::time::Duration::from_millis(500)).await;
                if current_version.load(Ordering::SeqCst) != version { return; }

                let results = search_uc.execute(&query_str, &config).await;
                let json = pkgs_to_qstr(&results);
                let _ = qt_thread.queue(move |mut b| {
                    b.as_mut().searchResultsReady(json);
                    b.as_mut().searchLoadingChanged(false);
                });
            });
        });
    }

    fn searchImmediately(self: Pin<&mut Self>, query: QString) {
        let qt_thread = self.qt_thread();
        let rt = self.rt.clone();
        let search_uc = self.search_uc.clone();
        let config = self.config.lock().unwrap().clone();
        let query_str = query.to_string();

        let qt_load = qt_thread.clone();
        let _ = qt_load.queue(|mut b| { b.as_mut().searchLoadingChanged(true); });

        std::thread::spawn(move || {
            let results = rt.block_on(search_uc.execute(&query_str, &config));
            let json = pkgs_to_qstr(&results);
            let _ = qt_thread.queue(move |mut b| {
                b.as_mut().searchResultsReady(json);
                b.as_mut().searchLoadingChanged(false);
            });
        });
    }

    // ── Listagens ─────────────────────────────────────────────────────────────

    fn getInstalledPackages(self: Pin<&mut Self>) -> QString {
        let cfg = self.config.lock().unwrap().clone();
        let pkgs = self.rt.block_on(self.installed_uc.execute(&cfg));
        pkgs_to_qstr(&pkgs)
    }

    fn getFeaturedPackages(self: Pin<&mut Self>) -> QString {
        if let Ok(cache) = self.featured_cache.lock() {
            if let Some(ref val) = *cache {
                return QString::from(val.as_str());
            }
        }
        let pkgs = self.rt.block_on(self.featured_uc.execute());
        let res = pkgs_to_qstr(&pkgs);
        if let Ok(mut cache) = self.featured_cache.lock() {
            *cache = Some(res.to_string());
        }
        res
    }

    fn getPopularPackages(self: Pin<&mut Self>) -> QString {
        if let Ok(cache) = self.popular_cache.lock() {
            if let Some(ref val) = *cache {
                return QString::from(val.as_str());
            }
        }
        let pkgs = self.rt.block_on(self.flatpak_repo.get_popular());
        let res = pkgs_to_qstr(&pkgs);
        if let Ok(mut cache) = self.popular_cache.lock() {
            *cache = Some(res.to_string());
        }
        res
    }

    fn getGamingPackages(self: Pin<&mut Self>) -> QString {
        if let Ok(cache) = self.gaming_cache.lock() {
            if let Some(ref val) = *cache {
                return QString::from(val.as_str());
            }
        }
        let pkgs = self.rt.block_on(self.gaming_uc.execute());
        let res = pkgs_to_qstr(&pkgs);
        if let Ok(mut cache) = self.gaming_cache.lock() {
            *cache = Some(res.to_string());
        }
        res
    }

    fn getDevelopmentPackages(self: Pin<&mut Self>) -> QString {
        if let Ok(cache) = self.dev_cache.lock() {
            if let Some(ref val) = *cache {
                return QString::from(val.as_str());
            }
        }
        let pkgs = self.rt.block_on(self.development_uc.execute());
        let res = pkgs_to_qstr(&pkgs);
        if let Ok(mut cache) = self.dev_cache.lock() {
            *cache = Some(res.to_string());
        }
        res
    }

    fn getHeroApps(self: Pin<&mut Self>) -> QString {
        if let Ok(cache) = self.hero_cache.lock() {
            if let Some(ref val) = *cache {
                return QString::from(val.as_str());
            }
        }
        let heroes = self.rt.block_on(self.appstream_repo.get_hero_apps());
        let res = heroes_to_qstr(&heroes);
        if let Ok(mut cache) = self.hero_cache.lock() {
            *cache = Some(res.to_string());
        }
        res
    }

    fn getGamingHeroApps(self: Pin<&mut Self>) -> QString {
        if let Ok(cache) = self.gaming_hero_cache.lock() {
            if let Some(ref val) = *cache {
                return QString::from(val.as_str());
            }
        }
        let heroes = self.rt.block_on(self.appstream_repo.get_gaming_hero_apps());
        let res = heroes_to_qstr(&heroes);
        if let Ok(mut cache) = self.gaming_hero_cache.lock() {
            *cache = Some(res.to_string());
        }
        res
    }

    fn getDevelopmentHeroApps(self: Pin<&mut Self>) -> QString {
        if let Ok(cache) = self.dev_hero_cache.lock() {
            if let Some(ref val) = *cache {
                return QString::from(val.as_str());
            }
        }
        let heroes = self.rt.block_on(self.appstream_repo.get_development_hero_apps());
        let res = heroes_to_qstr(&heroes);
        if let Ok(mut cache) = self.dev_hero_cache.lock() {
            *cache = Some(res.to_string());
        }
        res
    }

    fn getAppHeroImage(self: Pin<&mut Self>, name: QString, pkg_type: QString) -> QString {
        let url = self.rt.block_on(
            self.appstream_repo.get_app_hero_image(&name.to_string(), &pkg_type.to_string()),
        );
        QString::from(url.as_str())
    }

    fn getUpdatablePackages(self: Pin<&mut Self>) -> QString {
        let cfg = self.config.lock().unwrap().clone();
        let pkgs = self.rt.block_on(self.updatable_uc.execute(&cfg));
        pkgs_to_qstr(&pkgs)
    }

    fn getAlpmGroups(self: Pin<&mut Self>) -> QString {
        let groups = self.rt.block_on(self.alpm_repo.get_alpm_groups());
        let arr: Vec<serde_json::Value> = groups.iter()
            .map(|g| serde_json::Value::String(g.clone()))
            .collect();
        QString::from(serde_json::to_string(&arr).unwrap_or_else(|_| "[]".into()).as_str())
    }

    fn getGroupPackages(self: Pin<&mut Self>, group_name: QString) -> QString {
        let pkgs = self.rt.block_on(self.group_uc.execute(&group_name.to_string()));
        pkgs_to_qstr(&pkgs)
    }

    fn clear_internal_caches(&self) {
        if let Ok(mut cache) = self.featured_cache.lock() { *cache = None; }
        if let Ok(mut cache) = self.popular_cache.lock() { *cache = None; }
        if let Ok(mut cache) = self.hero_cache.lock() { *cache = None; }
        if let Ok(mut cache) = self.gaming_cache.lock() { *cache = None; }
        if let Ok(mut cache) = self.gaming_hero_cache.lock() { *cache = None; }
        if let Ok(mut cache) = self.dev_cache.lock() { *cache = None; }
        if let Ok(mut cache) = self.dev_hero_cache.lock() { *cache = None; }
    }

    // ── Ações ─────────────────────────────────────────────────────────────────

    fn installPackage(self: Pin<&mut Self>, pkg_type: QString, pkg_name: QString) {
        self.clear_internal_caches();
        let qt_thread = self.qt_thread();
        let rt = self.rt.clone();
        let install_uc = self.install_uc.clone();
        let (pt, pn) = (pkg_type.to_string(), pkg_name.to_string());
        let active_pid = self.active_process_pid.clone();

        std::thread::spawn(move || {
            if let Some(cmd) = rt.block_on(install_uc.execute(&pt, &pn)) {
                stream_command(cmd, qt_thread, active_pid);
            } else {
                let _ = qt_thread.queue(|mut b| {
                    b.as_mut().logReceived(QString::from("Tipo de pacote desconhecido"));
                    b.as_mut().actionFinished(false);
                });
            }
        });
    }

    fn uninstallPackage(self: Pin<&mut Self>, pkg_type: QString, pkg_name: QString) {
        self.clear_internal_caches();
        let qt_thread = self.qt_thread();
        let rt = self.rt.clone();
        let uninstall_uc = self.uninstall_uc.clone();
        let (pt, pn) = (pkg_type.to_string(), pkg_name.to_string());
        let active_pid = self.active_process_pid.clone();

        std::thread::spawn(move || {
            if let Some(cmd) = rt.block_on(uninstall_uc.execute(&pt, &pn)) {
                stream_command(cmd, qt_thread, active_pid);
            } else {
                let _ = qt_thread.queue(|mut b| {
                    b.as_mut().logReceived(QString::from("Tipo de pacote desconhecido"));
                    b.as_mut().actionFinished(false);
                });
            }
        });
    }

    fn updateCategory(self: Pin<&mut Self>, category: QString) {
        self.clear_internal_caches();
        let qt_thread = self.qt_thread();
        let helper = if which("yay") { "yay" } else { "paru" }.to_string();
        let cat = category.to_string();
        let active_pid = self.active_process_pid.clone();

        let cmd: Vec<String> = match cat.as_str() {
            "pacman" => vec!["pkexec".into(), "pacman".into(), "-Syu".into(), "--noconfirm".into()],
            "flatpak" => vec!["flatpak".into(), "update".into(), "-y".into()],
            "aur" => vec![helper, "--noconfirm".into(), "-Sua".into()],
            "all" => {
                let h = if which("yay") { "yay" } else { "paru" };
                vec!["sh".into(), "-c".into(), format!(
                    "pkexec pacman -Syu --noconfirm && {h} --noconfirm -Sua && flatpak update -y"
                )]
            }
            _ => {
                let _ = qt_thread.queue(|mut b| { b.as_mut().actionFinished(false); });
                return;
            }
        };
        stream_command(cmd, qt_thread, active_pid);
    }

    fn launchPackage(self: Pin<&mut Self>, pkg_type: QString, pkg_name: QString) {
        let rt = self.rt.clone();
        let launch_uc = self.launch_uc.clone();
        let (pt, pn) = (pkg_type.to_string(), pkg_name.to_string());
        std::thread::spawn(move || { rt.block_on(launch_uc.execute(&pt, &pn)); });
    }

    fn clearCache(self: Pin<&mut Self>) {
        self.clear_internal_caches();
        let qt_thread = self.qt_thread();
        let active_pid = self.active_process_pid.clone();
        stream_command(vec![
            "sh".into(), "-c".into(),
            "pkexec pacman -Scc --noconfirm && flatpak uninstall --unused -y && appstreamcli refresh-cache --user".into(),
        ], qt_thread, active_pid);
    }

    fn cancelActiveOperation(self: Pin<&mut Self>) {
        if let Ok(guard) = self.active_process_pid.lock() {
            if let Some(pid) = *guard {
                // Kill process tree
                let _ = std::process::Command::new("kill")
                    .arg("-9")
                    .arg(pid.to_string())
                    .spawn();
            }
        }
    }

    // ── Config ────────────────────────────────────────────────────────────────

    fn getConfigBool(self: Pin<&mut Self>, key: QString) -> bool {
        let cfg = self.config.lock().unwrap();
        match key.to_string().as_str() {
            "enable_aur" => cfg.enable_aur,
            "enable_flatpak" => cfg.enable_flatpak,
            "check_updates_startup" => cfg.check_updates_startup,
            _ => false,
        }
    }

    fn getConfigStr(self: Pin<&mut Self>, key: QString) -> QString {
        let cfg = self.config.lock().unwrap();
        let val = match key.to_string().as_str() {
            "theme_flavor" => cfg.theme_flavor.clone(),
            "theme_mode" => cfg.theme_mode.clone(),
            "language" => cfg.language.clone(),
            _ => String::new(),
        };
        QString::from(val.as_str())
    }

    fn setConfigBool(self: Pin<&mut Self>, key: QString, value: bool) {
        let mut cfg = self.config.lock().unwrap();
        match key.to_string().as_str() {
            "enable_aur" => cfg.enable_aur = value,
            "enable_flatpak" => cfg.enable_flatpak = value,
            "check_updates_startup" => cfg.check_updates_startup = value,
            _ => {}
        }
        let _ = save_config(&cfg);
    }

    fn setConfigStr(self: Pin<&mut Self>, key: QString, value: QString) {
        let mut cfg = self.config.lock().unwrap();
        match key.to_string().as_str() {
            "theme_flavor" => cfg.theme_flavor = value.to_string(),
            "theme_mode" => cfg.theme_mode = value.to_string(),
            "language" => cfg.language = value.to_string(),
            _ => {}
        }
        let _ = save_config(&cfg);
    }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

fn which(cmd: &str) -> bool {
    std::process::Command::new("which").arg(cmd)
        .output().map(|o| o.status.success()).unwrap_or(false)
}

