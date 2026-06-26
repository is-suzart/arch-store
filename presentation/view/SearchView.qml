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
            suggestions = JSON.parse(backend.getFeaturedPackages());
        }
    }

    Component.onCompleted: {
        if (typeof backend !== "undefined" && backend) {
            suggestions = JSON.parse(backend.getFeaturedPackages());
        }
    }

    // Search Loading Spinner
    MochaDS.CozySpinner {
        size: 48
        anchors.centerIn: parent
        visible: root.loading
    }

    // Main content area (when not loading)
    Flickable {
        id: mainFlickable

        anchors.fill: parent
        anchors.rightMargin: 10 // Space for scrollbar
        contentHeight: mainContent.height + 40
        clip: true
        visible: !root.loading

        Column {
            id: mainContent
            width: parent.width - 20
            spacing: 24

            // Suggestions Content (when query < 3)
            Column {
                width: parent.width
                spacing: 24
                visible: root.query.trim().length < 3

                // Welcome / Tip card
                Rectangle {
                    width: parent.width
                    height: 140
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
                MochaDS.CozyGrid {
                    id: suggestionGrid
                    width: parent.width
                    mobile: false
                    model: root.suggestions
                    visible: root.suggestions && root.suggestions.length > 0

                    delegate: Component {
                        MochaDS.CozyGridCol {
                            lg: 4
                            md: 6
                            sm: 12

                            SearchAppCard {
                                width: parent.width
                                appData: modelData
                                onDetailsClicked: {
                                    window.selectedApp = modelData;
                                    window.appDetailModal.open = true;
                                }
                            }
                        }
                    }
                }
            }

            // Search Results Content (when query >= 3)
            Column {
                width: parent.width
                spacing: 24
                visible: root.query.trim().length >= 3

                // Results Header
                Text {
                    text: qsTr("Resultados da Busca")
                    font.family: MochaDS.Theme.typography.familyBold
                    font.pixelSize: MochaDS.Theme.typography.sizeXl
                    color: MochaDS.Theme.colors.text
                    visible: root.results && root.results.length > 0
                }

                // Results Grid
                MochaDS.CozyGrid {
                    id: resultsGrid
                    width: parent.width
                    mobile: false
                    model: root.results
                    visible: root.results && root.results.length > 0

                    delegate: Component {
                        MochaDS.CozyGridCol {
                            lg: 4
                            md: 6
                            sm: 12

                            SearchAppCard {
                                width: parent.width
                                appData: modelData
                                onDetailsClicked: {
                                    window.selectedApp = modelData;
                                    window.appDetailModal.open = true;
                                }
                            }
                        }
                    }
                }

                // Empty state for search results
                Text {
                    text: qsTr("Nenhum aplicativo encontrado")
                    font.family: MochaDS.Theme.typography.family
                    font.pixelSize: MochaDS.Theme.typography.sizeLg
                    color: MochaDS.Theme.colors.subtext0
                    visible: !root.results || root.results.length === 0
                }
            }
        }

        MochaDS.ScrollBar {
            flickable: mainFlickable
            orientation: "vertical"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        }
    }
}
