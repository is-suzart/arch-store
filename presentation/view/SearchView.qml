import "../componentes"
import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property string query: window.searchQuery
    property var results: window.searchResults
    property bool loading: window.searchLoading
    property var suggestions: []

    onVisibleChanged: {
        if (visible && typeof backend !== "undefined" && backend) {
            suggestions = backend.getFeaturedPackages();
        }
    }

    Component.onCompleted: {
        if (typeof backend !== "undefined" && backend) {
            suggestions = backend.getFeaturedPackages();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // Search Loading
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            visible: root.loading

            MochaDS.CozySpinner {
                size: 48
                anchors.centerIn: parent
            }
        }

        // Suggestion Grid (when query is empty or too short)
        Flickable {
            id: suggestionFlickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: suggestionContent.height + 40
            clip: true
            visible: !root.loading && root.query.trim().length < 3

            ColumnLayout {
                id: suggestionContent
                width: suggestionFlickable.width - 20
                spacing: 24

                // Welcome / Tip card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    color: MochaDS.Theme.colors.mantle
                    radius: MochaDS.Theme.geometry.radiusMd
                    border.color: MochaDS.Theme.colors.surface0
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 20

                        MochaDS.LucideIcon {
                            name: "search"
                            size: 48
                            color: MochaDS.Theme.colors.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            spacing: 6
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: qsTr("Pesquise aplicativos no Arch Linux")
                                font.family: MochaDS.Theme.typography.familyBold
                                font.pixelSize: MochaDS.Theme.typography.sizeLg
                                color: MochaDS.Theme.colors.text
                            }

                            Text {
                                text: qsTr("Digite no campo de busca para encontrar pacotes locais (pacman), AUR ou Flatpaks. Digite pelo menos 3 caracteres para iniciar a busca.")
                                font.family: MochaDS.Theme.typography.family
                                font.pixelSize: MochaDS.Theme.typography.sizeSm
                                color: MochaDS.Theme.colors.subtext0
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Suggestions header
                Text {
                    text: qsTr("Aplicativos Recomendados")
                    font.family: MochaDS.Theme.typography.familyBold
                    font.pixelSize: MochaDS.Theme.typography.sizeXl
                    color: MochaDS.Theme.colors.text
                    visible: root.suggestions && root.suggestions.length > 0
                }

                // Suggestions Grid
                Flow {
                    Layout.fillWidth: true
                    width: suggestionContent.width
                    spacing: MochaDS.Theme.spacing.lg
                    visible: root.suggestions && root.suggestions.length > 0

                    Repeater {
                        model: root.suggestions

                        delegate: SearchAppCard {
                            width: Math.max(280, (suggestionContent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                            appData: modelData
                            onDetailsClicked: {
                                window.selectedApp = modelData;
                                window.appDetailModal.open = true;
                            }
                        }
                    }
                }
            }

            MochaDS.ScrollBar {
                flickable: suggestionFlickable
                orientation: "vertical"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }
        }

        // Search Results Grid
        Flickable {
            id: searchFlickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: resultsFlow.height + 40
            clip: true
            visible: !root.loading && root.query.trim().length >= 3

            Flow {
                id: resultsFlow

                width: searchFlickable.width - 20
                spacing: MochaDS.Theme.spacing.lg

                Repeater {
                    model: root.results

                    delegate: SearchAppCard {
                        width: Math.max(280, (parent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                        appData: modelData
                        onDetailsClicked: {
                            window.selectedApp = modelData;
                            window.appDetailModal.open = true;
                        }
                    }
                }
            }

            MochaDS.ScrollBar {
                flickable: searchFlickable
                orientation: "vertical"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }
        }
    }
}
