import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window

    // Track active page: "explore", "search", "installed"
    property string currentPage: "explore"
    // Unified search logic
    property string searchQuery: ""
    property var searchResults: []
    property bool searchLoading: false
    // App Detail Modal properties
    property var selectedApp: null
    // Console log modal properties
    property string consoleLog: ""
    property string currentAction: ""
    property var installedApps: []

    function refreshInstalledList() {
        installedApps = backend.getInstalledPackages();
    }

    function triggerSearch(query, immediate) {
        var isImmediate = (immediate === true);
        if (isImmediate) {
            backend.searchImmediately(query);
        } else {
            backend.searchTextChanged(query);
        }
    }

    visible: true
    width: 1280
    height: 850
    title: "Arch Linux Store"
    color: MochaDS.Theme.colors.background
    // Initial load
    Component.onCompleted: {
        MochaDS.Theme.flavor = "macchiato";
        refreshInstalledList();
    }

    // Toast system
    MochaDS.ToastManager {
        id: toasts

        position: "top-right"
    }

    // Connect to Backend Signals
    Connections {
        target: backend
        onLogReceived: {
            consoleLog += line + "\n";
        }
        onSearchResultsReady: {
            searchResults = results;
        }
        onSearchLoadingChanged: {
            searchLoading = loading;
        }
        onActionFinished: {
            searchLoading = false;
            terminalModal.open = false;
            if (success)
                toasts.success("Operação concluída com sucesso!", "Sucesso");
            else
                toasts.error("A operação falhou. Verifique os logs.", "Erro");
            refreshInstalledList();
            if (searchQuery)
                triggerSearch(searchQuery, true);

        }
    }

    MochaDS.Shell {
        anchors.fill: parent
        sidebarWidth: 300
        headerVisible: false
        columnCount: 1
        // 1. Top Header Content
        header: [
            Rectangle {
                anchors.fill: parent
                color: MochaDS.Theme.colors.mantle

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: MochaDS.Theme.spacing.lg
                    anchors.rightMargin: MochaDS.Theme.spacing.lg
                    spacing: MochaDS.Theme.spacing.md

                    Text {
                        text: "Central de Aplicativos"
                        font.family: MochaDS.Theme.typography.familyBold
                        font.pixelSize: MochaDS.Theme.typography.sizeH2
                        color: MochaDS.Theme.colors.text
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                }

            }
        ]
        // 2. Sidebar Navigation
        sidebar: [
            MochaDS.Sidebar {
                anchors.fill: parent
                variant: "floated"
                expandedWidth: 285

                MochaDS.SidebarHeader {
                    height: 130

                    Column {
                        width: parent.width
                        spacing: MochaDS.Theme.spacing.md
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            spacing: MochaDS.Theme.spacing.sm
                            anchors.horizontalCenter: parent.horizontalCenter

                            MochaDS.LucideIcon {
                                name: "package"
                                size: 24
                                color: MochaDS.Theme.colors.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Arch Store"
                                font.family: MochaDS.Theme.typography.familyBold
                                font.pixelSize: MochaDS.Theme.typography.sizeLg
                                color: MochaDS.Theme.colors.text
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                        MochaDS.TextField {
                            id: headerSearchField

                            placeholder: "Buscar pacotes..."
                            iconLeft: "search"
                            width: parent.width - MochaDS.Theme.spacing.lg * 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            onTextChanged: {
                                searchQuery = text;
                                if (text.length > 2 && currentPage !== "search") {
                                    currentPage = "search";
                                }
                                triggerSearch(text, false);
                            }
                        }

                    }

                }

                MochaDS.SidebarSection {
                    spacing: 8

                    MochaDS.SidebarItem {
                        icon: "compass"
                        label: "Explorar"
                        isActive: currentPage === "explore"
                        onClicked: {
                            currentPage = "explore";
                        }
                    }

                    MochaDS.SidebarItem {
                        icon: "search"
                        label: "Buscar"
                        isActive: currentPage === "search"
                        onClicked: {
                            currentPage = "search";
                        }
                    }

                    MochaDS.SidebarItem {
                        icon: "folder"
                        label: "Instalados"
                        isActive: currentPage === "installed"
                        onClicked: {
                            refreshInstalledList();
                            currentPage = "installed";
                        }
                    }

                }

                MochaDS.SidebarFooter {
                    username: "Usuário Arch"
                    email: "arch@localhost"
                    avatarIcon: "cat"
                }

            }
        ]
        // 3. Main Workspace Area (col1)
        col1: [
            Item {
                anchors.fill: parent

                // View 1: Explore View
                Flickable {
                    id: exploreView

                    anchors.fill: parent
                    visible: currentPage === "explore"
                    contentHeight: exploreContent.height + MochaDS.Theme.spacing.xxl
                    clip: true

                    Column {
                        id: exploreContent

                        width: parent.width
                        spacing: 24

                        // Header Banner Card
                        MochaDS.Card {
                            width: parent.width - MochaDS.Theme.spacing.lg
                            height: 180
                            variant: "accent"
                            accentPosition: "left"
                            customAccentColor: MochaDS.Theme.colors.mauve
                            backgroundColor: "mantle"
                            headerSeparator: false
                            footerSeparator: false

                            Column {
                                anchors.fill: parent
                                anchors.margins: MochaDS.Theme.spacing.lg
                                spacing: MochaDS.Theme.spacing.sm

                                Text {
                                    text: "Central de Aplicativos Arch"
                                    font.family: MochaDS.Theme.typography.familyBold
                                    font.pixelSize: MochaDS.Theme.typography.sizeH1
                                    color: MochaDS.Theme.colors.text
                                }

                                Text {
                                    text: "Gerencie Pacotes Oficiais (Pacman), AUR e Flatpaks em uma única interface moderna com design Mocha."
                                    font.family: MochaDS.Theme.typography.family
                                    font.pixelSize: MochaDS.Theme.typography.sizeLg
                                    color: MochaDS.Theme.colors.subtext1
                                }

                                Row {
                                    spacing: MochaDS.Theme.spacing.md

                                    MochaDS.Badge {
                                        text: "Pacman"
                                        variant: "primary"
                                    }

                                    MochaDS.Badge {
                                        text: "AUR"
                                        variant: "warning"
                                    }

                                    MochaDS.Badge {
                                        text: "Flatpak"
                                        variant: "secondary"
                                    }

                                }

                            }

                        }

                        // Section 1: Package Sources (3 columns)
                        Text {
                            text: "Fontes de Pacotes"
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeXl
                            color: MochaDS.Theme.colors.text
                        }

                        Flow {
                            width: parent.width
                            spacing: MochaDS.Theme.spacing.lg

                            MochaDS.Card {
                                title: "Repositórios Oficiais"
                                subtitle: "Pacotes pacman do Arch Linux"
                                icon: "package"
                                variant: "accent"
                                accentPosition: "top"
                                customAccentColor: MochaDS.Theme.colors.blue
                                width: Math.max(260, (parent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                                height: 130

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "system";
                                        currentPage = "search";
                                        triggerSearch("system", true);
                                    }
                                }

                            }

                            MochaDS.Card {
                                title: "AUR (Community)"
                                subtitle: "Arch User Repository"
                                icon: "users"
                                variant: "accent"
                                accentPosition: "top"
                                customAccentColor: MochaDS.Theme.colors.yellow
                                width: Math.max(260, (parent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                                height: 130

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "yay";
                                        currentPage = "search";
                                        triggerSearch("yay", true);
                                    }
                                }

                            }

                            MochaDS.Card {
                                title: "Flatpak (Flathub)"
                                subtitle: "Aplicativos sandbox universais"
                                icon: "box"
                                variant: "accent"
                                accentPosition: "top"
                                customAccentColor: MochaDS.Theme.colors.teal
                                width: Math.max(260, (parent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                                height: 130

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "flatpak";
                                        currentPage = "search";
                                        triggerSearch("flatpak", true);
                                    }
                                }

                            }

                        }

                        // Section 2: Popular Categories (4 columns)
                        Text {
                            text: "Categorias Populares"
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeXl
                            color: MochaDS.Theme.colors.text
                        }

                        Flow {
                            width: parent.width
                            spacing: MochaDS.Theme.spacing.lg

                            MochaDS.Card {
                                title: "Desenvolvimento"
                                icon: "code"
                                variant: "tonal"
                                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                                height: 90

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "development";
                                        currentPage = "search";
                                        triggerSearch("development", true);
                                    }
                                }

                            }

                            MochaDS.Card {
                                title: "Jogos"
                                icon: "gamepad-2"
                                variant: "tonal"
                                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                                height: 90

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "game";
                                        currentPage = "search";
                                        triggerSearch("game", true);
                                    }
                                }

                            }

                            MochaDS.Card {
                                title: "Gráficos"
                                icon: "image"
                                variant: "tonal"
                                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                                height: 90

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "graphics";
                                        currentPage = "search";
                                        triggerSearch("graphics", true);
                                    }
                                }

                            }

                            MochaDS.Card {
                                title: "Produtividade"
                                icon: "briefcase"
                                variant: "tonal"
                                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                                height: 90

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "office";
                                        currentPage = "search";
                                        triggerSearch("office", true);
                                    }
                                }

                            }

                        }

                        // Section 3: Recommended (4 columns)
                        Text {
                            text: "Populares & Recomendados"
                            font.family: MochaDS.Theme.typography.familyMedium
                            font.pixelSize: MochaDS.Theme.typography.sizeXl
                            color: MochaDS.Theme.colors.text
                        }

                        Flow {
                            width: parent.width
                            spacing: MochaDS.Theme.spacing.lg

                            MochaDS.Card {
                                title: "VS Code"
                                subtitle: "Editor de código"
                                icon: "code"
                                variant: "accent"
                                accentPosition: "top"
                                customAccentColor: MochaDS.Theme.colors.blue
                                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                                height: 120

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "visual-studio-code";
                                        currentPage = "search";
                                        triggerSearch("visual-studio-code", true);
                                    }
                                }

                            }

                            MochaDS.Card {
                                title: "GIMP"
                                subtitle: "Editor de imagens"
                                icon: "image"
                                variant: "accent"
                                accentPosition: "top"
                                customAccentColor: MochaDS.Theme.colors.green
                                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                                height: 120

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "gimp";
                                        currentPage = "search";
                                        triggerSearch("gimp", true);
                                    }
                                }

                            }

                            MochaDS.Card {
                                title: "VLC Player"
                                subtitle: "Reprodutor de mídia"
                                icon: "play"
                                variant: "accent"
                                accentPosition: "top"
                                customAccentColor: MochaDS.Theme.colors.peach
                                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                                height: 120

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "vlc";
                                        currentPage = "search";
                                        triggerSearch("vlc", true);
                                    }
                                }

                            }

                            MochaDS.Card {
                                title: "Firefox"
                                subtitle: "Navegador Web"
                                icon: "globe"
                                variant: "accent"
                                accentPosition: "top"
                                customAccentColor: MochaDS.Theme.colors.red
                                width: Math.max(200, (parent.width - MochaDS.Theme.spacing.lg * 4) / 4)
                                height: 120

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        headerSearchField.text = "firefox";
                                        currentPage = "search";
                                        triggerSearch("firefox", true);
                                    }
                                }

                            }

                        }

                    }

                    ScrollBar.vertical: ScrollBar {
                    }

                }

                // View 2: Search View
                Item {
                    id: searchView

                    anchors.fill: parent
                    visible: currentPage === "search"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 16

                        // Search input layout
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            MochaDS.TextField {
                                id: searchInputField

                                placeholder: "Pesquise por nome, descrição ou categoria..."
                                text: searchQuery
                                iconLeft: "search"
                                Layout.fillWidth: true
                                onTextChanged: {
                                    if (activeFocus) {
                                        searchQuery = text;
                                        triggerSearch(text, false);
                                    }
                                }
                                onAccepted: {
                                    searchQuery = text;
                                    triggerSearch(text, true);
                                }
                            }

                            MochaDS.Button {
                                text: "Buscar"
                                variant: "primary"
                                onClicked: {
                                    searchQuery = searchInputField.text;
                                    triggerSearch(searchQuery, true);
                                }
                            }

                        }

                        // Search Loading
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            visible: searchLoading

                            MochaDS.CozySpinner {
                                size: 48
                                anchors.centerIn: parent
                            }

                        }

                        // Search Results Grid
                        Flickable {
                            id: searchFlickable

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: resultsFlow.height
                            clip: true
                            visible: !searchLoading

                            Flow {
                                id: resultsFlow

                                width: searchFlickable.width
                                spacing: MochaDS.Theme.spacing.lg

                                Repeater {
                                    model: searchResults

                                    delegate: MochaDS.Card {
                                        title: modelData.title
                                        subtitle: modelData.version
                                        variant: "default"
                                        width: Math.max(280, (parent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                                        height: 180

                                        Column {
                                            anchors.fill: parent
                                            spacing: 8

                                            Row {
                                                width: parent.width
                                                spacing: 8

                                                AppIcon {
                                                    width: 48
                                                    height: 48
                                                    iconSource: modelData.icon
                                                    packageName: modelData.name
                                                }

                                                Column {
                                                    spacing: 4
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    Row {
                                                        spacing: 4

                                                        MochaDS.Badge {
                                                            text: modelData.type.toUpperCase()
                                                            variant: modelData.type === "flatpak" ? "secondary" : (modelData.type === "aur" ? "warning" : "primary")
                                                        }

                                                        MochaDS.Badge {
                                                            text: "Instalado"
                                                            variant: "success"
                                                            visible: modelData.installed
                                                        }
                                                    }
                                                }

                                            }

                                            Text {
                                                text: modelData.desc
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
                                                    selectedApp = modelData;
                                                    appDetailModal.open = true;
                                                }
                                            }

                                        }

                                    }

                                }

                            }

                        }

                    }

                }

                // View 3: Installed View
                Flickable {
                    id: installedView

                    anchors.fill: parent
                    visible: currentPage === "installed"
                    contentHeight: installedContent.height + MochaDS.Theme.spacing.xxl
                    clip: true

                    Column {
                        id: installedContent

                        width: parent.width
                        spacing: 20

                        RowLayout {
                            width: parent.width

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
                                onClicked: refreshInstalledList()
                            }

                        }

                        Flow {
                            id: installedFlow

                            width: parent.width
                            spacing: MochaDS.Theme.spacing.lg

                            Repeater {
                                model: installedApps

                                delegate: MochaDS.Card {
                                    title: modelData.title
                                    subtitle: "Versão: " + modelData.version
                                    variant: "default"
                                    width: Math.max(280, (parent.width - MochaDS.Theme.spacing.lg * 3) / 3)
                                    height: 170

                                    Column {
                                        anchors.fill: parent
                                        spacing: 8

                                        Row {
                                            spacing: 8
                                            width: parent.width

                                            AppIcon {
                                                width: 40
                                                height: 40
                                                iconSource: modelData.icon
                                                packageName: modelData.name
                                            }

                                            MochaDS.Badge {
                                                text: modelData.type.toUpperCase()
                                                variant: modelData.type === "flatpak" ? "secondary" : "primary"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                        }

                                        Text {
                                            text: modelData.desc
                                            width: parent.width
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                            font.family: MochaDS.Theme.typography.family
                                            font.pixelSize: MochaDS.Theme.typography.sizeSm
                                            color: MochaDS.Theme.colors.subtext1
                                        }

                                        Row {
                                            spacing: 8
                                            anchors.horizontalCenter: parent.horizontalCenter

                                            MochaDS.Button {
                                                text: "Desinstalar"
                                                variant: "danger"
                                                size: "sm"
                                                onClicked: {
                                                    consoleLog = "";
                                                    currentAction = "Desinstalação";
                                                    terminalModal.open = true;
                                                    backend.uninstallPackage(modelData.type, modelData.name);
                                                }
                                            }

                                        }

                                    }

                                }

                            }

                        }

                    }

                }

            }
        ]
    }

    // 4. Modal: App Details Dialog
    MochaDS.Modal {
        id: appDetailModal

        title: selectedApp ? selectedApp.title : ""
        size: "md"

        Column {
            width: parent.width
            spacing: 16

            Row {
                spacing: 16
                width: parent.width

                AppIcon {
                    width: 64
                    height: 64
                    iconSource: selectedApp ? selectedApp.icon : ""
                    packageName: selectedApp ? selectedApp.name : ""
                }

                Column {
                    spacing: 4

                    Text {
                        text: selectedApp ? selectedApp.title : ""
                        font.family: MochaDS.Theme.typography.familyBold
                        font.pixelSize: MochaDS.Theme.typography.sizeXl
                        color: MochaDS.Theme.colors.text
                    }

                    Text {
                        text: selectedApp ? "Versão: " + selectedApp.version : ""
                        font.family: MochaDS.Theme.typography.family
                        font.pixelSize: MochaDS.Theme.typography.sizeSm
                        color: MochaDS.Theme.colors.subtext0
                    }

                }

            }

            Text {
                text: selectedApp ? selectedApp.desc : ""
                width: parent.width
                wrapMode: Text.Wrap
                font.family: MochaDS.Theme.typography.family
                font.pixelSize: MochaDS.Theme.typography.sizeMd
                color: MochaDS.Theme.colors.text
            }

            Row {
                spacing: 8

                MochaDS.Badge {
                    text: selectedApp ? "TIPO: " + selectedApp.type.toUpperCase() : ""
                    variant: selectedApp && selectedApp.type === "flatpak" ? "secondary" : "primary"
                }

            }

            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                MochaDS.Button {
                    text: selectedApp && selectedApp.installed ? "Desinstalar" : "Instalar"
                    variant: selectedApp && selectedApp.installed ? "danger" : "success"
                    onClicked: {
                        appDetailModal.open = false;
                        consoleLog = "";
                        currentAction = selectedApp.installed ? "Desinstalação" : "Instalação";
                        terminalModal.open = true;
                        if (selectedApp.installed)
                            backend.uninstallPackage(selectedApp.type, selectedApp.name);
                        else
                            backend.installPackage(selectedApp.type, selectedApp.name);
                    }
                }

                MochaDS.Button {
                    text: "Fechar"
                    variant: "outline"
                    onClicked: appDetailModal.open = false
                }

            }

        }

    }

    // 5. Modal: Terminal Log Console Overlay
    MochaDS.Modal {
        id: terminalModal

        title: currentAction + " em Andamento..."
        size: "lg"

        ColumnLayout {
            width: parent.width
            height: 400
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                MochaDS.CozySpinner {
                    size: 24
                }

                Text {
                    text: "Por favor, aguarde o processo finalizar..."
                    font.family: MochaDS.Theme.typography.family
                    font.pixelSize: MochaDS.Theme.typography.sizeSm
                    color: MochaDS.Theme.colors.subtext0
                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: MochaDS.Theme.colors.crust
                radius: MochaDS.Theme.geometry.radiusSm
                border.color: MochaDS.Theme.colors.surface0
                border.width: MochaDS.Theme.geometry.borderSm

                Flickable {
                    id: logFlickable

                    anchors.fill: parent
                    anchors.margins: 12
                    contentHeight: logText.implicitHeight
                    clip: true
                    onContentHeightChanged: {
                        logFlickable.contentY = Math.max(0, logFlickable.contentHeight - logFlickable.height);
                    }

                    Text {
                        id: logText

                        text: consoleLog
                        width: parent.width
                        wrapMode: Text.WrapAnywhere
                        font.family: "Monospace"
                        font.pixelSize: 12
                        color: MochaDS.Theme.colors.green
                    }

                }

            }

        }

    }

}
