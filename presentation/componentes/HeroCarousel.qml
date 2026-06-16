import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../componentes"

Item {
    id: root

    // List of hero app objects (from backend.getHeroApps())
    property var model: []

    // Signals
    signal installClicked(var appData)
    signal detailsClicked(var appData)

    // ── Auto-advance timer ────────────────────────────────────────────────────
    property int currentIndex: 0

    Timer {
        id: autoTimer
        interval: 5500
        repeat: true
        running: root.model.length > 1
        onTriggered: root.currentIndex = (root.currentIndex + 1) % root.model.length
    }

    // ── Slide stack ──────────────────────────────────────────────────────────
    Item {
        id: slideArea
        anchors.fill: parent
        clip: true

        Repeater {
            id: slideRepeater
            model: root.model

            delegate: Item {
                id: slide
                anchors.fill: parent
                opacity: index === root.currentIndex ? 1.0 : 0.0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
                }

                // ── Hero background image ─────────────────────────────────────
                Image {
                    id: heroImg
                    anchors.fill: parent
                    source: modelData.hero_image || ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true

                    // dim while loading
                    opacity: status === Image.Ready ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 400 } }
                }

                // Loading shimmer while image loads
                Rectangle {
                    anchors.fill: parent
                    visible: heroImg.status !== Image.Ready
                    color: modelData.brand_color_dark || MochaDS.Theme.colors.mantle
                    opacity: 0.9
                }

                // ── Gradient overlay ──────────────────────────────────────────
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.35) }
                        GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.82) }
                    }
                }

                // ── Accent left bar (branding color) ─────────────────────────
                Rectangle {
                    width: 4
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    color: modelData.brand_color_light || MochaDS.Theme.colors.primary
                    opacity: 0.85
                    radius: 2
                }

                // ── Content ───────────────────────────────────────────────────
                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: MochaDS.Theme.spacing.xl
                        rightMargin: MochaDS.Theme.spacing.xl
                        bottomMargin: MochaDS.Theme.spacing.xl
                    }
                    spacing: MochaDS.Theme.spacing.lg

                    // App icon
                    AppIcon {
                        width: 56
                        height: 56
                        iconSource: modelData.icon || ""
                        packageName: modelData.name || ""
                        Layout.alignment: Qt.AlignBottom
                    }

                    // Text block
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignBottom
                        spacing: MochaDS.Theme.spacing.xs

                        // Type badge
                        MochaDS.Badge {
                            text: (modelData.type || "").toUpperCase()
                            variant: modelData.type === "flatpak" ? "secondary" : "primary"
                        }

                        Text {
                            text: modelData.title || ""
                            font.family: MochaDS.Theme.typography.familyBold
                            font.pixelSize: MochaDS.Theme.typography.sizeH2
                            color: "#ffffff"
                            style: Text.Normal
                        }

                        Text {
                            text: modelData.desc || ""
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: "#d0d0d0"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Action buttons
                    ColumnLayout {
                        Layout.alignment: Qt.AlignBottom
                        spacing: MochaDS.Theme.spacing.sm

                        MochaDS.Button {
                            text: modelData.installed ? "Instalado" : "Instalar"
                            variant: modelData.installed ? "tonal" : "success"
                            icon: modelData.installed ? "check" : "download"
                            disabled: modelData.installed
                            onClicked: root.installClicked(modelData)
                            Layout.alignment: Qt.AlignRight
                        }

                        MochaDS.Button {
                            text: "Detalhes"
                            variant: "outline"
                            icon: "info"
                            onClicked: root.detailsClicked(modelData)
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
            }
        }

        // ── Prev button ───────────────────────────────────────────────────────
        Item {
            id: prevBtn
            width: 44
            height: 44
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: MochaDS.Theme.spacing.md
            visible: root.model.length > 1

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: prevHover.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(0,0,0,0.35)
                Behavior on color { ColorAnimation { duration: 180 } }

                MochaDS.LucideIcon {
                    name: "chevron-left"
                    size: 20
                    color: "#ffffff"
                    anchors.centerIn: parent
                }
            }

            MouseArea {
                id: prevHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    autoTimer.restart()
                    root.currentIndex = (root.currentIndex - 1 + root.model.length) % root.model.length
                }
            }
        }

        // ── Next button ───────────────────────────────────────────────────────
        Item {
            id: nextBtn
            width: 44
            height: 44
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: MochaDS.Theme.spacing.md
            visible: root.model.length > 1

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: nextHover.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(0,0,0,0.35)
                Behavior on color { ColorAnimation { duration: 180 } }

                MochaDS.LucideIcon {
                    name: "chevron-right"
                    size: 20
                    color: "#ffffff"
                    anchors.centerIn: parent
                }
            }

            MouseArea {
                id: nextHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    autoTimer.restart()
                    root.currentIndex = (root.currentIndex + 1) % root.model.length
                }
            }
        }

        // ── Dot indicators ────────────────────────────────────────────────────
        Row {
            spacing: 6
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: MochaDS.Theme.spacing.sm
            visible: root.model.length > 1

            Repeater {
                model: root.model.length
                delegate: Rectangle {
                    width:  index === root.currentIndex ? 18 : 6
                    height: 6
                    radius: 3
                    color: index === root.currentIndex ? "#ffffff" : Qt.rgba(1,1,1,0.35)
                    Behavior on width { NumberAnimation { duration: 250 } }
                    Behavior on color { ColorAnimation { duration: 250 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            autoTimer.restart()
                            root.currentIndex = index
                        }
                    }
                }
            }
        }
    }
}
