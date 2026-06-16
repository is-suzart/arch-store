import gi
gi.require_version('Flatpak', '1.0')
from gi.repository import Flatpak
import requests
from typing import List
from domain.entities import Package
from domain.repositories import PackageRepository

class FlatpakPackageRepository(PackageRepository):
    def __init__(self):
        pass

    def _get_installed_flatpaks(self) -> dict:
        installed_flatpaks = {}
        for inst_func in [Flatpak.Installation.new_system, Flatpak.Installation.new_user]:
            try:
                inst = inst_func(None)
                for ref in inst.list_installed_refs(None):
                    if ref.get_kind() == Flatpak.RefKind.APP:
                        installed_flatpaks[ref.get_name()] = ref.get_appdata_version() or ""
            except Exception:
                pass
        return installed_flatpaks

    def search(self, query: str) -> List[Package]:
        if not query:
            return []
            
        results = []
        try:
            r = requests.post("https://flathub.org/api/v2/search", json={"query": query})
            if r.status_code == 200:
                hits = r.json().get("hits", [])
                installed_flatpaks = self._get_installed_flatpaks()
                
                for hit in hits[:30]:
                    app_id = hit.get("app_id") or hit.get("id")
                    if not app_id:
                        continue
                        
                    installed = app_id in installed_flatpaks
                    results.append(Package(
                        name=app_id,
                        title=hit.get("name") or app_id,
                        desc=hit.get("summary") or "",
                        version=hit.get("version") or "",
                        type="flatpak",
                        installed=installed,
                        installed_version=installed_flatpaks.get(app_id, "") if installed else "",
                        icon=hit.get("icon") or ""
                    ))
        except Exception as e:
            print(f"Error searching Flatpak: {e}")
            
        return results

    def get_installed(self) -> List[Package]:
        installed = []
        for inst_func in [Flatpak.Installation.new_system, Flatpak.Installation.new_user]:
            try:
                inst = inst_func(None)
                for ref in inst.list_installed_refs(None):
                    if ref.get_kind() == Flatpak.RefKind.APP:
                        installed.append(Package(
                            name=ref.get_name(),
                            title=ref.get_appdata_name() or ref.get_name(),
                            desc=ref.get_appdata_summary() or "",
                            version=ref.get_appdata_version() or "",
                            type="flatpak",
                            installed=True,
                            installed_version=ref.get_appdata_version() or ""
                        ))
            except Exception as e:
                print(f"Error loading installed flatpak: {e}")
        return installed

    def is_installed(self, app_id: str) -> bool:
        return app_id in self._get_installed_flatpaks()

    def get_popular(self) -> List[Package]:
        results = []
        try:
            r = requests.get("https://flathub.org/api/v2/collection/popular", timeout=5)
            if r.status_code == 200:
                hits = r.json().get("hits", [])
                installed_flatpaks = self._get_installed_flatpaks()
                
                for hit in hits[:12]:
                    app_id = hit.get("app_id") or hit.get("id")
                    if not app_id:
                        continue
                    installed = app_id in installed_flatpaks
                    results.append(Package(
                        name=app_id,
                        title=hit.get("name") or app_id,
                        desc=hit.get("summary") or "",
                        version=hit.get("version") or "latest",
                        type="flatpak",
                        installed=installed,
                        installed_version=installed_flatpaks.get(app_id, "") if installed else "",
                        icon=hit.get("icon") or ""
                    ))
        except Exception as e:
            print(f"Error fetching popular flatpaks: {e}")
            
        return results

    def get_install_command(self, pkg_name: str) -> List[str]:
        # Robust command: ensure flathub remote is added and install from it explicitly
        return [
            "sh", "-c", 
            f"flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && "
            f"flatpak install --user -y flathub '{pkg_name}'"
        ]

    def get_uninstall_command(self, pkg_name: str) -> List[str]:
        # Try to uninstall from user first, then system (if possible without sudo, though system usually needs it)
        # But for consistency with install, we prioritize --user
        return ["flatpak", "uninstall", "--user", "-y", pkg_name]

    def get_updatable(self) -> List[Package]:
        updates = []
        for inst_func in [Flatpak.Installation.new_system, Flatpak.Installation.new_user]:
            try:
                inst = inst_func(None)
                for ref in inst.list_installed_refs(None):
                    if ref.get_kind() == Flatpak.RefKind.APP:
                        local_commit = ref.get_commit()
                        try:
                            remote_ref = inst.fetch_remote_ref_sync(ref.get_remote(), ref.get_kind(), ref.get_name(), ref.get_arch(), ref.get_branch(), None)
                            if remote_ref:
                                remote_commit = remote_ref.get_commit()
                                if local_commit != remote_commit:
                                    updates.append(Package(
                                        name=ref.get_name(),
                                        title=ref.get_appdata_name() or ref.get_name(),
                                        desc=ref.get_appdata_summary() or "",
                                        version=remote_ref.get_appdata_version() or "latest",
                                        type="flatpak",
                                        installed=True,
                                        installed_version=ref.get_appdata_version() or "",
                                        icon=""
                                    ))
                        except Exception:
                            pass
            except Exception as e:
                print(f"Error checking flatpak updates: {e}")
        return updates

