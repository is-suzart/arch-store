from typing import List
from domain.entities import Package
from domain.repositories import FeaturedRepository

class GetFeaturedPackagesUseCase:
    def __init__(self, featured_repo: FeaturedRepository):
        self.featured_repo = featured_repo

    def execute(self) -> List[Package]:
        return self.featured_repo.get_featured_packages()
