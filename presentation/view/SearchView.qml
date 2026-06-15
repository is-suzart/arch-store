import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../componentes"

Item {
    id: root

    property string query: window.searchQuery
    property var results: window.searchResults
    property bool loading: window.searchLoading

    onQueryChanged: {
        if (searchInputField.text !== query) {
            searchInputField.text = query;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // Search input layout
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MochaDS.TextField {
                id: searchInputField

                placeholder: "Pesquise por nome, descrição ou categoria..."
                text: root.query
                iconLeft: "search"
                Layout.fillWidth: true
                onTextChanged: {
                    if (activeFocus) {
                        window.searchQuery = text;
                        window.triggerSearch(text, false);
                    }
                }
                onAccepted: {
                    window.searchQuery = text;
                    window.triggerSearch(text, true);
                }
            }

            MochaDS.Button {
                text: "Buscar"
                variant: "primary"
                onClicked: {
                    window.searchQuery = searchInputField.text;
                    window.triggerSearch(window.searchQuery, true);
                }
            }

        }

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

        // Search Results Grid
        Flickable {
            id: searchFlickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: resultsFlow.height
            clip: true
            visible: !root.loading

            Flow {
                id: resultsFlow

                width: searchFlickable.width
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

            ScrollBar.vertical: ScrollBar {
            }

        }

    }
}
