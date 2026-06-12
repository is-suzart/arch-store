from PySide6.QtQuick import QQuickImageProvider
from PySide6.QtGui import QIcon, QPixmap
from PySide6.QtCore import QSize

class SystemIconProvider(QQuickImageProvider):
    def __init__(self):
        super().__init__(QQuickImageProvider.Pixmap)

    def requestPixmap(self, id: str, size: QSize, requestedSize: QSize) -> QPixmap:
        # id corresponds to the icon name, e.g. "gimp" or "firefox"
        icon = QIcon.fromTheme(id)
        if icon.isNull():
            return QPixmap()

        # Choose sizes
        width = requestedSize.width() if requestedSize.width() > 0 else 64
        height = requestedSize.height() if requestedSize.height() > 0 else 64

        pixmap = icon.pixmap(width, height)
        
        if size:
            size.setWidth(pixmap.width())
            size.setHeight(pixmap.height())

        return pixmap
