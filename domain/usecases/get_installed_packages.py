from typing import List
from domain.entities import Package
from domain.repositories import PackageRepository

class GetInstalledPackagesUseCase:
    def __init__(self, alpm_repo: PackageRepository, flatpak_repo: PackageRepository):
        self.alpm_repo = alpm_repo
        self.flatpak_repo = flatpak_repo
        self.enable_flatpak = True

    def execute(self) -> List[Package]:
        installed = []
        installed.extend(self.alpm_repo.get_installed())
        if self.enable_flatpak:
            installed.extend(self.flatpak_repo.get_installed())
        return installed
