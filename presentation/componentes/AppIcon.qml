import QtQuick 2.15
import QtQuick.Controls 2.15
import MochaDS 1.0 as MochaDS

Item {
    id: root
    property string iconSource: ""
    property string packageName: ""

    implicitWidth: 48
    implicitHeight: 48

    // Variavel de estado local para saber o que tentar carregar
    readonly property bool isWebIcon: root.iconSource.startsWith("http")
    
    // Constrói a URL do tema de sistema apenas se não for um icone web e existir um nome valido
    readonly property string systemIconUrl: {
        if (isWebIcon) return "";
        if (root.iconSource !== "") return "image://theme/" + root.iconSource;
        if (root.packageName !== "") return "image://theme/" + root.packageName;
        return "";
    }

    Rectangle {
        anchors.fill: parent
        color: MochaDS.Theme.colors.surface0
        radius: MochaDS.Theme.geometry.radiusSm
        clip: true

        // 1. Web Icon Loader
        Image {
            id: webIcon
            anchors.fill: parent
            anchors.margins: 4
            source: root.isWebIcon ? root.iconSource : ""
            fillMode: Image.PreserveAspectFit
            visible: root.isWebIcon && status === Image.Ready
            
            // Suaviza a aparição
            Behavior on opacity { NumberAnimation { duration: 150 } }
            opacity: visible ? 1 : 0
        }

        // 2. System Icon Theme Loader
        Image {
            id: systemIcon
            anchors.fill: parent
            anchors.margins: 4
            // A magica assincrona (AsyncImageProvider) cuida pra n travar a UI!
            source: root.systemIconUrl
            fillMode: Image.PreserveAspectFit
            
            // Só mostra se NÃO for web icon E a imagem foi carregada com sucesso e tem largura valida
            visible: !root.isWebIcon && status === Image.Ready && implicitWidth > 0
            asynchronous: true // Dica pro QML que a fonte é pesada
            
            Behavior on opacity { NumberAnimation { duration: 150 } }
            opacity: visible ? 1 : 0
        }

        // 3. Fallback Vector Icon (Mostra enquanto carrega ou se der erro)
        MochaDS.LucideIcon {
            anchors.centerIn: parent
            name: "package"
            size: root.width * 0.5
            color: MochaDS.Theme.colors.subtext0
            // Fica visivel se nenhum dos dois anteriores estiver pronto
            visible: (!webIcon.visible && !systemIcon.visible)
        }
    }
}
