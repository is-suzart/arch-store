import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../componentes"

Flickable {
    id: installedView

    contentHeight: installedContent.height + MochaDS.Theme.spacing.xxl
    clip: true

    Column {
        id: installedContent

        width: parent.width
        spacing: 20

        RowLayout {
            width: parent.width
            height: implicitHeight

            Text {
                text: "Aplicativos Instalados"
                font.family: MochaDS.Theme.typography.familyBold
                font.pixelSize: MochaDS.Theme.typography.sizeH1
                color: MochaDS.Theme.colors.text
                Layout.fillWidth: true
            }

            MochaDS.Button {
                text: "Atualizar Lista"
                icon: "rotate-cw"
                variant: "ghost"
                onClicked: window.refreshInstalledList()
            }

        }

        Flow {
            id: installedFlow

            width: parent.width
            spacing: MochaDS.Theme.spacing.lg

            Repeater {
                model: window.installedApps

                delegate: InstalledAppCard {
                    width: Math.max(280, (parent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                    appData: modelData

                    onUninstallClicked: {
                        window.triggerUninstall(modelData.type, modelData.name);
                    }
                }

            }

        }

    }

    ScrollBar.vertical: ScrollBar {
    }
}
