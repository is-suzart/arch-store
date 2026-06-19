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
    property alias developmentView: developmentView
    // Global Loader State
    property bool globalLoading: false
    property string globalLoadingLabel: ""

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
        if (typeof developmentView !== "undefined" && developmentView !== null)
            developmentView.refresh();

        if (typeof updatesView !== "undefined" && updatesView !== null)
            updatesView.refresh();

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
        runWithLoader(qsTr("Carregando pacotes do grupo %1...").arg(groupLabel), function() {
            groupPackagesView.groupName = groupName;
            groupPackagesView.groupLabel = groupLabel;
            window.currentPage = "group_" + groupName;
            groupPackagesView.refresh();
        });
    }

    function triggerUninstall(type, name) {
        consoleLog = "";
        currentAction = qsTr("Desinstalação");
        terminalModal.open = true;
        backend.uninstallPackage(type, name);
    }

    function isBatchAppSelected(pkgName) {
        for (var i = 0; i < selectedBatchApps.length; i++) {
            if (selectedBatchApps[i].name === pkgName)
                return true;

        }
        return false;
    }

    function toggleBatchApp(appData) {
        var temp = [];
        var found = false;
        for (var i = 0; i < selectedBatchApps.length; i++) {
            if (selectedBatchApps[i].name === appData.name)
                found = true;
            else
                temp.push(selectedBatchApps[i]);
        }
        if (!found)
            temp.push({
            "name": appData.name,
            "title": appData.title || appData.name,
            "type": appData.type
        });

        selectedBatchApps = temp;
    }

    function clearBatchApps() {
        selectedBatchApps = [];
    }

    function startBatchInstallation() {
        if (selectedBatchApps.length === 0)
            return ;

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
            toasts.success(qsTr("Todas as instalações em lote foram concluídas!"), qsTr("Sucesso"));
            refreshInstalledList();
            return ;
        }
        var nextApp = batchQueue[0];
        var tempQueue = [];
        for (var i = 1; i < batchQueue.length; i++) {
            tempQueue.push(batchQueue[i]);
        }
        batchQueue = tempQueue;
        currentBatchApp = nextApp;
        currentAction = qsTr("Instalação de %1").arg(nextApp.title);
        terminalModal.open = true;
        consoleLog += qsTr("\n=== Iniciando instalação de %1 (%2) ===\n").arg(nextApp.title).arg(nextApp.type);
        backend.installPackage(nextApp.type, nextApp.name);
    }

    function isBatchUninstallAppSelected(pkgName) {
        for (var i = 0; i < selectedBatchUninstallApps.length; i++) {
            if (selectedBatchUninstallApps[i].name === pkgName)
                return true;

        }
        return false;
    }

    function toggleBatchUninstallApp(appData) {
        var temp = [];
        var found = false;
        for (var i = 0; i < selectedBatchUninstallApps.length; i++) {
            if (selectedBatchUninstallApps[i].name === appData.name)
                found = true;
            else
                temp.push(selectedBatchUninstallApps[i]);
        }
        if (!found)
            temp.push({
            "name": appData.name,
            "title": appData.title || appData.name,
            "type": appData.type
        });

        selectedBatchUninstallApps = temp;
    }

    function clearBatchUninstallApps() {
        selectedBatchUninstallApps = [];
    }

    function startBatchUninstallation() {
        if (selectedBatchUninstallApps.length === 0)
            return ;

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
            toasts.success(qsTr("Todas as desinstalações em lote foram concluídas!"), qsTr("Sucesso"));
            refreshInstalledList();
            return ;
        }
        var nextApp = batchUninstallQueue[0];
        var tempQueue = [];
        for (var i = 1; i < batchUninstallQueue.length; i++) {
            tempQueue.push(batchUninstallQueue[i]);
        }
        batchUninstallQueue = tempQueue;
        currentBatchUninstallApp = nextApp;
        currentAction = qsTr("Desinstalação de %1").arg(nextApp.title);
        terminalModal.open = true;
        consoleLog += qsTr("\n=== Iniciando desinstalação de %1 (%2) ===\n").arg(nextApp.title).arg(nextApp.type);
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
        if (check_updates)
            updatesView.refresh();

    }

    Timer {
        id: globalLoaderTimer

        property var callback: null

        interval: 75
        repeat: false
        onTriggered: {
            if (callback)
                callback();

            globalLoading = false;
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
                if (success)
                    toasts.success(qsTr("Instalação de %1 concluída!").arg(window.currentBatchApp ? window.currentBatchApp.title : ""), qsTr("Sucesso"));
                else
                    toasts.error(qsTr("Falha ao instalar %1.").arg(window.currentBatchApp ? window.currentBatchApp.title : ""), qsTr("Erro"));
                window.processNextBatchItem();
            } else if (window.isBatchUninstallRunning) {
                if (success)
                    toasts.success(qsTr("Desinstalação de %1 concluída!").arg(window.currentBatchUninstallApp ? window.currentBatchUninstallApp.title : ""), qsTr("Sucesso"));
                else
                    toasts.error(qsTr("Falha ao desinstalar %1.").arg(window.currentBatchUninstallApp ? window.currentBatchUninstallApp.title : ""), qsTr("Erro"));
                window.processNextBatchUninstallItem();
            } else {
                terminalModal.open = false;
                if (success)
                    toasts.success(qsTr("Operação concluída com sucesso!"), qsTr("Sucesso"));
                else
                    toasts.error(qsTr("A operação falhou. Verifique os logs."), qsTr("Erro"));
                runWithLoader(qsTr("Atualizando lista de aplicativos..."), function() {
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
        headerVisible: mainShell.isMobile
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
                    anchors.leftMargin: MochaDS.Theme.spacing.md
                    anchors.rightMargin: MochaDS.Theme.spacing.md
                    spacing: MochaDS.Theme.spacing.sm

                    MochaDS.Button {
                        icon: "menu"
                        variant: "ghost"
                        size: "sm"
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: {
                            mainShell.sidebarOpenMobile = !mainShell.sidebarOpenMobile;
                        }
                    }

                    MochaDS.LucideIcon {
                        name: "package"
                        size: 20
                        color: MochaDS.Theme.colors.primary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "Arch Store"
                        font.family: MochaDS.Theme.typography.familyBold
                        font.pixelSize: MochaDS.Theme.typography.sizeLg
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
                            text: window.selectedBatchApps.length === 1 ? qsTr("aplicativo selecionado para instalação") : qsTr("aplicativos selecionados para instalação em lote")
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
                        text: qsTr("Limpar Seleção")
                        variant: "outline"
                        size: "sm"
                        onClicked: {
                            window.clearBatchApps();
                        }
                    }

                    MochaDS.Button {
                        text: qsTr("Instalar em Lote")
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
                            text: window.selectedBatchUninstallApps.length === 1 ? qsTr("aplicativo selecionado para desinstalação") : qsTr("aplicativos selecionados para desinstalação em lote")
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
                        text: qsTr("Limpar Seleção")
                        variant: "outline"
                        size: "sm"
                        onClicked: {
                            window.clearBatchUninstallApps();
                        }
                    }

                    MochaDS.Button {
                        text: qsTr("Desinstalar em Lote")
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

                // View 4.5: Development View
                DevelopmentView {
                    id: developmentView

                    anchors.fill: parent
                    visible: currentPage === "development"
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
                        if (visible)
                            settingsView.loadConfig();

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

        title: qsTr("%1 em Andamento...").arg(currentAction)
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
                    text: qsTr("Por favor, aguarde o processo finalizar...")
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
