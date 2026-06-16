import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

MochaDS.Card {
    id: cardRoot

    property var appData: null

    signal uninstallClicked()

    MouseArea {
        id: cardMouseArea
        anchors.fill: parent
        onClicked: {
            if (cardRoot.appData) {
                window.toggleBatchUninstallApp(cardRoot.appData);
            }
        }
        Component.onCompleted: {
            cardMouseArea.parent = cardRoot;
        }
    }

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

                Item {
                    width: 40
                    height: 40
                    Layout.alignment: Qt.AlignVCenter

                    AppIcon {
                        anchors.fill: parent
                        iconSource: (cardRoot.appData && cardRoot.appData.icon) ? cardRoot.appData.icon : ""
                        packageName: (cardRoot.appData && cardRoot.appData.name) ? cardRoot.appData.name : ""
                    }

                    // Glassmorphic selection circle indicator (danger themed for uninstallation)
                    Rectangle {
                        id: selectionIndicator
                        width: 16
                        height: 16
                        radius: 8
                        color: isSelected ? MochaDS.Theme.colors.danger : MochaDS.Theme.colors.surface0
                        border.color: isSelected ? "transparent" : MochaDS.Theme.colors.overlay0
                        border.width: 1.5
                        // Positioned overlapping top-left of the icon
                        x: -5
                        y: -5

                        // Inner dot for selected state
                        Rectangle {
                            anchors.centerIn: parent
                            width: 6
                            height: 6
                            radius: 3
                            color: MochaDS.Theme.colors.base
                            visible: parent.isSelected
                        }

                        readonly property bool isSelected: (cardRoot.appData && cardRoot.appData.name) ? window.isBatchUninstallAppSelected(cardRoot.appData.name) : false

                        MouseArea {
                            anchors.fill: parent
                            // Extra click margins for better UX
                            anchors.margins: -8
                            onClicked: {
                                if (cardRoot.appData) {
                                    window.toggleBatchUninstallApp(cardRoot.appData);
                                }
                            }
                        }
                    }
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
                text: cardRoot.appData ? (cardRoot.appData.title || cardRoot.appData.name) : ""
                width: parent.width
                font.family: MochaDS.Theme.typography.family
                font.pixelSize: MochaDS.Theme.typography.sizeXl
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

            Item {
                width: parent.width
                height: footer.height + 24

                RowLayout {
                    id: footer

                    anchors.verticalCenter: parent.verticalCenter
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

        }
    ]
}
