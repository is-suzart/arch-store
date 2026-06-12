from dataclasses import dataclass

@dataclass
class Package:
    name: str
    title: str
    desc: str
    version: str
    type: str # 'pacman', 'aur', or 'flatpak'
    installed: bool
    installed_version: str
    icon: str = ""

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "title": self.title,
            "desc": self.desc,
            "version": self.version,
            "type": self.type,
            "installed": self.installed,
            "installedVersion": self.installed_version,
            "icon": self.icon
        }
