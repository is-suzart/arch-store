import requests
from typing import List
from domain.entities import Package
from domain.repositories import PackageRepository

class AurPackageRepository(PackageRepository):
    def __init__(self, alpm_repository=None):
        self.alpm_repository = alpm_repository

    def search(self, query: str) -> List[Package]:
        if not query:
            return []
            
        results = []
        try:
            r = requests.get(f"https://aur.archlinux.org/rpc/?v=5&type=search&arg={query}")
            if r.status_code == 200:
                aur_data = r.json().get("results", [])
                for pkg in aur_data[:30]:  # limit to top 30
                    name = pkg.get("Name", "")
                    
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
        except Exception as e:
            print(f"Error searching AUR: {e}")
            
        return results

    def get_installed(self) -> List[Package]:
        return []

    def get_install_command(self, pkg_name: str) -> List[str]:
        return ["yay", "--sudo", "pkexec", "--noconfirm", "-S", pkg_name]

    def get_uninstall_command(self, pkg_name: str) -> List[str]:
        return ["yay", "--sudo", "pkexec", "--noconfirm", "-Rns", pkg_name]
