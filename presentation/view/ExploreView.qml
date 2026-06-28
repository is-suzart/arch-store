import "../componentes"
import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Flickable {
    id: exploreView

    property var heroApps: []
    property bool loading: false

    function refreshFeatured() {
        loading = true;
        refreshTimer.start();
    }

    Timer {
        id: refreshTimer
        interval: 150
        repeat: false
        onTriggered: {
            featuredGrid.featuredApps = JSON.parse(backend.getFeaturedPackages());
            popularGrid.popularApps = JSON.parse(backend.getPopularPackages());
            heroApps = JSON.parse(backend.getHeroApps());
            loading = false;
        }
    }

    contentHeight: exploreContent.height + MochaDS.Theme.spacing.xxl
    clip: true
    Component.onCompleted: {
        refreshFeatured();
    }

    Column {
        id: exploreContent

        width: parent.width
        spacing: 24
        visible: !exploreView.loading

        // ── Hero Carousel ─────────────────────────────────────────────────────
        HeroCarousel {
            id: heroCarousel
            width: parent.width
            height: 280
            model: exploreView.heroApps

            onInstallClicked: function(appData) {
                if (appData.installed) return;
                window.consoleLog = "";
                window.currentAction = "Instalação";
                window.terminalModal.open = true;
                backend.installPackage(appData.type, appData.name);
            }

            onDetailsClicked: function(appData) {
                window.selectedApp = appData;
                window.appDetailModal.open = true;
            }
        }

        // Section 3: Curated Distro Highlights (pamac-like)
        Text {
            text: qsTr("Destaques da Distribuição")
            font.family: MochaDS.Theme.typography.familyMedium
            font.pixelSize: MochaDS.Theme.typography.sizeXl
            color: MochaDS.Theme.colors.text
            leftPadding: MochaDS.Theme.spacing.xs
        }

        MochaDS.CozyGrid {
            id: featuredGrid

            property var featuredApps: []

            width: parent.width
            mobile: false
            model: featuredGrid.featuredApps

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

        // Section 4: Trending Flatpaks from Flathub API
        Text {
            text: qsTr("Tendências no Flatpak")
            font.family: MochaDS.Theme.typography.familyMedium
            font.pixelSize: MochaDS.Theme.typography.sizeXl
            color: MochaDS.Theme.colors.text
            leftPadding: MochaDS.Theme.spacing.xs
        }

        MochaDS.CozyGrid {
            id: popularGrid

            property var popularApps: []

            width: parent.width
            mobile: false
            model: popularGrid.popularApps

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
        visible: exploreView.loading
    }

    MochaDS.ScrollBar {
        flickable: exploreView
        orientation: "vertical"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }

}

