import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15

MochaDS.Card {
    id: cardRoot

    property var appData: null

    signal detailsClicked()

    title: appData ? appData.title : ""
    subtitle: appData ? appData.version : ""
    variant: "default"

    Column {
        width: parent.width
        spacing: 8

        Row {
            width: parent.width
            spacing: 8

            AppIcon {
                width: 48
                height: 48
                iconSource: (cardRoot.appData && cardRoot.appData.icon) ? cardRoot.appData.icon : ""
                packageName: (cardRoot.appData && cardRoot.appData.name) ? cardRoot.appData.name : ""
            }

            Column {
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    spacing: 4

                    MochaDS.Badge {
                        text: (cardRoot.appData && cardRoot.appData.type) ? cardRoot.appData.type.toUpperCase() : ""
                        variant: (cardRoot.appData && cardRoot.appData.type === "flatpak") ? "secondary" : ((cardRoot.appData && cardRoot.appData.type === "aur") ? "warning" : "primary")
                    }

                    MochaDS.Badge {
                        text: "Instalado"
                        variant: "success"
                        visible: cardRoot.appData ? cardRoot.appData.installed : false
                    }

                }

            }

        }

        Text {
            text: cardRoot.appData ? cardRoot.appData.desc : ""
            width: parent.width
            elide: Text.ElideRight
            maximumLineCount: 2
            font.family: MochaDS.Theme.typography.family
            font.pixelSize: MochaDS.Theme.typography.sizeSm
            color: MochaDS.Theme.colors.subtext1
            wrapMode: Text.Wrap
        }

        Item {
            width: 1
            height: 8
        }

        MochaDS.Button {
            text: "Mais Detalhes"
            variant: "outline"
            size: "sm"
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                cardRoot.detailsClicked();
            }
        }

    }

}
