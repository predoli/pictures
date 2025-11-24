#ifndef BACKENDCLIENT_H
#define BACKENDCLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include "ImageModel.h"

class BackendClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ImageModel* model READ model CONSTANT)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString ordering READ ordering WRITE setOrdering NOTIFY orderingChanged)
    Q_PROPERTY(int count READ count WRITE setCount NOTIFY countChanged)

public:
    explicit BackendClient(QObject *parent = nullptr);

    ImageModel* model() const;
    bool isLoading() const;
    QString error() const;
    QString ordering() const;
    int count() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setOrdering(const QString &ordering);
    Q_INVOKABLE void setCount(int count);

signals:
    void isLoadingChanged();
    void errorChanged();
    void orderingChanged();
    void countChanged();

private slots:
    void onReplyFinished(QNetworkReply *reply);

private:
    void fetchImages();

    QNetworkAccessManager *m_manager;
    ImageModel *m_model;
    bool m_isLoading;
    QString m_error;
    QString m_ordering;
    int m_count;
    QString m_lastImage; // To support pagination if needed, though current requirement is simple
};

#endif // BACKENDCLIENT_H
