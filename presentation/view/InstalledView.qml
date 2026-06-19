import "../componentes"
import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    // View mode: "grid" or "list"
    property string viewMode: "grid"
    property bool listLoading: false

    Timer {
        id: refreshTimer

        interval: 150 // Tiny delay to allow loader visual transition
        repeat: false
        onTriggered: {
            window.refreshInstalledList();
            root.listLoading = false;
        }
    }

    onVisibleChanged: {
        if (visible) {
            listLoading = true;
            refreshTimer.start();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            spacing: MochaDS.Theme.spacing.md

            Text {
                text: qsTr("Aplicativos Instalados")
                font.family: MochaDS.Theme.typography.familyBold
                font.pixelSize: MochaDS.Theme.typography.sizeH2
                color: MochaDS.Theme.colors.text
                Layout.fillWidth: true
            }

            Row {
                Layout.alignment: Qt.AlignVCenter

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
                text: qsTr("Atualizar Lista")
                icon: "rotate-cw"
                variant: "ghost"
                loading: root.listLoading
                disabled: root.listLoading
                onClicked: {
                    root.listLoading = true;
                    refreshTimer.start();
                }
                Layout.alignment: Qt.AlignVCenter
            }

        }

        // Main content area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Grid View container (Flickable + CozyGrid)
            Flickable {
                id: installedGridView

                anchors.fill: parent
                contentHeight: installedGrid.height + MochaDS.Theme.spacing.xxl
                contentWidth: width
                clip: true
                visible: root.viewMode === "grid" && !root.listLoading

                MochaDS.CozyGrid {
                    id: installedGrid
                    width: parent.width - MochaDS.Theme.spacing.md
                    mobile: false
                    model: window.installedApps

                    delegate: Component {
                        MochaDS.CozyGridCol {
                            lg: 4
                            md: 6
                            sm: 12

                            InstalledAppCard {
                                width: parent.width
                                appData: modelData
                                onUninstallClicked: {
                                    window.triggerUninstall(modelData.type, modelData.name);
                                }
                            }

                        }

                    }

                }

                MochaDS.ScrollBar {
                    flickable: installedGridView
                    orientation: "vertical"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }

            }

            // Spinner for Grid View Loading
            Item {
                anchors.fill: parent
                visible: root.viewMode === "grid" && root.listLoading

                MochaDS.CozySpinner {
                    size: 48
                    anchors.centerIn: parent
                }

            }

            // List View container (CozyList)
            MochaDS.CozyList {
                id: installedListView

                anchors.fill: parent
                visible: root.viewMode === "list"
                model: window.installedApps
                spacing: MochaDS.Theme.spacing.xs
                isLoading: root.listLoading

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
                                    variant: modelData.type === "flatpak" ? "secondary" : "primary"
                                }

                            }

                            Text {
                                text: modelData.desc
                                font.family: MochaDS.Theme.typography.family
                                font.pixelSize: MochaDS.Theme.typography.sizeSm
                                color: MochaDS.Theme.colors.subtext0
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                        }

                        Text {
                            text: "v" + modelData.version
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                            color: MochaDS.Theme.colors.subtext1
                            Layout.alignment: Qt.AlignVCenter
                        }

                        MochaDS.Button {
                            text: qsTr("Desinstalar")
                            variant: "danger"
                            size: "sm"
                            onClicked: {
                                window.triggerUninstall(modelData.type, modelData.name);
                            }
                            Layout.alignment: Qt.AlignVCenter
                        }

                    }

                }

            }

        }

    }

}
