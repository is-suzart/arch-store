import pyalpm
from typing import List
from domain.entities import Package
from domain.repositories import PackageRepository

class AlpmPackageRepository(PackageRepository):
    def __init__(self):
        self.handle = pyalpm.Handle("/", "/var/lib/pacman")
        self.localdb = self.handle.get_localdb()
        
        # Load sync databases (repos)
        self.syncdbs = []
        for dbname in ["core", "extra", "community", "multilib"]:
            try:
                db = self.handle.register_syncdb(dbname, pyalpm.SIG_DATABASE_OPTIONAL)
                self.syncdbs.append(db)
            except Exception:
                pass

    def _refresh_localdb(self):
        try:
            self.handle = pyalpm.Handle("/", "/var/lib/pacman")
            self.localdb = self.handle.get_localdb()
        except Exception as e:
            print(f"Error refreshing ALPM database: {e}")

    def _get_icon_from_desktop(self, file_path: str) -> str:
        try:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if line.startswith("Icon="):
                        return line.split("=", 1)[1].strip()
        except Exception:
            pass
        return ""

    def get_installed_icon(self, pkg_name: str) -> str:
        self._refresh_localdb()
        try:
            pkg = self.localdb.get_pkg(pkg_name)
            if pkg:
                for f in pkg.files:
                    file_path = f[0]
                    if "usr/share/applications/" in file_path and file_path.endswith(".desktop"):
                        return self._get_icon_from_desktop("/" + file_path)
        except Exception:
            pass
        return ""

    def is_installed(self, pkg_name: str) -> bool:
        self._refresh_localdb()
        try:
            return self.localdb.get_pkg(pkg_name) is not None
        except Exception:
            return False

    def get_installed_version(self, pkg_name: str) -> str:
        self._refresh_localdb()
        try:
            pkg = self.localdb.get_pkg(pkg_name)
            return pkg.version if pkg else ""
        except Exception:
            return ""

    def search(self, query: str) -> List[Package]:
        self._refresh_localdb()
        if not query:
            return []
            
        results = []
        query_lower = query.lower()
        pacman_names = set()

        for db in self.syncdbs:
            try:
                for pkg in db.search(query_lower):
                    if pkg.name in pacman_names:
                        continue
                    pacman_names.add(pkg.name)
                    
                    installed = self.is_installed(pkg.name)
                    icon_name = self.get_installed_icon(pkg.name) if installed else ""
                    
                    results.append(Package(
                        name=pkg.name,
                        title=pkg.name,
                        desc=pkg.desc or "",
                        version=pkg.version,
                        type="pacman",
                        installed=installed,
                        installed_version=self.get_installed_version(pkg.name) if installed else "",
                        icon=icon_name
                    ))
            except Exception as e:
                print(f"Error searching ALPM db: {e}")
                
        return results

    def get_installed(self) -> List[Package]:
        self._refresh_localdb()
        installed = []
        try:
            for pkg in self.localdb.pkgcache:
                is_desktop = False
                icon_name = ""
                for f in pkg.files:
                    file_path = f[0]
                    if "usr/share/applications/" in file_path and file_path.endswith(".desktop"):
                        is_desktop = True
                        icon_name = self._get_icon_from_desktop("/" + file_path)
                        break
                if is_desktop:
                    # Check if the package is in sync databases to distinguish pacman vs aur
                    is_official = False
                    for db in self.syncdbs:
                        if db.get_pkg(pkg.name) is not None:
                            is_official = True
                            break
                    pkg_type = "pacman" if is_official else "aur"

                    installed.append(Package(
                        name=pkg.name,
                        title=pkg.name,
                        desc=pkg.desc or "",
                        version=pkg.version,
                        type=pkg_type,
                        installed=True,
                        installed_version=pkg.version,
                        icon=icon_name
                    ))
        except Exception as e:
            print(f"Error loading installed pacman: {e}")
        return installed


    def get_install_command(self, pkg_name: str) -> List[str]:
        return ["sudo", "-A", "pacman", "-S", "--noconfirm", pkg_name]

    def get_uninstall_command(self, pkg_name: str) -> List[str]:
        return ["sudo", "-A", "pacman", "-Rns", "--noconfirm", pkg_name]

    def get_updatable(self) -> List[Package]:
        self._refresh_localdb()
        updates = []
        for pkg in self.localdb.pkgcache:
            for db in self.syncdbs:
                sync_pkg = db.get_pkg(pkg.name)
                if sync_pkg:
                    if pyalpm.vercmp(pkg.version, sync_pkg.version) < 0:
                        icon_name = self.get_installed_icon(pkg.name)
                        updates.append(Package(
                            name=pkg.name,
                            title=pkg.name,
                            desc=pkg.desc or "",
                            version=sync_pkg.version,
                            type="pacman",
                            installed=True,
                            installed_version=pkg.version,
                            icon=icon_name
                        ))
                        break
        return updates

    def get_packages_by_group(self, group_name: str) -> List[Package]:
        self._refresh_localdb()
        results = []
        seen_names = set()
        
        for db in self.syncdbs:
            try:
                for pkg in db.pkgcache:
                    if group_name in pkg.groups:
                        if pkg.name in seen_names:
                            continue
                        seen_names.add(pkg.name)
                        
                        installed = self.is_installed(pkg.name)
                        icon_name = self.get_installed_icon(pkg.name) if installed else ""
                        
                        results.append(Package(
                            name=pkg.name,
                            title=pkg.name,
                            desc=pkg.desc or "",
                            version=pkg.version,
                            type="pacman",
                            installed=installed,
                            installed_version=self.get_installed_version(pkg.name) if installed else "",
                            icon=icon_name
                        ))
            except Exception as e:
                print(f"Error getting group {group_name} from ALPM: {e}")
        return results
