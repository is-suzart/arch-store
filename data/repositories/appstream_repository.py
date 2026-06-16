import gi
gi.require_version('AppStream', '1.0')
from gi.repository import AppStream
from typing import List
import json
from pathlib import Path
from domain.entities import Package
from domain.repositories import FeaturedRepository

class AppStreamFeaturedRepository(FeaturedRepository):
    def __init__(self, alpm_repo, flatpak_repo):
        self.alpm_repo = alpm_repo
        self.flatpak_repo = flatpak_repo
        self.pool = AppStream.Pool()
        self.pool.load()
        self._pkgname_map = None
        
    def get_packages_from_file(self, config_filename: str, fallback_ids: List[str]) -> List[Package]:
        config_path = Path(__file__).parent.parent.parent / "data" / config_filename
        app_ids = fallback_ids
        
        if config_path.exists():
            try:
                with open(config_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if isinstance(data, list):
                        app_ids = data
            except Exception as e:
                print(f"Error loading {config_filename}: {e}")
                
        results = []
        for app_id in app_ids:
            try:
                comp_box = self.pool.get_components_by_id(app_id)
                comps = comp_box.as_array() if hasattr(comp_box, 'as_array') else list(comp_box)
                if not comps:
                    # Fallback: Treat app_id as a pacman or AUR package name directly
                    installed = self.alpm_repo.is_installed(app_id)
                    installed_version = self.alpm_repo.get_installed_version(app_id) if installed else ""
                    
                    if installed:
                        pkg_type = "pacman"
                        version = installed_version
                        desc = "Pacote de sistema instalado."
                    else:
                        version = ""
                        desc = ""
                        for db in self.alpm_repo.syncdbs:
                            try:
                                pkg = db.get_pkg(app_id)
                                if pkg:
                                    version = pkg.version
                                    desc = pkg.desc or ""
                                    break
                            except Exception:
                                pass
                        
                        if version:
                            pkg_type = "pacman"
                        else:
                            # Not in pacman repos, assume AUR
                            pkg_type = "aur"
                            version = "latest"
                            desc = "Ferramenta/Biblioteca de jogos (AUR)"
                            
                    results.append(Package(
                        name=app_id,
                        title=app_id.replace("-bin", "").replace("-git", "").replace("-", " ").title(),
                        desc=desc or "Pacote utilitário de jogos.",
                        version=version or "latest",
                        type=pkg_type,
                        installed=installed,
                        installed_version=installed_version,
                        icon="package"
                    ))
                    continue
                
                # Prefer the component that has a package name
                selected_comp = comps[0]
                for c in comps:
                    if c.get_pkgname():
                        selected_comp = c
                        break
                
                pkg_name = selected_comp.get_pkgname()
                
                if pkg_name:
                    pkg_type = "pacman"
                    installed = self.alpm_repo.is_installed(pkg_name)
                    installed_version = self.alpm_repo.get_installed_version(pkg_name) if installed else ""
                    
                    version = installed_version
                    if not version:
                        for db in self.alpm_repo.syncdbs:
                            try:
                                pkg = db.get_pkg(pkg_name)
                                if pkg:
                                    version = pkg.version
                                    break
                            except Exception:
                                pass
                    if not version:
                        version = "latest"
                else:
                    pkg_name = selected_comp.get_id()
                    pkg_type = "flatpak"
                    installed = self.flatpak_repo.is_installed(pkg_name)
                    installed_version = ""
                    if installed:
                        installed_flatpaks = self.flatpak_repo._get_installed_flatpaks()
                        installed_version = installed_flatpaks.get(pkg_name, "")
                    version = installed_version or "latest"
                
                icon_name = ""
                icons = selected_comp.get_icons()
                if icons:
                    selected_icon = icons[0]
                    for ic in icons:
                        if hasattr(ic, 'get_kind') and ic.get_kind() == 1:
                            selected_icon = ic
                            break
                    if hasattr(selected_icon, 'get_name'):
                        icon_name = selected_icon.get_name()
                        if icon_name.endswith((".png", ".svg", ".xpm")):
                            icon_name = icon_name.rsplit(".", 1)[0]
                
                if not icon_name:
                    icon_name = pkg_name or app_id
                
                results.append(Package(
                    name=pkg_name,
                    title=selected_comp.get_name() or pkg_name,
                    desc=selected_comp.get_summary() or "",
                    version=version,
                    type=pkg_type,
                    installed=installed,
                    installed_version=installed_version,
                    icon=icon_name
                ))
            except Exception as e:
                print(f"Error processing app_id {app_id}: {e}")
                
        return results

    def get_featured_packages(self) -> List[Package]:
        fallback_ids = [
            "org.mozilla.firefox",
            "com.visualstudio.code",
            "org.kde.kdenlive",
            "org.gimp.GIMP",
            "org.videolan.VLC",
            "org.inkscape.Inkscape",
            "org.blender.Blender",
            "com.valvesoftware.Steam",
            "org.libreoffice.LibreOffice",
            "org.telegram.desktop"
        ]
        return self.get_packages_from_file("featured_apps.json", fallback_ids)

    def get_gaming_packages(self) -> List[Package]:
        fallback_ids = [
            "com.valvesoftware.Steam",
            "net.lutris.Lutris",
            "com.github.benjamimgois.goverlay",
            "gamemode",
            "mangohud",
            "com.discordapp.Discord",
            "com.heroicgameslauncher.hgl",
            "hydra-games-launcher-bin",
            "wine",
            "winetricks",
            "com.github.Mathew148.Protontricks",
            "net.davidotek.pupgui2"
        ]
        return self.get_packages_from_file("gaming_apps.json", fallback_ids)

    def get_hero_apps(self) -> List[dict]:
        """Return up to 6 apps with hero image data for the Explore page carousel.

        Each dict contains:
          - All Package fields (name, title, desc, version, type, installed, icon)
          - hero_image: URL of the first DEFAULT/SOURCE screenshot
          - brand_color_light: branding primary color for light scheme (or default)
          - brand_color_dark:  branding primary color for dark scheme (or default)
        """
        hero_ids = [
            "com.valvesoftware.Steam",
            "org.libreoffice.LibreOffice",
            "net.lutris.Lutris",
            "com.heroicgameslauncher.hgl",
            "com.visualstudio.code",
            "org.gimp.GIMP",
        ]

        # Fallback accent colors (Catppuccin Mocha tones) per app when branding absent
        fallback_colors = {
            "com.valvesoftware.Steam":        {"light": "#c6d0f5", "dark": "#1b2838"},
            "org.libreoffice.LibreOffice":    {"light": "#c6d0f5", "dark": "#18A303"},
            "net.lutris.Lutris":              {"light": "#f4b8e4", "dark": "#cc5500"},
            "com.heroicgameslauncher.hgl":    {"light": "#ac9aac", "dark": "#1c202c"},
            "com.visualstudio.code":          {"light": "#c6d0f5", "dark": "#0078d4"},
            "org.gimp.GIMP":                  {"light": "#f4b8e4", "dark": "#4e3e6e"},
        }

        IMAGE_KIND_SOURCE = AppStream.ImageKind.SOURCE
        results = []

        for app_id in hero_ids:
            try:
                comp_box = self.pool.get_components_by_id(app_id)
                comps = comp_box.as_array() if hasattr(comp_box, 'as_array') else list(comp_box)
                if not comps:
                    continue
                comp = comps[0]

                # ── Hero image: first DEFAULT screenshot, SOURCE size ──────────────
                hero_image = ""
                for sc in comp.get_screenshots_all():
                    for img in sc.get_images_all():
                        if img.get_kind() == IMAGE_KIND_SOURCE:
                            hero_image = img.get_url() or ""
                            break
                    if hero_image:
                        break

                # ── Branding colors ───────────────────────────────────────────────
                fb = fallback_colors.get(app_id, {"light": "#c6d0f5", "dark": "#1e1e2e"})
                brand_light = fb["light"]
                brand_dark  = fb["dark"]
                branding = comp.get_branding()
                if branding:
                    try:
                        c = branding.get_color(AppStream.ColorKind.PRIMARY, AppStream.ColorSchemeKind.LIGHT)
                        if c:
                            brand_light = c
                    except Exception:
                        pass
                    try:
                        c = branding.get_color(AppStream.ColorKind.PRIMARY, AppStream.ColorSchemeKind.DARK)
                        if c:
                            brand_dark = c
                    except Exception:
                        pass

                # ── Package metadata ──────────────────────────────────────────────
                pkg_name = comp.get_pkgname() or app_id
                if comp.get_pkgname():
                    pkg_type = "pacman"
                    installed = self.alpm_repo.is_installed(pkg_name)
                    installed_version = self.alpm_repo.get_installed_version(pkg_name) if installed else ""
                    version = installed_version
                    if not version:
                        for db in self.alpm_repo.syncdbs:
                            try:
                                pkg = db.get_pkg(pkg_name)
                                if pkg:
                                    version = pkg.version
                                    break
                            except Exception:
                                pass
                    version = version or "latest"
                else:
                    pkg_name = app_id
                    pkg_type = "flatpak"
                    installed = self.flatpak_repo.is_installed(pkg_name)
                    installed_version = ""
                    if installed:
                        installed_flatpaks = self.flatpak_repo._get_installed_flatpaks()
                        installed_version = installed_flatpaks.get(pkg_name, "")
                    version = installed_version or "latest"

                # ── Icon ──────────────────────────────────────────────────────────
                icon_name = ""
                icons = comp.get_icons()
                if icons:
                    icon_name = icons[0].get_name() if hasattr(icons[0], 'get_name') else ""
                    if icon_name.endswith((".png", ".svg", ".xpm")):
                        icon_name = icon_name.rsplit(".", 1)[0]
                if not icon_name:
                    icon_name = pkg_name

                results.append({
                    "name":              pkg_name,
                    "title":             comp.get_name() or pkg_name,
                    "desc":              comp.get_summary() or "",
                    "version":           version,
                    "type":              pkg_type,
                    "installed":         installed,
                    "installed_version": installed_version,
                    "icon":              icon_name,
                    "hero_image":        hero_image,
                    "brand_color_light": brand_light,
                    "brand_color_dark":  brand_dark,
                })
            except Exception as e:
                print(f"[hero] Error processing {app_id}: {e}")

        return results

    def get_app_hero_image(self, name: str, pkg_type: str) -> str:
        """Return the first SOURCE screenshot URL for any package, or empty string.

        Strategy:
        - flatpak: name IS the AppStream component id  (e.g. com.discordapp.Discord)
        - pacman / aur: search pool by pkgname, then fall back to id search
        """
        IMAGE_KIND_SOURCE = AppStream.ImageKind.SOURCE

        def _first_screenshot(comp) -> str:
            for sc in comp.get_screenshots_all():
                for img in sc.get_images_all():
                    if img.get_kind() == IMAGE_KIND_SOURCE:
                        url = img.get_url() or ""
                        if url:
                            return url
            return ""

        try:
            if pkg_type == "flatpak":
                comp_box = self.pool.get_components_by_id(name)
                comps = comp_box.as_array() if hasattr(comp_box, 'as_array') else list(comp_box)
                if comps:
                    return _first_screenshot(comps[0])
            else:
                # pacman / aur: search by pkgname using lazy map
                if self._pkgname_map is None:
                    self._pkgname_map = {}
                    comps = self.pool.get_components()
                    arr = comps.as_array() if hasattr(comps, 'as_array') else list(comps)
                    for c in arr:
                        pkgname = c.get_pkgname()
                        if pkgname:
                            self._pkgname_map[pkgname] = c

                comp = self._pkgname_map.get(name)
                if comp:
                    return _first_screenshot(comp)

                # fallback: try name as an app-id
                comp_box = self.pool.get_components_by_id(name)
                comps = comp_box.as_array() if hasattr(comp_box, 'as_array') else list(comp_box)
                if comps:
                    return _first_screenshot(comps[0])
        except Exception as e:
            print(f"[hero_image] Error for {pkg_type}/{name}: {e}")

        return ""
