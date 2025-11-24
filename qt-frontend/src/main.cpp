#include <QCommandLineParser>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "BackendClient.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QCoreApplication::setOrganizationName("DigitalPhotoFrame");
    QCoreApplication::setOrganizationDomain("example.com");
    QCoreApplication::setApplicationName("DigitalPhotoFrame");

    QQmlApplicationEngine engine;
    
    BackendClient backendClient;
    engine.rootContext()->setContextProperty("backend", &backendClient);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    engine.load(url);
    
    // Initial fetch
    backendClient.refresh();

    return app.exec();
}
