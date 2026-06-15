import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

MochaDS.Card {
    id: cardRoot

    property var appData: null

    signal uninstallClicked()

    title: appData ? appData.title : ""
    subtitle: appData ? "Versão: " + appData.version : ""
    variant: "default"
    header: [
        Item {
            width: cardRoot.width
            height: 64 // 40px (altura do ícone) + 16px (8px de padding superior e inferior)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: MochaDS.Theme.spacing.lg
                anchors.rightMargin: MochaDS.Theme.spacing.lg

                AppIcon {
                    width: 40
                    height: 40
                    Layout.alignment: Qt.AlignVCenter
                    iconSource: (cardRoot.appData && cardRoot.appData.icon) ? cardRoot.appData.icon : ""
                    packageName: (cardRoot.appData && cardRoot.appData.name) ? cardRoot.appData.name : ""
                }

                Item {
                    Layout.fillWidth: true
                }

                MochaDS.Badge {
                    text: (cardRoot.appData && cardRoot.appData.type) ? cardRoot.appData.type.toUpperCase() : ""
                    variant: (cardRoot.appData && cardRoot.appData.type === "flatpak") ? "secondary" : "primary"
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
                text: cardRoot.appData ? cardRoot.appData.name : ""
                width: parent.width
                font.family: MochaDS.Theme.typography.family
                font.pixelSize: MochaDS.Theme.typography.sizeH1
                color: MochaDS.Theme.colors.text
                wrapMode: Text.Wrap
            }

            Text {
                text: cardRoot.appData ? cardRoot.appData.desc : ""
                width: parent.width
                elide: Text.ElideRight
                maximumLineCount: 1
                font.family: MochaDS.Theme.typography.family
                font.pixelSize: MochaDS.Theme.typography.sizeSm
                color: MochaDS.Theme.colors.subtext0
            }

            RowLayout {
                spacing: 8
                width: parent.width
                height: implicitHeight

                Text {
                    text: cardRoot.appData ? cardRoot.appData.version : ""
                    font.family: MochaDS.Theme.typography.family
                    font.pixelSize: MochaDS.Theme.typography.sizeSm
                    color: MochaDS.Theme.colors.subtext1
                }

                Item {
                    Layout.fillWidth: true
                }

                MochaDS.Button {
                    text: "Desinstalar"
                    variant: "danger"
                    size: "sm"
                    onClicked: {
                        cardRoot.uninstallClicked();
                    }
                }

            }

        }
    ]
}
