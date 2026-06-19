import "../componentes"
import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property var allUpdates: []
    property var pacmanUpdates: []
    property var flatpakUpdates: []
    property var aurUpdates: []
    property bool updatesLoading: false
    property string viewMode: "list" // "list" or "grid"

    function refresh() {
        updatesLoading = true;
        updatesTimer.start();
    }

    Timer {
        id: updatesTimer
        interval: 150
        repeat: false
        onTriggered: {
            var list = backend.getUpdatablePackages();
            allUpdates = list;
            
            var pac = [];
            var flt = [];
            var aur = [];
            for (var i = 0; i < list.length; i++) {
                if (list[i].type === "pacman") pac.push(list[i]);
                else if (list[i].type === "flatpak") flt.push(list[i]);
                else if (list[i].type === "aur") aur.push(list[i]);
            }
            pacmanUpdates = pac;
            flatpakUpdates = flt;
            aurUpdates = aur;
            updatesLoading = false;
        }
    }

    Component.onCompleted: {
        refresh();
    }

    onVisibleChanged: {
        if (visible) {
            refresh();
        }
    }

    // Active model based on tab index
    readonly property var activeModel: {
        if (updateTabs.currentIndex === 0) return pacmanUpdates;
        if (updateTabs.currentIndex === 1) return aurUpdates;
        return flatpakUpdates;
    }

    readonly property string activeCategoryName: {
        if (updateTabs.currentIndex === 0) return "pacman";
        if (updateTabs.currentIndex === 1) return "aur";
        return "flatpak";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        // Header section
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            spacing: MochaDS.Theme.spacing.md

            Text {
                text: qsTr("Atualizações do Sistema")
                font.family: MochaDS.Theme.typography.familyBold
                font.pixelSize: MochaDS.Theme.typography.sizeH2
                color: MochaDS.Theme.colors.text
                Layout.fillWidth: true
            }

            // Tab Selector (Segmented)
            MochaDS.Tabs {
                id: updateTabs
                model: [
                    qsTr("Pacman (%1)").arg(pacmanUpdates.length),
                    qsTr("AUR (%1)").arg(aurUpdates.length),
                    qsTr("Flatpak (%1)").arg(flatpakUpdates.length)
                ]
                currentIndex: 0
                variant: "segmented"
                Layout.preferredWidth: 380
                Layout.alignment: Qt.AlignVCenter
            }

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                MochaDS.ButtonGroup {
                    expand: false
                    currentIndex: root.viewMode === "grid" ? 0 : 1

                    MochaDS.ButtonGroupItem {
                        iconName: "grid"
                        text: qsTr("Grade")
                        onClicked: root.viewMode = "grid"
                    }

                    MochaDS.ButtonGroupItem {
                        iconName: "list"
                        text: qsTr("Lista")
                        onClicked: root.viewMode = "list"
                    }
                }
            }

            MochaDS.Button {
                text: qsTr("Verificar")
                icon: "rotate-cw"
                variant: "ghost"
                loading: root.updatesLoading
                disabled: root.updatesLoading
                onClicked: root.refresh()
                Layout.alignment: Qt.AlignVCenter
            }

            MochaDS.Button {
                text: qsTr("Atualizar %1").arg(activeCategoryName === "pacman" ? "Pacman" : (activeCategoryName === "aur" ? "AUR" : "Flatpak"))
                variant: "tonal"
                size: "sm"
                disabled: root.updatesLoading || activeModel.length === 0
                onClicked: {
                    window.consoleLog = "";
                    window.currentAction = qsTr("Atualização de Pacotes");
                    window.terminalModal.open = true;
                    backend.updateCategory(activeCategoryName);
                }
                Layout.alignment: Qt.AlignVCenter
            }

            MochaDS.Button {
                text: qsTr("Atualizar Tudo")
                variant: "success"
                size: "sm"
                disabled: root.updatesLoading || allUpdates.length === 0
                onClicked: {
                    window.consoleLog = "";
                    window.currentAction = qsTr("Atualização Completa do Sistema");
                    window.terminalModal.open = true;
                    backend.updateCategory("all");
                }
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Main content area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loading state
            Item {
                anchors.fill: parent
                visible: root.updatesLoading

                MochaDS.CozySpinner {
                    size: 48
                    anchors.centerIn: parent
                }
            }

            // Empty state
            Item {
                anchors.fill: parent
                visible: !root.updatesLoading && activeModel.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    MochaDS.LucideIcon {
                        name: "check-circle-2"
                        size: 48
                        color: MochaDS.Theme.colors.green
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: qsTr("Tudo atualizado!")
                        font.family: MochaDS.Theme.typography.familyBold
                        font.pixelSize: MochaDS.Theme.typography.sizeLg
                        color: MochaDS.Theme.colors.text
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: qsTr("Nenhuma atualização disponível para esta categoria.")
                        font.family: MochaDS.Theme.typography.family
                        font.pixelSize: MochaDS.Theme.typography.sizeSm
                        color: MochaDS.Theme.colors.subtext0
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // List View
            MochaDS.CozyList {
                id: updatesListView
                anchors.fill: parent
                visible: !root.updatesLoading && root.viewMode === "list" && activeModel.length > 0
                model: root.activeModel
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
                                    variant: modelData.type === "flatpak" ? "secondary" : (modelData.type === "aur" ? "warning" : "primary")
                                }
                            }

                            Text {
                                text: modelData.desc || qsTr("Sem descrição disponível.")
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
                                text: "v" + modelData.installedVersion
                                font.family: MochaDS.Theme.typography.family
                                font.pixelSize: MochaDS.Theme.typography.sizeSm
                                color: MochaDS.Theme.colors.subtext1
                            }

                            MochaDS.LucideIcon {
                                name: "arrow-right"
                                size: 14
                                color: MochaDS.Theme.colors.subtext1
                            }

                            Text {
                                text: "v" + modelData.version
                                font.family: MochaDS.Theme.typography.familyBold
                                font.pixelSize: MochaDS.Theme.typography.sizeSm
                                color: MochaDS.Theme.colors.green
                            }
                        }

                        MochaDS.Button {
                            text: qsTr("Atualizar")
                            variant: "primary"
                            size: "sm"
                            onClicked: {
                                window.consoleLog = "";
                                window.currentAction = qsTr("Atualização de %1").arg(modelData.title);
                                window.terminalModal.open = true;
                                backend.installPackage(modelData.type, modelData.name);
                            }
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }

            // Grid View (Card View)
            Flickable {
                id: updatesGridView
                anchors.fill: parent
                contentHeight: updatesGrid.height + MochaDS.Theme.spacing.xxl
                clip: true
                visible: !root.updatesLoading && root.viewMode === "grid" && activeModel.length > 0

                MochaDS.CozyGrid {
                    id: updatesGrid
                    width: parent.width - MochaDS.Theme.spacing.md
                    mobile: false
                    model: root.activeModel

                    delegate: Component {
                        MochaDS.CozyGridCol {
                            lg: 4
                            md: 6
                            sm: 12

                            MochaDS.Card {
                                width: parent.width
                                title: modelData.title
                                subtitle: qsTr("Instalado: v") + modelData.installedVersion
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
                                                text: modelData.type.toUpperCase()
                                                variant: modelData.type === "flatpak" ? "secondary" : (modelData.type === "aur" ? "warning" : "primary")
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }
                                    }
                                ]

                                content: [
                                    Column {
                                        width: parent.width
                                        spacing: 8

                                        Text {
                                            text: modelData.desc || qsTr("Sem descrição disponível.")
                                            width: parent.width
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                            font.family: MochaDS.Theme.typography.family
                                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                                            color: MochaDS.Theme.colors.subtext0
                                        }

                                        RowLayout {
                                            width: parent.width
                                            height: implicitHeight
                                            spacing: 6

                                            Text {
                                                text: qsTr("Nova versão: ")
                                                font.family: MochaDS.Theme.typography.family
                                                font.pixelSize: MochaDS.Theme.typography.sizeSm
                                                color: MochaDS.Theme.colors.subtext1
                                            }

                                            Text {
                                                text: "v" + modelData.version
                                                font.family: MochaDS.Theme.typography.familyBold
                                                font.pixelSize: MochaDS.Theme.typography.sizeSm
                                                color: MochaDS.Theme.colors.green
                                                Layout.fillWidth: true
                                            }

                                            MochaDS.Button {
                                                text: qsTr("Atualizar")
                                                variant: "primary"
                                                size: "sm"
                                                onClicked: {
                                                    window.consoleLog = "";
                                                    window.currentAction = qsTr("Atualização de %1").arg(modelData.title);
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
                    flickable: updatesGridView
                    orientation: "vertical"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
            }
        }
    }
}
