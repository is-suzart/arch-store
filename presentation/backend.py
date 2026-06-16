import subprocess
import json
import os
from pathlib import Path
from PySide6.QtCore import QObject, Slot, Signal, QThread, QTimer

class SearchWorker(QThread):
    results_ready = Signal(list)

    def __init__(self, search_usecase, query):
        super().__init__()
        self.search_usecase = search_usecase
        self.query = query

    def run(self):
        try:
            packages = self.search_usecase.execute(self.query)
            results = [pkg.to_dict() for pkg in packages]
            self.results_ready.emit(results)
        except Exception as e:
            print(f"Error in SearchWorker: {e}")
            self.results_ready.emit([])

class InstallWorker(QThread):
    log_received = Signal(str)
    finished = Signal(bool)

    def __init__(self, cmd):
        super().__init__()
        self.cmd = cmd

    def run(self):
        try:
            import os
            env = os.environ.copy()
            current_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            askpass_path = os.path.join(current_dir, "askpass.sh")
            env["SUDO_ASKPASS"] = askpass_path
            env["SSH_ASKPASS"] = askpass_path
            
            # We run the process capturing output and streaming it line-by-line
            process = subprocess.Popen(
                self.cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                env=env
            )
            
            while True:
                line = process.stdout.readline()
                if not line and process.poll() is not None:
                    break
                if line:
                    self.log_received.emit(line.strip())
            
            rc = process.poll()
            self.finished.emit(rc == 0)
        except Exception as e:
            self.log_received.emit(f"Error executing command: {e}")
            self.finished.emit(False)

class Backend(QObject):
    logReceived = Signal(str, arguments=['line'])
    actionFinished = Signal(bool, arguments=['success'])
    searchResultsReady = Signal(list, arguments=['results'])
    searchLoadingChanged = Signal(bool, arguments=['loading'])

    def __init__(self, search_usecase, get_installed_usecase, install_usecase, uninstall_usecase, get_featured_usecase, get_popular_usecase, get_gaming_usecase, get_updatable_usecase, appstream_repo=None, get_group_packages_usecase=None, launch_usecase=None):
        super().__init__()
        self.launch_usecase = launch_usecase
        self.get_group_packages_usecase = get_group_packages_usecase
        self.search_usecase = search_usecase
        self.get_installed_usecase = get_installed_usecase
        self.install_usecase = install_usecase
        self.uninstall_usecase = uninstall_usecase
        self.get_featured_usecase = get_featured_usecase
        self.get_popular_usecase = get_popular_usecase
        self.get_gaming_usecase = get_gaming_usecase
        self.get_updatable_usecase = get_updatable_usecase
        self.appstream_repo = appstream_repo
        self.worker = None
        self.search_worker = None

        # Config files setup
        config_dir = Path.home() / ".config" / "arch-store"
        config_dir.mkdir(parents=True, exist_ok=True)
        self.config_path = config_dir / "config.json"
        
        self.config = {
            "theme_flavor": "mocha",
            "enable_aur": True,
            "enable_flatpak": True,
            "check_updates_startup": True
        }
        
        if self.config_path.exists():
            try:
                with open(self.config_path, "r", encoding="utf-8") as f:
                    self.config.update(json.load(f))
            except Exception as e:
                print(f"Error loading config: {e}")
                
        self._sync_usecases()

        # Debounce timer setup
        self.search_timer = QTimer(self)
        self.search_timer.setSingleShot(True)
        self.search_timer.setInterval(500)
        self.search_timer.timeout.connect(self._executar_pesquisa)
        self.search_query = ""
        self.last_search_query = ""

    @Slot(str)
    def searchTextChanged(self, query):
        self.search_query = query.strip()
        self.search_timer.start()

    @Slot(str)
    def searchImmediately(self, query):
        self.search_query = query.strip()
        self.search_timer.stop()
        self._executar_pesquisa()

    def _executar_pesquisa(self):
        if self.search_query == self.last_search_query:
            return
            
        if len(self.search_query) < 3:
            self.last_search_query = self.search_query
            self.searchResultsReady.emit([])
            return

        self.last_search_query = self.search_query
        self.searchLoadingChanged.emit(True)

        if self.search_worker and self.search_worker.isRunning():
            self.search_worker.terminate()
            self.search_worker.wait()

        self.search_worker = SearchWorker(self.search_usecase, self.search_query)
        self.search_worker.results_ready.connect(self._on_search_completed)
        self.search_worker.start()

    def _on_search_completed(self, results):
        self.searchResultsReady.emit(results)
        self.searchLoadingChanged.emit(False)

    @Slot(str, result=list)
    def searchPackages(self, query):
        packages = self.search_usecase.execute(query)
        return [pkg.to_dict() for pkg in packages]

    @Slot(result=list)
    def getInstalledPackages(self):
        packages = self.get_installed_usecase.execute()
        return [pkg.to_dict() for pkg in packages]

    @Slot(result=list)
    def getFeaturedPackages(self):
        try:
            packages = self.get_featured_usecase.execute()
            return [pkg.to_dict() for pkg in packages]
        except Exception as e:
            print(f"Error getting featured packages: {e}")
            return []

    @Slot(result=list)
    def getPopularPackages(self):
        try:
            packages = self.get_popular_usecase.execute()
            return [pkg.to_dict() for pkg in packages]
        except Exception as e:
            print(f"Error getting popular packages: {e}")
            return []

    @Slot(result=list)
    def getGamingPackages(self):
        try:
            packages = self.get_gaming_usecase.execute()
            return [pkg.to_dict() for pkg in packages]
        except Exception as e:
            print(f"Error getting gaming packages: {e}")
            return []

    @Slot(result=list)
    def getHeroApps(self):
        try:
            if self.appstream_repo is None:
                return []
            return self.appstream_repo.get_hero_apps()
        except Exception as e:
            print(f"Error getting hero apps: {e}")
            return []

    @Slot(str, str, result=str)
    def getAppHeroImage(self, name, pkg_type):
        try:
            if self.appstream_repo is None:
                return ""
            return self.appstream_repo.get_app_hero_image(name, pkg_type)
        except Exception as e:
            print(f"Error getting hero image for {pkg_type}/{name}: {e}")
            return ""

    @Slot(str, str)
    def installPackage(self, pkg_type, pkg_name):
        if self.worker and self.worker.isRunning():
            self.logReceived.emit("Another operation is already running!")
            return

        cmd = self.install_usecase.execute(pkg_type, pkg_name)
        if not cmd:
            self.logReceived.emit("Unknown package type.")
            return

        self.logReceived.emit(f"Starting installation of {pkg_name} ({pkg_type})...")
        self.worker = InstallWorker(cmd)
        self.worker.log_received.connect(self.logReceived.emit)
        self.worker.finished.connect(self.on_worker_finished)
        self.worker.start()

    @Slot(str, str)
    def uninstallPackage(self, pkg_type, pkg_name):
        if self.worker and self.worker.isRunning():
            self.logReceived.emit("Another operation is already running!")
            return

        cmd = self.uninstall_usecase.execute(pkg_type, pkg_name)
        if not cmd:
            self.logReceived.emit("Unknown package type.")
            return

        self.logReceived.emit(f"Removing {pkg_name} ({pkg_type})...")
        self.worker = InstallWorker(cmd)
        self.worker.log_received.connect(self.logReceived.emit)
        self.worker.finished.connect(self.on_worker_finished)
        self.worker.start()

    @Slot(result=list)
    def getUpdatablePackages(self):
        try:
            packages = self.get_updatable_usecase.execute()
            return [pkg.to_dict() for pkg in packages]
        except Exception as e:
            print(f"Error getting updatable packages: {e}")
            return []

    @Slot(str)
    def updateCategory(self, category):
        if self.worker and self.worker.isRunning():
            self.logReceived.emit("Another operation is already running!")
            return

        if category == "pacman":
            cmd = ["sudo", "-A", "pacman", "-Syu", "--noconfirm"]
        elif category == "flatpak":
            # Update both system and user, non-interactively
            cmd = ["flatpak", "update", "-y", "--noninteractive"]
        elif category == "aur":
            cmd = ["yay", "--sudo", "sudo", "-A", "-Sua", "--noconfirm"]
        elif category == "all":
            cmd = ["sh", "-c", "sudo -A pacman -Syu --noconfirm && yay --sudo sudo -A -Sua --noconfirm && flatpak update -y --noninteractive"]
        else:
            self.logReceived.emit("Unknown update category.")
            return

        self.logReceived.emit(f"Starting system update for: {category.upper()}...")
        self.worker = InstallWorker(cmd)
        self.worker.log_received.connect(self.logReceived.emit)
        self.worker.finished.connect(self.on_worker_finished)
        self.worker.start()

    @Slot(str, str)
    def launchPackage(self, pkg_type, pkg_name):
        if self.launch_usecase:
            self.launch_usecase.execute(pkg_type, pkg_name)

    def on_worker_finished(self, success):
        self.actionFinished.emit(success)

    def _save_config(self):
        try:
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(self.config, f, indent=4)
        except Exception as e:
            print(f"Error saving config: {e}")

    def _sync_usecases(self):
        self.search_usecase.enable_aur = self.config.get("enable_aur", True)
        self.search_usecase.enable_flatpak = self.config.get("enable_flatpak", True)
        self.get_installed_usecase.enable_flatpak = self.config.get("enable_flatpak", True)
        self.get_updatable_usecase.enable_aur = self.config.get("enable_aur", True)
        self.get_updatable_usecase.enable_flatpak = self.config.get("enable_flatpak", True)

    @Slot(str, result=bool)
    def getConfigBool(self, key):
        return bool(self.config.get(key, True))

    @Slot(str, result=str)
    def getConfigStr(self, key):
        return str(self.config.get(key, "mocha"))

    @Slot(str, bool)
    def setConfigBool(self, key, value):
        self.config[key] = bool(value)
        self._save_config()
        self._sync_usecases()

    @Slot(str, str)
    def setConfigStr(self, key, value):
        self.config[key] = str(value)
        self._save_config()
        self._sync_usecases()

    @Slot()
    def clearCache(self):
        if self.worker and self.worker.isRunning():
            self.logReceived.emit("Another operation is already running!")
            return

        cmd = ["sh", "-c", "sudo -A pacman -Scc --noconfirm && flatpak uninstall --unused -y --noninteractive && appstreamcli refresh-cache --user"]
        self.logReceived.emit("Iniciando limpeza de cache...")
        self.worker = InstallWorker(cmd)
        self.worker.log_received.connect(self.logReceived.emit)
        self.worker.finished.connect(self.on_worker_finished)
        self.worker.start()

    @Slot(str, result=list)
    def getGroupPackages(self, group_name):
        try:
            if not self.get_group_packages_usecase:
                return []
            packages = self.get_group_packages_usecase.execute(group_name)
            return [pkg.to_dict() for pkg in packages]
        except Exception as e:
            print(f"Error in getGroupPackages: {e}")
            return []

    @Slot(result=list)
    def getAlpmGroups(self):
        try:
            alpm_repo = self.search_usecase.alpm_repo
            alpm_repo._refresh_localdb()
            groups = set()
            for db in alpm_repo.syncdbs:
                for pkg in db.pkgcache:
                    groups.update(pkg.groups)
            
            all_groups = sorted([g for g in groups if g])
            
            if not all_groups:
                all_groups = ["gnome", "kde-system", "xfce4", "qt6", "xorg"]
                
            labels = {
                "gnome": "Ambiente GNOME",
                "kde-system": "Ambiente KDE",
                "xfce4": "Ambiente XFCE",
                "qt6": "Desenvolvimento Qt6",
                "base-devel": "Desenvolvimento Base",
                "xorg": "Servidor Xorg",
                "mate": "Ambiente MATE",
                "lxqt": "Ambiente LXQt",
                "deepin": "Ambiente Deepin"
            }
            
            return [{"name": g, "label": labels.get(g, g)} for g in all_groups]
        except Exception as e:
            print(f"Error getting ALPM groups: {e}")
            return [
                {"name": "gnome", "label": "Ambiente GNOME"},
                {"name": "kde-system", "label": "Ambiente KDE"},
                {"name": "xfce4", "label": "Ambiente XFCE"},
                {"name": "qt6", "label": "Desenvolvimento Qt6"},
                {"name": "xorg", "label": "Servidor Xorg"}
            ]
