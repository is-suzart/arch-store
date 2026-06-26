import "../componentes"
import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Flickable {
    id: root

    property var heroApps: []
    property bool loading: false

    function refresh() {
        loading = true;
        refreshTimer.start();
    }

    Timer {
        id: refreshTimer
        interval: 150
        repeat: false
        onTriggered: {
            gamingGrid.gamingApps = JSON.parse(backend.getGamingPackages());
            heroApps = JSON.parse(backend.getGamingHeroApps());
            loading = false;
        }
    }

    onVisibleChanged: {
        if (visible) {
            refresh();
        }
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
        visible: !root.loading


        // ── Hero Carousel ─────────────────────────────────────────────────────
        HeroCarousel {
            id: heroCarousel
            width: parent.width
            height: 280
            model: root.heroApps
            visible: root.heroApps && root.heroApps.length > 0

            onInstallClicked: function(appData) {
                if (appData.installed) return;
                window.consoleLog = "";
                window.currentAction = qsTr("Instalação");
                window.terminalModal.open = true;
                backend.installPackage(appData.type, appData.name);
            }

            onDetailsClicked: function(appData) {
                window.selectedApp = appData;
                window.appDetailModal.open = true;
            }
        }

        RowLayout {
            width: parent.width
            height: implicitHeight
            spacing: MochaDS.Theme.spacing.md

            Text {
                text: qsTr("Jogos e Ferramentas")
                font.family: MochaDS.Theme.typography.familyBold
                font.pixelSize: MochaDS.Theme.typography.sizeH2
                color: MochaDS.Theme.colors.text
                Layout.fillWidth: true
            }

            MochaDS.Button {
                text: qsTr("Atualizar Lista")
                icon: "rotate-cw"
                variant: "ghost"
                loading: root.loading
                disabled: root.loading
                onClicked: {
                    root.refresh();
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


    MochaDS.CozySpinner {
        size: 48
        anchors.centerIn: parent
        visible: root.loading
    }

    MochaDS.ScrollBar {
        flickable: root
        orientation: "vertical"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }

}
