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

def get_base_path():
    import sys
    from pathlib import Path
    if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
        return Path(sys._MEIPASS)
    return Path(__file__).parent.absolute()

if __name__ == "__main__":
    app = QApplication(sys.argv)

    from PySide6.QtCore import QTranslator, QLocale
    translator = QTranslator()
    current_dir = get_base_path()
    locale_dir = current_dir / "locale"
    
    # Read language preference from config.json
    config_path = Path.home() / ".config" / "arch-store" / "config.json"
    lang_code = "system"
    if config_path.exists():
        try:
            import json
            with open(config_path, "r", encoding="utf-8") as f:
                config_data = json.load(f)
                lang_code = config_data.get("language", "system")
        except Exception as e:
            print(f"Error reading language from config in main.py: {e}")

    if lang_code and lang_code != "system":
        locale = QLocale(lang_code)
    else:
        locale = QLocale.system()

    # Load translator based on selected locale
    if translator.load(locale, "arch-store", "_", str(locale_dir)):
        app.installTranslator(translator)
        print(f"Loaded translation for locale: {locale.name()}")
    else:
        print(f"No translation found for locale: {locale.name()}, falling back to system default (pt_BR)")

    engine = QQmlApplicationEngine()

    # Register native system theme icon provider
    from presentation.system_icon_provider import SystemIconProvider
    engine.addImageProvider("theme", SystemIconProvider())

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
    from domain.usecases.get_development_packages import GetDevelopmentPackagesUseCase
    get_development_usecase = GetDevelopmentPackagesUseCase(appstream_repo)
    
    from domain.usecases.get_updatable_packages import GetUpdatablePackagesUseCase
    get_updatable_usecase = GetUpdatablePackagesUseCase(alpm_repo, aur_repo, flatpak_repo)

    from domain.usecases.get_group_packages import GetGroupPackagesUseCase
    get_group_packages_usecase = GetGroupPackagesUseCase(alpm_repo)

    from domain.usecases.launch_package import LaunchPackageUseCase
    launch_usecase = LaunchPackageUseCase(alpm_repo, flatpak_repo)

    backend = Backend(
        search_usecase=search_usecase,
        get_installed_usecase=get_installed_usecase,
        install_usecase=install_usecase,
        uninstall_usecase=uninstall_usecase,
        get_featured_usecase=get_featured_usecase,
        get_popular_usecase=get_popular_usecase,
        get_gaming_usecase=get_gaming_usecase,
        get_development_usecase=get_development_usecase,
        get_updatable_usecase=get_updatable_usecase,
        appstream_repo=appstream_repo,
        get_group_packages_usecase=get_group_packages_usecase,
        launch_usecase=launch_usecase
    )



    engine.rootContext().setContextProperty("backend", backend)

    qml_file = str(current_dir / "presentation" / "main.qml")
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
