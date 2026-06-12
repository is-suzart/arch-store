from typing import List
from domain.entities import Package
from domain.repositories import PackageRepository

class GetInstalledPackagesUseCase:
    def __init__(self, alpm_repo: PackageRepository, flatpak_repo: PackageRepository):
        self.alpm_repo = alpm_repo
        self.flatpak_repo = flatpak_repo

    def execute(self) -> List[Package]:
        installed = []
        installed.extend(self.alpm_repo.get_installed())
        installed.extend(self.flatpak_repo.get_installed())
        return installed
