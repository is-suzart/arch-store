from typing import List
from domain.entities import Package
from domain.repositories import PackageRepository

class GetUpdatablePackagesUseCase:
    def __init__(self, alpm_repo: PackageRepository, aur_repo: PackageRepository, flatpak_repo: PackageRepository):
        self.alpm_repo = alpm_repo
        self.aur_repo = aur_repo
        self.flatpak_repo = flatpak_repo
        self.enable_aur = True
        self.enable_flatpak = True

    def execute(self) -> List[Package]:
        updatable = []
        try:
            updatable.extend(self.alpm_repo.get_updatable())
        except Exception as e:
            print(f"Error executing ALPM updates: {e}")
        if self.enable_aur:
            try:
                updatable.extend(self.aur_repo.get_updatable())
            except Exception as e:
                print(f"Error executing AUR updates: {e}")
        if self.enable_flatpak:
            try:
                updatable.extend(self.flatpak_repo.get_updatable())
            except Exception as e:
                print(f"Error executing Flatpak updates: {e}")
        return updatable
