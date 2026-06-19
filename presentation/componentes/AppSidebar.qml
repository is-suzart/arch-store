import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

MochaDS.Sidebar {
    id: rootSidebar

    // Expose the search text field's text property for external access (e.g. main.qml's searchFor)
    property alias searchText: headerSearchField.text

    //anchors.verticalCenter: parent.verticalCenter
    height: parent.height
    anchors.fill: parentfill
    variant: "floated"
    expandedWidth: 285

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

                placeholder: qsTr("Buscar pacotes...")
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
            label: qsTr("Explorar")
            isActive: window.currentPage === "explore"
            onClicked: {
                window.currentPage = "explore";
            }
        }

        MochaDS.SidebarItem {
            icon: "search"
            label: qsTr("Buscar")
            isActive: window.currentPage === "search"
            onClicked: {
                window.currentPage = "search";
            }
        }

        MochaDS.SidebarItem {
            icon: "gamepad-2"
            label: qsTr("Jogos")
            isActive: window.currentPage === "gaming"
            onClicked: {
                window.refreshInstalledList();
                window.currentPage = "gaming";
            }
        }

        MochaDS.SidebarItem {
            icon: "code"
            label: qsTr("Desenvolvimento")
            isActive: window.currentPage === "development"
            onClicked: {
                window.refreshInstalledList();
                if (typeof developmentView !== "undefined" && developmentView !== null) {
                    developmentView.refresh();
                }
                window.currentPage = "development";
            }
        }


        MochaDS.SidebarItem {
            icon: "folder"
            label: qsTr("Instalados")
            isActive: window.currentPage === "installed"
            onClicked: {
                window.refreshInstalledList();
                window.currentPage = "installed";
            }
        }

        MochaDS.SidebarItem {
            icon: "refresh-cw"
            label: qsTr("Atualizações")
            isActive: window.currentPage === "updates"
            onClicked: {
                window.refreshInstalledList();
                window.currentPage = "updates";
            }
        }

        MochaDS.SidebarItem {
            icon: "layers"
            label: qsTr("Grupos Pacman")

            Repeater {
                model: (typeof backend !== "undefined" && backend) ? backend.getAlpmGroups() : []

                delegate: MochaDS.SidebarItem {
                    icon: modelData.name === "qt6" ? "code" : "monitor"
                    label: modelData.label
                    isActive: window.currentPage === "group_" + modelData.name
                    onClicked: {
                        window.loadGroup(modelData.name, modelData.label);
                    }
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
                text: qsTr("Configurações")
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
