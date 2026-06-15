import QtQuick 2.15
import QtQuick.Controls 2.15
import MochaDS 1.0 as MochaDS

Item {
    id: root
    property string iconSource: ""  // Can be web URL, system icon name, or empty
    property string packageName: "" // Fallback name

    implicitWidth: 48
    implicitHeight: 48

    Rectangle {
        anchors.fill: parent
        color: MochaDS.Theme.colors.surface0
        radius: MochaDS.Theme.geometry.radiusSm
        clip: true

        // 1. Web Icon Loader (Flatpak / Flathub)
        Image {
            id: webIcon
            anchors.fill: parent
            anchors.margins: 4
            source: (root.iconSource && root.iconSource.startsWith("http")) ? root.iconSource : ""
            fillMode: Image.PreserveAspectFit
            visible: status === Image.Ready
        }

        // 2. System Icon Theme Loader
        Image {
            id: systemIcon
            anchors.fill: parent
            anchors.margins: 4
            source: {
                if (webIcon.visible)
                    return "";
                if (root.iconSource && !root.iconSource.startsWith("http")) {
                    return "image://theme/" + root.iconSource;
                }
                return "image://theme/" + root.packageName;
            }
            fillMode: Image.PreserveAspectFit
            visible: !webIcon.visible && status === Image.Ready
        }

        // 3. Fallback Vector Icon
        MochaDS.LucideIcon {
            anchors.centerIn: parent
            name: "package"
            size: root.width * 0.5
            color: MochaDS.Theme.colors.subtext0
            visible: !webIcon.visible && !systemIcon.visible
        }
    }
}
