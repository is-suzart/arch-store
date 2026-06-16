import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

MochaDS.Sidebar {
    id: rootSidebar

    anchors.verticalCenter: parent.verticalCenter
    variant: "floated"
    expandedWidth: 285

    // Expose the search text field's text property for external access (e.g. main.qml's searchFor)
    property alias searchText: headerSearchField.text

    MochaDS.SidebarHeader {
        height: 130

        Column {
            width: parent.width
            spacing: MochaDS.Theme.spacing.md
            anchors.verticalCenter: parent.verticalCenter

            Row {
                spacing: MochaDS.Theme.spacing.sm
                anchors.horizontalCenter: parent.horizontalCenter

                MochaDS.LucideIcon {
                    name: "package"
                    size: 24
                    color: MochaDS.Theme.colors.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Arch Store"
                    font.family: MochaDS.Theme.typography.familyBold
                    font.pixelSize: MochaDS.Theme.typography.sizeLg
                    color: MochaDS.Theme.colors.text
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            MochaDS.TextField {
                id: headerSearchField

                placeholder: "Buscar pacotes..."
                iconLeft: "search"
                width: parent.width - MochaDS.Theme.spacing.lg * 2
                anchors.horizontalCenter: parent.horizontalCenter
                onTextChanged: {
                    window.searchQuery = text;
                    if (text.length > 2 && window.currentPage !== "search")
                        window.currentPage = "search";

                    window.triggerSearch(text, false);
                }
            }

        }

    }

    MochaDS.SidebarSection {
        spacing: 8

        MochaDS.SidebarItem {
            icon: "compass"
            label: "Explorar"
            isActive: window.currentPage === "explore"
            onClicked: {
                window.currentPage = "explore";
            }
        }

        MochaDS.SidebarItem {
            icon: "search"
            label: "Buscar"
            isActive: window.currentPage === "search"
            onClicked: {
                window.currentPage = "search";
            }
        }

        MochaDS.SidebarItem {
            icon: "gamepad-2"
            label: "Jogos"
            isActive: window.currentPage === "gaming"
            onClicked: {
                window.runWithLoader("Carregando jogos e ferramentas...", function() {
                    window.refreshInstalledList();
                    window.currentPage = "gaming";
                });
            }
        }

        MochaDS.SidebarItem {
            icon: "folder"
            label: "Instalados"
            isActive: window.currentPage === "installed"
            onClicked: {
                window.runWithLoader("Carregando aplicativos instalados...", function() {
                    window.refreshInstalledList();
                    window.currentPage = "installed";
                });
            }
        }

        MochaDS.SidebarItem {
            icon: "refresh-cw"
            label: "Atualizações"
            isActive: window.currentPage === "updates"
            onClicked: {
                window.runWithLoader("Buscando atualizações...", function() {
                    window.refreshInstalledList();
                    window.currentPage = "updates";
                });
            }
        }

        MochaDS.SidebarItem {
            icon: "layers"
            label: "Grupos Pacman"
            
            MochaDS.SidebarItem {
                icon: "monitor"
                label: "GNOME"
                isActive: window.currentPage === "group_gnome"
                onClicked: {
                    window.loadGroup("gnome", "Ambiente GNOME");
                }
            }
            MochaDS.SidebarItem {
                icon: "monitor"
                label: "KDE"
                isActive: window.currentPage === "group_kde-system"
                onClicked: {
                    window.loadGroup("kde-system", "Ambiente KDE");
                }
            }
            MochaDS.SidebarItem {
                icon: "monitor"
                label: "XFCE"
                isActive: window.currentPage === "group_xfce4"
                onClicked: {
                    window.loadGroup("xfce4", "Ambiente XFCE");
                }
            }
            MochaDS.SidebarItem {
                icon: "code"
                label: "Qt6"
                isActive: window.currentPage === "group_qt6"
                onClicked: {
                    window.loadGroup("qt6", "Desenvolvimento Qt6");
                }
            }
        }

    }

    // Configurações footer section
    MochaDS.SidebarFooter {
        id: sidebarFooter

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: MochaDS.Theme.spacing.sm
            anchors.rightMargin: MochaDS.Theme.spacing.sm
            spacing: MochaDS.Theme.spacing.xs

            MochaDS.Button {
                text: "Configurações"
                icon: "settings"
                variant: window.currentPage === "settings" ? "tonal" : "ghost"
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    window.currentPage = "settings";
                }
            }
        }
    }
}
