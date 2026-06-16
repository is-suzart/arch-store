import "./componentes"
import "./view"
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

    // Batch Install properties
    property var selectedBatchApps: []
    property var batchQueue: []
    property bool isBatchRunning: false
    property var currentBatchApp: null

    // Batch Uninstall properties
    property var selectedBatchUninstallApps: []
    property var batchUninstallQueue: []
    property bool isBatchUninstallRunning: false
    property var currentBatchUninstallApp: null

    // Expose modals and views as properties on window for external files to access safely
    property alias appDetailModal: appDetailModal
    property alias terminalModal: terminalModal
    property alias gamingView: gamingView

    // Global Loader State
    property bool globalLoading: false
    property string globalLoadingLabel: ""

    Timer {
        id: globalLoaderTimer
        interval: 150
        repeat: false
        property var callback: null
        onTriggered: {
            if (callback) {
                callback();
            }
            globalLoading = false;
        }
    }

    function runWithLoader(label, callbackFunc) {
        globalLoadingLabel = label;
        globalLoading = true;
        globalLoaderTimer.callback = callbackFunc;
        globalLoaderTimer.start();
    }

    function refreshInstalledList() {
        installedApps = backend.getInstalledPackages();
        exploreView.refreshFeatured();
        gamingView.refresh();
        if (typeof updatesView !== "undefined" && updatesView !== null) {
            updatesView.refresh();
        }
    }

    function triggerSearch(query, immediate) {
        var isImmediate = (immediate === true);
        if (isImmediate)
            backend.searchImmediately(query);
        else
            backend.searchTextChanged(query);
    }

    function searchFor(query) {
        appSidebar.searchText = query;
        currentPage = "search";
        triggerSearch(query, true);
    }

    function loadGroup(groupName, groupLabel) {
        runWithLoader("Carregando pacotes do grupo " + groupLabel + "...", function() {
            groupPackagesView.groupName = groupName;
            groupPackagesView.groupLabel = groupLabel;
            window.currentPage = "group_" + groupName;
            groupPackagesView.refresh();
        });
    }

    function triggerUninstall(type, name) {
        consoleLog = "";
        currentAction = "Desinstalação";
        terminalModal.open = true;
        backend.uninstallPackage(type, name);
    }

    function isBatchAppSelected(pkgName) {
        for (var i = 0; i < selectedBatchApps.length; i++) {
            if (selectedBatchApps[i].name === pkgName) {
                return true;
            }
        }
        return false;
    }

    function toggleBatchApp(appData) {
        var temp = [];
        var found = false;
        for (var i = 0; i < selectedBatchApps.length; i++) {
            if (selectedBatchApps[i].name === appData.name) {
                found = true;
            } else {
                temp.push(selectedBatchApps[i]);
            }
        }
        if (!found) {
            temp.push({
                name: appData.name,
                title: appData.title || appData.name,
                type: appData.type
            });
        }
        selectedBatchApps = temp;
    }

    function clearBatchApps() {
        selectedBatchApps = [];
    }

    function startBatchInstallation() {
        if (selectedBatchApps.length === 0) return;
        
        var queue = [];
        for (var i = 0; i < selectedBatchApps.length; i++) {
            queue.push(selectedBatchApps[i]);
        }
        batchQueue = queue;
        isBatchRunning = true;
        clearBatchApps();
        
        consoleLog = "";
        processNextBatchItem();
    }

    function processNextBatchItem() {
        if (batchQueue.length === 0) {
            isBatchRunning = false;
            currentBatchApp = null;
            terminalModal.open = false;
            toasts.success("Todas as instalações em lote foram concluídas!", "Sucesso");
            refreshInstalledList();
            return;
        }
        
        var nextApp = batchQueue[0];
        var tempQueue = [];
        for (var i = 1; i < batchQueue.length; i++) {
            tempQueue.push(batchQueue[i]);
        }
        batchQueue = tempQueue;
        
        currentBatchApp = nextApp;
        currentAction = "Instalação de " + nextApp.title;
        terminalModal.open = true;
        
        consoleLog += "\n=== Iniciando instalação de " + nextApp.title + " (" + nextApp.type + ") ===\n";
        backend.installPackage(nextApp.type, nextApp.name);
    }

    function isBatchUninstallAppSelected(pkgName) {
        for (var i = 0; i < selectedBatchUninstallApps.length; i++) {
            if (selectedBatchUninstallApps[i].name === pkgName) {
                return true;
            }
        }
        return false;
    }

    function toggleBatchUninstallApp(appData) {
        var temp = [];
        var found = false;
        for (var i = 0; i < selectedBatchUninstallApps.length; i++) {
            if (selectedBatchUninstallApps[i].name === appData.name) {
                found = true;
            } else {
                temp.push(selectedBatchUninstallApps[i]);
            }
        }
        if (!found) {
            temp.push({
                name: appData.name,
                title: appData.title || appData.name,
                type: appData.type
            });
        }
        selectedBatchUninstallApps = temp;
    }

    function clearBatchUninstallApps() {
        selectedBatchUninstallApps = [];
    }

    function startBatchUninstallation() {
        if (selectedBatchUninstallApps.length === 0) return;
        
        var queue = [];
        for (var i = 0; i < selectedBatchUninstallApps.length; i++) {
            queue.push(selectedBatchUninstallApps[i]);
        }
        batchUninstallQueue = queue;
        isBatchUninstallRunning = true;
        clearBatchUninstallApps();
        
        consoleLog = "";
        processNextBatchUninstallItem();
    }

    function processNextBatchUninstallItem() {
        if (batchUninstallQueue.length === 0) {
            isBatchUninstallRunning = false;
            currentBatchUninstallApp = null;
            terminalModal.open = false;
            toasts.success("Todas as desinstalações em lote foram concluídas!", "Sucesso");
            refreshInstalledList();
            return;
        }
        
        var nextApp = batchUninstallQueue[0];
        var tempQueue = [];
        for (var i = 1; i < batchUninstallQueue.length; i++) {
            tempQueue.push(batchUninstallQueue[i]);
        }
        batchUninstallQueue = tempQueue;
        
        currentBatchUninstallApp = nextApp;
        currentAction = "Desinstalação de " + nextApp.title;
        terminalModal.open = true;
        
        consoleLog += "\n=== Iniciando desinstalação de " + nextApp.title + " (" + nextApp.type + ") ===\n";
        backend.uninstallPackage(nextApp.type, nextApp.name);
    }

    visible: true
    width: 1280
    height: 850
    title: "Arch Linux Store"
    color: MochaDS.Theme.colors.background
    // Initial load
    Component.onCompleted: {
        var saved_flavor = backend.getConfigStr("theme_flavor");
        MochaDS.Theme.flavor = saved_flavor;
        refreshInstalledList();
        
        var check_updates = backend.getConfigBool("check_updates_startup");
        if (check_updates) {
            updatesView.refresh();
        }
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
            if (window.isBatchRunning) {
                if (success) {
                    toasts.success("Instalação de " + (window.currentBatchApp ? window.currentBatchApp.title : "") + " concluída!", "Sucesso");
                } else {
                    toasts.error("Falha ao instalar " + (window.currentBatchApp ? window.currentBatchApp.title : "") + ".", "Erro");
                }
                window.processNextBatchItem();
            } else if (window.isBatchUninstallRunning) {
                if (success) {
                    toasts.success("Desinstalação de " + (window.currentBatchUninstallApp ? window.currentBatchUninstallApp.title : "") + " concluída!", "Sucesso");
                } else {
                    toasts.error("Falha ao desinstalar " + (window.currentBatchUninstallApp ? window.currentBatchUninstallApp.title : "") + ".", "Erro");
                }
                window.processNextBatchUninstallItem();
            } else {
                terminalModal.open = false;
                if (success)
                    toasts.success("Operação concluída com sucesso!", "Sucesso");
                else
                    toasts.error("A operação falhou. Verifique os logs.", "Erro");

                runWithLoader("Atualizando lista de aplicativos...", function() {
                    refreshInstalledList();
                    if (searchQuery)
                        triggerSearch(searchQuery, true);
                });
            }
        }
    }

    MochaDS.Shell {
        id: mainShell
        anchors.fill: parent
        sidebarWidth: 300
        headerVisible: false
        columnCount: 1
        footerHeight: 70
        footerVisible: (currentPage === "installed" && selectedBatchUninstallApps.length > 0) || (currentPage !== "installed" && selectedBatchApps.length > 0)

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
            AppSidebar {
                id: appSidebar
            }
        ]
        // 3. Footer Content
        footer: [
            Rectangle {
                anchors.fill: parent
                color: MochaDS.Theme.colors.mantle
                border.color: MochaDS.Theme.colors.surface0
                border.width: 1

                // 3.1. Batch Install Footer
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: MochaDS.Theme.spacing.lg
                    anchors.rightMargin: MochaDS.Theme.spacing.lg
                    spacing: MochaDS.Theme.spacing.md
                    visible: window.currentPage !== "installed"

                    RowLayout {
                        spacing: 8
                        MochaDS.Badge {
                            text: String(window.selectedBatchApps.length)
                            variant: "primary"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: window.selectedBatchApps.length === 1 
                                ? "aplicativo selecionado para instalação"
                                : "aplicativos selecionados para instalação em lote"
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    MochaDS.Button {
                        text: "Limpar Seleção"
                        variant: "outline"
                        size: "sm"
                        onClicked: {
                            window.clearBatchApps();
                        }
                    }

                    MochaDS.Button {
                        text: "Instalar em Lote"
                        variant: "success"
                        size: "md"
                        onClicked: {
                            window.startBatchInstallation();
                        }
                    }
                }

                // 3.2. Batch Uninstall Footer
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: MochaDS.Theme.spacing.lg
                    anchors.rightMargin: MochaDS.Theme.spacing.lg
                    spacing: MochaDS.Theme.spacing.md
                    visible: window.currentPage === "installed"

                    RowLayout {
                        spacing: 8
                        MochaDS.Badge {
                            text: String(window.selectedBatchUninstallApps.length)
                            variant: "danger"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: window.selectedBatchUninstallApps.length === 1 
                                ? "aplicativo selecionado para desinstalação"
                                : "aplicativos selecionados para desinstalação em lote"
                            font.family: MochaDS.Theme.typography.family
                            font.pixelSize: MochaDS.Theme.typography.sizeMd
                            color: MochaDS.Theme.colors.text
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    MochaDS.Button {
                        text: "Limpar Seleção"
                        variant: "outline"
                        size: "sm"
                        onClicked: {
                            window.clearBatchUninstallApps();
                        }
                    }

                    MochaDS.Button {
                        text: "Desinstalar em Lote"
                        variant: "danger"
                        size: "md"
                        onClicked: {
                            window.startBatchUninstallation();
                        }
                    }
                }
            }
        ]
        col1: [
            Item {
                anchors.fill: parent

                // View 1: Explore View
                ExploreView {
                    id: exploreView
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

                // View 4: Gaming View
                GamingView {
                    id: gamingView
                    anchors.fill: parent
                    visible: currentPage === "gaming"
                }

                // View 5: Updates View
                UpdatesView {
                    id: updatesView
                    anchors.fill: parent
                    visible: currentPage === "updates"
                }

                // View 6: Settings View
                SettingsView {
                    id: settingsView
                    anchors.fill: parent
                    visible: currentPage === "settings"
                    
                    // Whenever settingsView becomes visible, reload configuration
                    onVisibleChanged: {
                        if (visible) {
                            settingsView.loadConfig();
                        }
                    }
                }

                // View 7: Group Packages View
                GroupPackagesView {
                    id: groupPackagesView
                    anchors.fill: parent
                    visible: currentPage.startsWith("group_")
                }

            }
        ]
    }

    DetailModalApp {
        id: appDetailModal
        appData: selectedApp
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

    // Global page loading overlay spinner
    MochaDS.CozySpinner {
        overlay: true
        visible: window.globalLoading
        label: window.globalLoadingLabel
    }

}
