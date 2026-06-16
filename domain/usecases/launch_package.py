import subprocess
import os
from pathlib import Path

class LaunchPackageUseCase:
    def __init__(self, alpm_repo, flatpak_repo):
        self.alpm_repo = alpm_repo
        self.flatpak_repo = flatpak_repo

    def execute(self, pkg_type: str, pkg_name: str) -> bool:
        try:
            if pkg_type == "flatpak":
                subprocess.Popen(["flatpak", "run", pkg_name], start_new_session=True)
                return True
            
            elif pkg_type in ["pacman", "aur"]:
                # Try to find the desktop file to get the Exec command
                pkg = self.alpm_repo.localdb.get_pkg(pkg_name)
                if pkg:
                    for f in pkg.files:
                        file_path = f[0]
                        if "usr/share/applications/" in file_path and file_path.endswith(".desktop"):
                            full_path = "/" + file_path
                            exec_cmd = self._get_exec_from_desktop(full_path)
                            if exec_cmd:
                                # Clean up Exec command (remove %U, %f, etc)
                                import re
                                exec_cmd = re.sub(r'%\w', '', exec_cmd).strip()
                                subprocess.Popen(exec_cmd.split(), start_new_session=True)
                                return True
                
                # Fallback: just try to run the package name as a binary
                subprocess.Popen([pkg_name], start_new_session=True)
                return True
        except Exception as e:
            print(f"Error launching package {pkg_name}: {e}")
        return False

    def _get_exec_from_desktop(self, file_path: str) -> str:
        try:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if line.startswith("Exec="):
                        return line.split("=", 1)[1].strip()
        except Exception:
            pass
        return ""
