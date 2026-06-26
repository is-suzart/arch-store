#include "system_icon_provider.h"
#include <QtQml/QQmlEngine>
#include <QtQuick/QQuickAsyncImageProvider>
#include <QtQuick/QQuickImageResponse>
#include <QtGui/QIcon>
#include <QtGui/QImage>
#include <QtCore/QThreadPool>
#include <QtCore/QRunnable>
#include <QtCore/QHash>
#include <QtCore/QMutex>
#include <QtCore/QMutexLocker>
#include <QtCore/QEvent>
#include <QtCore/QCoreApplication>

// 1. Custom event to pass QImage from background thread to AsyncIconResponse
class IconLoadedEvent : public QEvent {
public:
    static const QEvent::Type TYPE = static_cast<QEvent::Type>(QEvent::User + 1234);
    QImage image;
    IconLoadedEvent(const QImage& img) : QEvent(TYPE), image(img) {}
};

// 2. Main asynchronous provider class
class SystemIconProvider : public QQuickAsyncImageProvider {
private:
    QHash<QString, QImage> m_imageCache;
    QHash<QString, bool> m_missingCache;
    QMutex m_mutex;

public:
    SystemIconProvider() {}

    QQuickImageResponse* requestImageResponse(const QString &id, const QSize &requestedSize) override;

    void cacheImage(const QString& id, const QString& cacheKey, const QImage& image) {
        QMutexLocker locker(&m_mutex);
        if (image.isNull()) {
            m_missingCache.insert(id, true);
        } else {
            m_imageCache.insert(cacheKey, image);
        }
    }

    bool isMissing(const QString& id) {
        QMutexLocker locker(&m_mutex);
        return m_missingCache.contains(id);
    }

    QImage getCached(const QString& cacheKey) {
        QMutexLocker locker(&m_mutex);
        return m_imageCache.value(cacheKey);
    }
};

// 3. Runnable that performs filesystem lookup in background
class IconLoaderRunnable : public QRunnable {
private:
    QObject* m_response;
    SystemIconProvider* m_provider;
    QString m_id;
    QSize m_requestedSize;
    QString m_cacheKey;

public:
    IconLoaderRunnable(QObject* response, SystemIconProvider* provider, const QString& id, const QSize& requestedSize, const QString& cacheKey)
        : m_response(response), m_provider(provider), m_id(id), m_requestedSize(requestedSize), m_cacheKey(cacheKey) {}

    void run() override {
        QIcon icon = QIcon::fromTheme(m_id);
        if (icon.isNull()) {
            // Standard freedesktop icon naming spec fallbacks for package installer
            const QStringList fallbacks = {
                QStringLiteral("package-x-generic"),
                QStringLiteral("system-software-install"),
                QStringLiteral("application-x-executable"),
                QStringLiteral("preferences-system-details"),
                QStringLiteral("box")
            };
            for (const auto& name : fallbacks) {
                icon = QIcon::fromTheme(name);
                if (!icon.isNull()) {
                    break;
                }
            }
        }

        int width = m_requestedSize.width() > 0 ? m_requestedSize.width() : 64;
        int height = m_requestedSize.height() > 0 ? m_requestedSize.height() : 64;
        QImage image;
        if (!icon.isNull()) {
            image = icon.pixmap(width, height).toImage();
        }

        // Cache the result
        m_provider->cacheImage(m_id, m_cacheKey, image);

        // Safely notify the QQuickImageResponse on the main thread via Qt event loop
        QCoreApplication::postEvent(m_response, new IconLoadedEvent(image));
    }
};

// 4. Image response object for QML (bypasses custom Q_OBJECT MOC requirements)
class AsyncIconResponse : public QQuickImageResponse {
private:
    QImage m_image;

public:
    // Cached response constructor
    AsyncIconResponse(const QImage& image) : m_image(image) {
        QMetaObject::invokeMethod(this, [this]() { emit finished(); }, Qt::QueuedConnection);
    }

    // Async thread construction
    AsyncIconResponse(SystemIconProvider* provider, const QString &id, const QSize &requestedSize, const QString& cacheKey) {
        auto* runnable = new IconLoaderRunnable(this, provider, id, requestedSize, cacheKey);
        QThreadPool::globalInstance()->start(runnable);
    }

    QQuickTextureFactory* textureFactory() const override {
        return QQuickTextureFactory::textureFactoryForImage(m_image);
    }

protected:
    bool event(QEvent* e) override {
        if (e->type() == IconLoadedEvent::TYPE) {
            auto* loadedEvent = static_cast<IconLoadedEvent*>(e);
            m_image = loadedEvent->image;
            emit finished();
            return true;
        }
        return QQuickImageResponse::event(e);
    }
};

// Define requestImageResponse after AsyncIconResponse has been fully defined
QQuickImageResponse* SystemIconProvider::requestImageResponse(const QString &id, const QSize &requestedSize) {
    int width = requestedSize.width() > 0 ? requestedSize.width() : 64;
    int height = requestedSize.height() > 0 ? requestedSize.height() : 64;
    QString cacheKey = QStringLiteral("%1_%2x%3").arg(id).arg(width).arg(height);

    if (isMissing(id)) {
        return new AsyncIconResponse(QImage());
    }
    QImage img = getCached(cacheKey);
    if (!img.isNull()) {
        return new AsyncIconResponse(img);
    }

    return new AsyncIconResponse(this, id, requestedSize, cacheKey);
}

extern "C" void register_system_icon_provider(void* engine_ptr) {
    if (engine_ptr) {
        auto* engine = reinterpret_cast<QQmlEngine*>(engine_ptr);
        engine->addImageProvider(QStringLiteral("theme"), new SystemIconProvider());
    }
}
