from typing import List
from domain.entities import Package
from data.repositories.flatpak_repository import FlatpakPackageRepository

class GetPopularPackagesUseCase:
    def __init__(self, flatpak_repo: FlatpakPackageRepository):
        self.flatpak_repo = flatpak_repo

    def execute(self) -> List[Package]:
        return self.flatpak_repo.get_popular()
