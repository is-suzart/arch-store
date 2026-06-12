from abc import ABC, abstractmethod
from typing import List
from .entities import Package

class PackageRepository(ABC):
    @abstractmethod
    def search(self, query: str) -> List[Package]:
        pass

    @abstractmethod
    def get_installed(self) -> List[Package]:
        pass

    @abstractmethod
    def get_install_command(self, pkg_name: str) -> List[str]:
        pass

    @abstractmethod
    def get_uninstall_command(self, pkg_name: str) -> List[str]:
        pass
