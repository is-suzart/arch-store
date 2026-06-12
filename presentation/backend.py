import subprocess
from PySide6.QtCore import QObject, Slot, Signal, QThread, QTimer

class SearchWorker(QThread):
    results_ready = Signal(list)

    def __init__(self, search_usecase, query):
        super().__init__()
        self.search_usecase = search_usecase
        self.query = query

    def run(self):
        try:
            packages = self.search_usecase.execute(self.query)
            results = [pkg.to_dict() for pkg in packages]
            self.results_ready.emit(results)
        except Exception as e:
            print(f"Error in SearchWorker: {e}")
            self.results_ready.emit([])

class InstallWorker(QThread):
    log_received = Signal(str)
    finished = Signal(bool)

    def __init__(self, cmd):
        super().__init__()
        self.cmd = cmd

    def run(self):
        try:
            # We run the process capturing output and streaming it line-by-line
            process = subprocess.Popen(
                self.cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1
            )
            
            while True:
                line = process.stdout.readline()
                if not line and process.poll() is not None:
                    break
                if line:
                    self.log_received.emit(line.strip())
            
            rc = process.poll()
            self.finished.emit(rc == 0)
        except Exception as e:
            self.log_received.emit(f"Error executing command: {e}")
            self.finished.emit(False)

class Backend(QObject):
    logReceived = Signal(str, arguments=['line'])
    actionFinished = Signal(bool, arguments=['success'])
    searchResultsReady = Signal(list, arguments=['results'])
    searchLoadingChanged = Signal(bool, arguments=['loading'])

    def __init__(self, search_usecase, get_installed_usecase, install_usecase, uninstall_usecase):
        super().__init__()
        self.search_usecase = search_usecase
        self.get_installed_usecase = get_installed_usecase
        self.install_usecase = install_usecase
        self.uninstall_usecase = uninstall_usecase
        self.worker = None
        self.search_worker = None

        # Debounce timer setup
        self.search_timer = QTimer(self)
        self.search_timer.setSingleShot(True)
        self.search_timer.setInterval(500)
        self.search_timer.timeout.connect(self._executar_pesquisa)
        self.search_query = ""
        self.last_search_query = ""

    @Slot(str)
    def searchTextChanged(self, query):
        self.search_query = query.strip()
        self.search_timer.start()

    @Slot(str)
    def searchImmediately(self, query):
        self.search_query = query.strip()
        self.search_timer.stop()
        self._executar_pesquisa()

    def _executar_pesquisa(self):
        if self.search_query == self.last_search_query:
            return
            
        if len(self.search_query) < 3:
            self.last_search_query = self.search_query
            self.searchResultsReady.emit([])
            return

        self.last_search_query = self.search_query
        self.searchLoadingChanged.emit(True)

        if self.search_worker and self.search_worker.isRunning():
            self.search_worker.terminate()
            self.search_worker.wait()

        self.search_worker = SearchWorker(self.search_usecase, self.search_query)
        self.search_worker.results_ready.connect(self._on_search_completed)
        self.search_worker.start()

    def _on_search_completed(self, results):
        self.searchResultsReady.emit(results)
        self.searchLoadingChanged.emit(False)

    @Slot(str, result=list)
    def searchPackages(self, query):
        packages = self.search_usecase.execute(query)
        return [pkg.to_dict() for pkg in packages]

    @Slot(result=list)
    def getInstalledPackages(self):
        packages = self.get_installed_usecase.execute()
        return [pkg.to_dict() for pkg in packages]

    @Slot(str, str)
    def installPackage(self, pkg_type, pkg_name):
        if self.worker and self.worker.isRunning():
            self.logReceived.emit("Another operation is already running!")
            return

        cmd = self.install_usecase.execute(pkg_type, pkg_name)
        if not cmd:
            self.logReceived.emit("Unknown package type.")
            return

        self.logReceived.emit(f"Starting installation of {pkg_name} ({pkg_type})...")
        self.worker = InstallWorker(cmd)
        self.worker.log_received.connect(self.logReceived.emit)
        self.worker.finished.connect(self.on_worker_finished)
        self.worker.start()

    @Slot(str, str)
    def uninstallPackage(self, pkg_type, pkg_name):
        if self.worker and self.worker.isRunning():
            self.logReceived.emit("Another operation is already running!")
            return

        cmd = self.uninstall_usecase.execute(pkg_type, pkg_name)
        if not cmd:
            self.logReceived.emit("Unknown package type.")
            return

        self.logReceived.emit(f"Removing {pkg_name} ({pkg_type})...")
        self.worker = InstallWorker(cmd)
        self.worker.log_received.connect(self.logReceived.emit)
        self.worker.finished.connect(self.on_worker_finished)
        self.worker.start()

    def on_worker_finished(self, success):
        self.actionFinished.emit(success)
