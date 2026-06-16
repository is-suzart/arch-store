import sys
import os
os.environ["QML_XHR_ALLOW_FILE_READ"] = "1"
from pathlib import Path

from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

# Data layer
from data.repositories.alpm_repository import AlpmPackageRepository
from data.repositories.aur_repository import AurPackageRepository
from data.repositories.flatpak_repository import FlatpakPackageRepository
from data.repositories.appstream_repository import AppStreamFeaturedRepository

# Domain layer
from domain.usecases.search_packages import SearchPackagesUseCase
from domain.usecases.get_installed_packages import GetInstalledPackagesUseCase
from domain.usecases.install_package import InstallPackageUseCase
from domain.usecases.uninstall_package import UninstallPackageUseCase
from domain.usecases.get_featured_packages import GetFeaturedPackagesUseCase
from domain.usecases.get_popular_packages import GetPopularPackagesUseCase
from domain.usecases.get_gaming_packages import GetGamingPackagesUseCase

# Presentation layer
from presentation.backend import Backend

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # Register native system theme icon provider
    from presentation.system_icon_provider import SystemIconProvider
    engine.addImageProvider("theme", SystemIconProvider())

    current_dir = Path(__file__).parent.absolute()
    engine.addImportPath(str(current_dir / "qml_modules"))

    # Dependency Injection Setup
    alpm_repo = AlpmPackageRepository()
    aur_repo = AurPackageRepository(alpm_repo)
    flatpak_repo = FlatpakPackageRepository()
    appstream_repo = AppStreamFeaturedRepository(alpm_repo, flatpak_repo)

    search_usecase = SearchPackagesUseCase(alpm_repo, aur_repo, flatpak_repo)
    get_installed_usecase = GetInstalledPackagesUseCase(alpm_repo, flatpak_repo)
    install_usecase = InstallPackageUseCase(alpm_repo, aur_repo, flatpak_repo)
    uninstall_usecase = UninstallPackageUseCase(alpm_repo, aur_repo, flatpak_repo)
    get_featured_usecase = GetFeaturedPackagesUseCase(appstream_repo)
    get_popular_usecase = GetPopularPackagesUseCase(flatpak_repo)
    get_gaming_usecase = GetGamingPackagesUseCase(appstream_repo)
    
    from domain.usecases.get_updatable_packages import GetUpdatablePackagesUseCase
    get_updatable_usecase = GetUpdatablePackagesUseCase(alpm_repo, aur_repo, flatpak_repo)

    from domain.usecases.get_group_packages import GetGroupPackagesUseCase
    get_group_packages_usecase = GetGroupPackagesUseCase(alpm_repo)

    backend = Backend(
        search_usecase=search_usecase,
        get_installed_usecase=get_installed_usecase,
        install_usecase=install_usecase,
        uninstall_usecase=uninstall_usecase,
        get_featured_usecase=get_featured_usecase,
        get_popular_usecase=get_popular_usecase,
        get_gaming_usecase=get_gaming_usecase,
        get_updatable_usecase=get_updatable_usecase,
        appstream_repo=appstream_repo,
        get_group_packages_usecase=get_group_packages_usecase,
    )


    engine.rootContext().setContextProperty("backend", backend)

    qml_file = str(current_dir / "presentation" / "main.qml")
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
