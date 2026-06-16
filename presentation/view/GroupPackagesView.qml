import "../componentes"
import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property string groupName: ""
    property string groupLabel: ""
    property var groupApps: []
    property bool loading: false
    property string viewMode: "list" // default to list first!

    function refresh() {
        if (!groupName) return;
        loading = true;
        refreshTimer.start();
    }

    Timer {
        id: refreshTimer
        interval: 150
        repeat: false
        onTriggered: {
            var list = backend.getGroupPackages(groupName);
            groupApps = list;
            loading = false;
        }
    }

    onGroupNameChanged: {
        refresh();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        // Header Section
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            spacing: MochaDS.Theme.spacing.md

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: root.groupLabel !== "" ? root.groupLabel : "Grupo Pacman"
                    font.family: MochaDS.Theme.typography.familyBold
                    font.pixelSize: MochaDS.Theme.typography.sizeH2
                    color: MochaDS.Theme.colors.text
                }
                Text {
                    text: "Pacotes oficiais do Arch Linux pertencentes ao grupo '" + root.groupName + "'"
                    font.family: MochaDS.Theme.typography.family
                    font.pixelSize: MochaDS.Theme.typography.sizeSm
                    color: MochaDS.Theme.colors.subtext0
                }
            }

            // View Mode Selector
            MochaDS.ButtonGroup {
                expand: false
                currentIndex: root.viewMode === "grid" ? 0 : 1
                Layout.alignment: Qt.AlignVCenter

                MochaDS.ButtonGroupItem {
                    iconName: "grid"
                    text: "Grade"
                    onClicked: root.viewMode = "grid"
                }

                MochaDS.ButtonGroupItem {
                    iconName: "list"
                    text: "Lista"
                    onClicked: root.viewMode = "list"
                }
            }

            MochaDS.Button {
                text: "Recarregar"
                icon: "rotate-cw"
                variant: "ghost"
                loading: root.loading
                disabled: root.loading
                onClicked: root.refresh()
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Content Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loading state
            Item {
                anchors.fill: parent
                visible: root.loading

                MochaDS.CozySpinner {
                    size: 48
                    anchors.centerIn: parent
                }
            }

            // Empty state
            Item {
                anchors.fill: parent
                visible: !root.loading && root.groupApps.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    MochaDS.LucideIcon {
                        name: "package-open"
                        size: 48
                        color: MochaDS.Theme.colors.overlay1
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Nenhum pacote encontrado"
                        font.family: MochaDS.Theme.typography.familyBold
                        font.pixelSize: MochaDS.Theme.typography.sizeLg
                        color: MochaDS.Theme.colors.text
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // List View (Default)
            MochaDS.CozyList {
                id: groupListView
                anchors.fill: parent
                visible: !root.loading && root.viewMode === "list" && root.groupApps.length > 0
                model: root.groupApps
                spacing: MochaDS.Theme.spacing.xs

                rowContent: Component {
                    RowLayout {
                        anchors.fill: parent
                        spacing: MochaDS.Theme.spacing.md

                        AppIcon {
                            width: 32
                            height: 32
                            iconSource: modelData.icon || ""
                            packageName: modelData.name || ""
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            RowLayout {
                                spacing: MochaDS.Theme.spacing.sm

                                Text {
                                    text: modelData.title
                                    font.family: MochaDS.Theme.typography.familyBold
                                    font.pixelSize: MochaDS.Theme.typography.sizeMd
                                    color: MochaDS.Theme.colors.text
                                }

                                MochaDS.Badge {
                                    text: modelData.type.toUpperCase()
                                    variant: "primary"
                                }

                                MochaDS.Badge {
                                    text: "Instalado"
                                    variant: "success"
                                    visible: modelData.installed
                                }
                            }

                            Text {
                                text: modelData.desc || "Sem descrição disponível."
                                font.family: MochaDS.Theme.typography.family
                                font.pixelSize: MochaDS.Theme.typography.sizeSm
                                color: MochaDS.Theme.colors.subtext0
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "v" + modelData.version
                                font.family: MochaDS.Theme.typography.family
                                font.pixelSize: MochaDS.Theme.typography.sizeSm
                                color: MochaDS.Theme.colors.subtext1
                            }

                            MochaDS.Button {
                                text: modelData.installed ? "Mais Detalhes" : "Instalar"
                                variant: modelData.installed ? "outline" : "primary"
                                size: "sm"
                                onClicked: {
                                    if (modelData.installed) {
                                        window.selectedApp = modelData;
                                        window.appDetailModal.open = true;
                                    } else {
                                        window.consoleLog = "";
                                        window.currentAction = "Instalação de " + modelData.title;
                                        window.terminalModal.open = true;
                                        backend.installPackage(modelData.type, modelData.name);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Grid View
            Flickable {
                id: groupGridView
                anchors.fill: parent
                contentHeight: groupGrid.height + MochaDS.Theme.spacing.xxl
                clip: true
                visible: !root.loading && root.viewMode === "grid" && root.groupApps.length > 0

                MochaDS.CozyGrid {
                    id: groupGrid
                    width: parent.width - MochaDS.Theme.spacing.md
                    mobile: false
                    model: root.groupApps

                    delegate: Component {
                        MochaDS.CozyGridCol {
                            lg: 4
                            md: 6
                            sm: 12

                            MochaDS.Card {
                                width: parent.width
                                title: modelData.title
                                subtitle: "Versão: " + modelData.version
                                variant: "outline"

                                header: [
                                    Item {
                                        width: parent.width
                                        height: 54

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: MochaDS.Theme.spacing.md
                                            anchors.rightMargin: MochaDS.Theme.spacing.md

                                            AppIcon {
                                                width: 32
                                                height: 32
                                                iconSource: modelData.icon || ""
                                                packageName: modelData.name || ""
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Item { Layout.fillWidth: true }

                                            MochaDS.Badge {
                                                text: modelData.installed ? "INSTALADO" : "PACMAN"
                                                variant: modelData.installed ? "success" : "primary"
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }
                                    }
                                ]

                                content: [
                                    ColumnLayout {
                                        width: parent.width
                                        height: implicitHeight
                                        spacing: 8

                                        Text {
                                            text: modelData.desc || "Sem descrição disponível."
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            font.family: MochaDS.Theme.typography.family
                                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                                            color: MochaDS.Theme.colors.subtext0
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Item { Layout.fillWidth: true }

                                            MochaDS.Button {
                                                text: "Mais Detalhes"
                                                variant: "outline"
                                                size: "sm"
                                                onClicked: {
                                                    window.selectedApp = modelData;
                                                    window.appDetailModal.open = true;
                                                }
                                            }

                                            MochaDS.Button {
                                                text: "Instalar"
                                                variant: "primary"
                                                size: "sm"
                                                visible: !modelData.installed
                                                onClicked: {
                                                    window.consoleLog = "";
                                                    window.currentAction = "Instalação de " + modelData.title;
                                                    window.terminalModal.open = true;
                                                    backend.installPackage(modelData.type, modelData.name);
                                                }
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }

                MochaDS.ScrollBar {
                    flickable: groupGridView
                    orientation: "vertical"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
            }
        }
    }
}
