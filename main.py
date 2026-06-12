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

# Domain layer
from domain.usecases.search_packages import SearchPackagesUseCase
from domain.usecases.get_installed_packages import GetInstalledPackagesUseCase
from domain.usecases.install_package import InstallPackageUseCase
from domain.usecases.uninstall_package import UninstallPackageUseCase

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

    search_usecase = SearchPackagesUseCase(alpm_repo, aur_repo, flatpak_repo)
    get_installed_usecase = GetInstalledPackagesUseCase(alpm_repo, flatpak_repo)
    install_usecase = InstallPackageUseCase(alpm_repo, aur_repo, flatpak_repo)
    uninstall_usecase = UninstallPackageUseCase(alpm_repo, aur_repo, flatpak_repo)

    backend = Backend(
        search_usecase=search_usecase,
        get_installed_usecase=get_installed_usecase,
        install_usecase=install_usecase,
        uninstall_usecase=uninstall_usecase
    )

    engine.rootContext().setContextProperty("backend", backend)

    qml_file = str(current_dir / "presentation" / "qml" / "main.qml")
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
