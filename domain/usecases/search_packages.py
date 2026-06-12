from typing import List
from domain.entities import Package
from domain.repositories import PackageRepository

class SearchPackagesUseCase:
    def __init__(self, alpm_repo: PackageRepository, aur_repo: PackageRepository, flatpak_repo: PackageRepository):
        self.alpm_repo = alpm_repo
        self.aur_repo = aur_repo
        self.flatpak_repo = flatpak_repo

    def execute(self, query: str) -> List[Package]:
        if not query:
            return []
            
        results = []
        
        # 1. Search Pacman
        alpm_results = self.alpm_repo.search(query)
        results.extend(alpm_results)
        
        pacman_names = {pkg.name for pkg in alpm_results}
        
        # 2. Search AUR
        aur_results = self.aur_repo.search(query)
        # Filter duplicates where name matches pacman packages
        aur_filtered = [pkg for pkg in aur_results if pkg.name not in pacman_names]
        results.extend(aur_filtered)
        
        # 3. Search Flatpak
        flatpak_results = self.flatpak_repo.search(query)
        results.extend(flatpak_results)
        
        return results
