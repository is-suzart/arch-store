from typing import List
from domain.repositories import PackageRepository

class InstallPackageUseCase:
    def __init__(self, alpm_repo: PackageRepository, aur_repo: PackageRepository, flatpak_repo: PackageRepository):
        self.alpm_repo = alpm_repo
        self.aur_repo = aur_repo
        self.flatpak_repo = flatpak_repo

    def execute(self, pkg_type: str, pkg_name: str) -> List[str]:
        if pkg_type == "pacman":
            return self.alpm_repo.get_install_command(pkg_name)
        elif pkg_type == "aur":
            return self.aur_repo.get_install_command(pkg_name)
        elif pkg_type == "flatpak":
            return self.flatpak_repo.get_install_command(pkg_name)
        return []
