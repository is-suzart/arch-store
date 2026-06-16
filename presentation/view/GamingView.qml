import "../componentes"
import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Flickable {
    id: root

    function refresh() {
        gamingGrid.gamingApps = backend.getGamingPackages();
    }

    contentHeight: mainLayout.height + MochaDS.Theme.spacing.xxl
    clip: true
    Component.onCompleted: {
        refresh();
    }

    Column {
        id: mainLayout

        width: parent.width
        spacing: 20

        RowLayout {
            width: parent.width
            height: implicitHeight
            spacing: MochaDS.Theme.spacing.md

            Text {
                text: "Jogos e Ferramentas"
                font.family: MochaDS.Theme.typography.familyBold
                font.pixelSize: MochaDS.Theme.typography.sizeH2
                color: MochaDS.Theme.colors.text
                Layout.fillWidth: true
            }

            MochaDS.Button {
                text: "Atualizar Lista"
                icon: "rotate-cw"
                variant: "ghost"
                onClicked: {
                    window.runWithLoader("Atualizando jogos...", function() {
                        root.refresh();
                    });
                }
            }

        }

        // Section: Games CozyGrid
        MochaDS.CozyGrid {
            id: gamingGrid

            property var gamingApps: []

            width: parent.width
            mobile: false
            model: gamingGrid.gamingApps

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


    MochaDS.ScrollBar {
        flickable: root
        orientation: "vertical"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }

}
