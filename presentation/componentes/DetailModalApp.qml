import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

MochaDS.Modal {
    id: root

    property var appData: null

    // Hero image URL — fetched from AppStream when appData changes
    property string heroImageUrl: ""

    onAppDataChanged: {
        heroImageUrl = "";
        if (appData && appData.name && appData.type) {
            heroImageUrl = backend.getAppHeroImage(appData.name, appData.type);
        }
    }

    title: appData ? appData.title : ""
    size: "md"

    Column {
        width: parent.width
        spacing: 0

        // ── Hero image (shown only when available) ────────────────────────────
        Item {
            width: parent.width
            height: heroImg.status === Image.Ready ? 180 : 0
            clip: true
            visible: height > 0

            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            Image {
                id: heroImg
                anchors.fill: parent
                source: root.heroImageUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: status === Image.Ready ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 350 } }
            }

            // Gradient overlay — fades bottom into modal background
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.7; color: Qt.rgba(0, 0, 0, 0.25) }
                    GradientStop { position: 1.0; color: MochaDS.Theme.colors.surface0 }
                }
            }
        }

        // ── Content padding wrapper ───────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 16
            topPadding: heroImg.status === Image.Ready ? 12 : 0
            leftPadding: 0
            rightPadding: 0
            bottomPadding: 4

            // App icon + name + version
            Row {
                spacing: 16
                width: parent.width

                AppIcon {
                    width: 64
                    height: 64
                    iconSource: root.appData ? root.appData.icon : ""
                    packageName: root.appData ? root.appData.name : ""
                }

                Column {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: root.appData ? root.appData.title : ""
                        font.family: MochaDS.Theme.typography.familyBold
                        font.pixelSize: MochaDS.Theme.typography.sizeXl
                        color: MochaDS.Theme.colors.text
                    }

                    Text {
                        text: root.appData ? "Versão: " + root.appData.version : ""
                        font.family: MochaDS.Theme.typography.family
                        font.pixelSize: MochaDS.Theme.typography.sizeSm
                        color: MochaDS.Theme.colors.subtext0
                    }
                }

            }

            // Description
            Text {
                text: root.appData ? root.appData.desc : ""
                width: parent.width
                wrapMode: Text.Wrap
                font.family: MochaDS.Theme.typography.family
                font.pixelSize: MochaDS.Theme.typography.sizeMd
                color: MochaDS.Theme.colors.text
            }

            // Type badge
            Row {
                spacing: 8

                MochaDS.Badge {
                    text: root.appData ? "TIPO: " + root.appData.type.toUpperCase() : ""
                    variant: root.appData && root.appData.type === "flatpak" ? "secondary" : "primary"
                }

            }

            // Action buttons
            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                MochaDS.Button {
                    text: root.appData && root.appData.installed ? "Desinstalar" : "Instalar"
                    variant: root.appData && root.appData.installed ? "danger" : "success"
                    onClicked: {
                        root.open = false;
                        window.consoleLog = "";
                        window.currentAction = root.appData.installed ? "Desinstalação" : "Instalação";
                        window.terminalModal.open = true;
                        if (root.appData.installed)
                            backend.uninstallPackage(root.appData.type, root.appData.name);
                        else
                            backend.installPackage(root.appData.type, root.appData.name);
                    }
                }

                MochaDS.Button {
                    text: "Fechar"
                    variant: "outline"
                    onClicked: root.open = false
                }

            }

        }

    }
}
