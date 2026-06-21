import requests
import shutil
from typing import List
from domain.entities import Package
from domain.repositories import PackageRepository

class AurPackageRepository(PackageRepository):
    def __init__(self, alpm_repository=None):
        self.alpm_repository = alpm_repository
        self.helper = "yay" if shutil.which("yay") else ("paru" if shutil.which("paru") else "yay")

    def search(self, query: str) -> List[Package]:
        if not query:
            return []

        results = []

        # Normalize: lowercase and replace spaces with hyphens to match AUR naming conventions
        # e.g. "Google Chrome" → "google-chrome"
        normalized_query = query.strip().lower().replace(" ", "-")

        # Use by=name-desc to search both package name and description
        seen_names = set()
        for search_query in dict.fromkeys([normalized_query, query.strip()]):
            try:
                r = requests.get(
                    f"https://aur.archlinux.org/rpc/?v=5&type=search&by=name-desc&arg={requests.utils.quote(search_query)}",
                    timeout=10
                )
                if r.status_code == 200:
                    aur_data = r.json().get("results", [])
                    for pkg in aur_data:
                        name = pkg.get("Name", "")
                        if name in seen_names:
                            continue
                        seen_names.add(name)

                        installed = False
                        installed_version = ""
                        if self.alpm_repository:
                            installed = self.alpm_repository.is_installed(name)
                            if installed:
                                installed_version = self.alpm_repository.get_installed_version(name)

                        results.append(Package(
                            name=name,
                            title=name,
                            desc=pkg.get("Description") or "",
                            version=pkg.get("Version", ""),
                            type="aur",
                            installed=installed,
                            installed_version=installed_version
                        ))
                        if len(results) >= 30:
                            break
            except Exception as e:
                print(f"Error searching AUR: {e}")

            if len(results) >= 30:
                break

        return results


    def get_installed(self) -> List[Package]:
        return []

    def get_install_command(self, pkg_name: str) -> List[str]:
        return [self.helper, "--sudoflags", "-A", "--noconfirm", "-S", pkg_name]

    def get_uninstall_command(self, pkg_name: str) -> List[str]:
        return [self.helper, "--sudoflags", "-A", "--noconfirm", "-Rns", pkg_name]

    def get_updatable(self) -> List[Package]:
        if not self.alpm_repository:
            return []
        self.alpm_repository._refresh_localdb()
        localdb = self.alpm_repository.localdb
        syncdbs = self.alpm_repository.syncdbs
        
        # Find foreign packages
        foreign = []
        for pkg in localdb.pkgcache:
            found_in_sync = False
            for db in syncdbs:
                if db.get_pkg(pkg.name):
                    found_in_sync = True
                    break
            if not found_in_sync:
                foreign.append(pkg)
                
        # Query AUR RPC in chunks
        aur_updates = []
        chunk_size = 50
        for i in range(0, len(foreign), chunk_size):
            chunk = foreign[i:i+chunk_size]
            args = '&'.join([f'arg[]={pkg.name}' for pkg in chunk])
            try:
                r = requests.get(f"https://aur.archlinux.org/rpc/?v=5&type=info&{args}", timeout=10)
                if r.status_code == 200:
                    results = r.json().get("results", [])
                    for aur_pkg in results:
                        name = aur_pkg.get("Name")
                        aur_ver = aur_pkg.get("Version")
                        local_pkg = next((p for p in chunk if p.name == name), None)
                        if local_pkg and aur_ver:
                            import pyalpm
                            if pyalpm.vercmp(local_pkg.version, aur_ver) < 0:
                                icon_name = self.alpm_repository.get_installed_icon(name)
                                aur_updates.append(Package(
                                    name=name,
                                    title=name,
                                    desc=aur_pkg.get("Description") or "",
                                    version=aur_ver,
                                    type="aur",
                                    installed=True,
                                    installed_version=local_pkg.version,
                                    icon=icon_name
                                ))
            except Exception as e:
                print(f"Error checking AUR updates: {e}")
        return aur_updates
