from typing import List
from domain.entities import Package
from data.repositories.appstream_repository import AppStreamFeaturedRepository

class GetDevelopmentPackagesUseCase:
    def __init__(self, appstream_repo: AppStreamFeaturedRepository):
        self.appstream_repo = appstream_repo

    def execute(self) -> List[Package]:
        return self.appstream_repo.get_development_packages()
