import MochaDS 1.0 as MochaDS
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "./view"
import "./componentes"

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

    function searchFor(query) {
        headerSearchField.text = query;
        currentPage = "search";
        triggerSearch(query, true);
    }

    function triggerUninstall(type, name) {
        consoleLog = "";
        currentAction = "Desinstalação";
        terminalModal.open = true;
        backend.uninstallPackage(type, name);
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
                ExploreView {
                    anchors.fill: parent
                    visible: currentPage === "explore"
                }

                // View 2: Search View
                SearchView {
                    anchors.fill: parent
                    visible: currentPage === "search"
                }

                // View 3: Installed View
                InstalledView {
                    anchors.fill: parent
                    visible: currentPage === "installed"
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
