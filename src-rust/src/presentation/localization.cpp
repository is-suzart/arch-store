#include "localization.h"
#include <QtCore/QCoreApplication>
#include <QtCore/QTranslator>
#include <QtCore/QLocale>
#include <QtCore/QDir>
#include <QtCore/QFileInfo>
#include <cstring>

extern "C" void setup_qt_translator(void* app_ptr, const char* locale_dir) {
    if (!app_ptr || !locale_dir) return;

    QDir dir(locale_dir);
    if (!dir.exists()) return;

    // Detect system locale
    QLocale systemLocale = QLocale::system();
    QString langCode = systemLocale.name(); // e.g. "pt_BR", "en_US"

    // Try full locale first (e.g. "en_US.qm"), then language-only (e.g. "en.qm")
    QStringList candidates;
    candidates << langCode + ".qm";
    candidates << langCode.left(2) + ".qm"; // fallback to "en.qm"

    for (const auto& baseName : candidates) {
        QString path = dir.filePath(baseName);
        if (QFileInfo::exists(path)) {
            auto* translator = new QTranslator();
            if (translator->load(path)) {
                QCoreApplication::installTranslator(translator);
            }
            break;
        }
    }
}
