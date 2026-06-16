from typing import List
from domain.entities import Package
from domain.repositories import PackageRepository

class GetGroupPackagesUseCase:
    def __init__(self, alpm_repo: PackageRepository):
        self.alpm_repo = alpm_repo

    def execute(self, group_name: str) -> List[Package]:
        if not group_name:
            return []
        try:
            return self.alpm_repo.get_packages_by_group(group_name)
        except Exception as e:
            print(f"Error getting packages for group {group_name}: {e}")
            return []
