#include "BackendClient.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QDebug>

BackendClient::BackendClient(QObject *parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this))
    , m_model(new ImageModel(this))
    , m_isLoading(false)
    , m_ordering("random")
    , m_count(20)
{
}

ImageModel* BackendClient::model() const
{
    return m_model;
}

bool BackendClient::isLoading() const
{
    return m_isLoading;
}

QString BackendClient::error() const
{
    return m_error;
}

QString BackendClient::ordering() const
{
    return m_ordering;
}

int BackendClient::count() const
{
    return m_count;
}

void BackendClient::setOrdering(const QString &ordering)
{
    if (m_ordering != ordering) {
        m_ordering = ordering;
        emit orderingChanged();
        refresh();
    }
}

void BackendClient::setCount(int count)
{
    if (m_count != count) {
        m_count = count;
        emit countChanged();
        refresh();
    }
}

void BackendClient::refresh()
{
    fetchImages();
}

void BackendClient::fetchImages()
{
    if (m_isLoading) return;

    m_isLoading = true;
    m_error.clear();
    emit isLoadingChanged();
    emit errorChanged();

    QUrl url("http://localhost:8080/images");
    QUrlQuery query;
    query.addQueryItem("count", QString::number(m_count));
    query.addQueryItem("ordering", m_ordering);
    // query.addQueryItem("last_image", m_lastImage); // TODO: Implement pagination logic if needed
    url.setQuery(query);

    QNetworkRequest request(url);
    QNetworkReply *reply = m_manager->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onReplyFinished(reply);
    });
}

void BackendClient::onReplyFinished(QNetworkReply *reply)
{
    m_isLoading = false;
    emit isLoadingChanged();

    if (reply->error() != QNetworkReply::NoError) {
        m_error = reply->errorString();
        emit errorChanged();
        qWarning() << "Network error:" << m_error;
        reply->deleteLater();
        return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    QJsonObject root = doc.object();

    if (root.contains("error")) {
        m_error = root["error"].toString();
        emit errorChanged();
        reply->deleteLater();
        return;
    }

    QJsonArray imagesArray = root["images"].toArray();
    QList<ImageEntry> images;

    for (const QJsonValue &val : imagesArray) {
        QJsonObject obj = val.toObject();
        ImageEntry entry;
        entry.filename = obj["filename"].toString();
        entry.filePath = obj["file_path"].toString();
        entry.url = obj["url"].toString();
        entry.mimeType = obj["mime_type"].toString();
        entry.size = obj["size"].toVariant().toLongLong();
        entry.width = obj["width"].toInt();
        entry.height = obj["height"].toInt();
        entry.modifiedDate = QDateTime::fromString(obj["modified_date"].toString(), Qt::ISODate);
        images.append(entry);
    }

    m_model->setImages(images);
    
    // Update last image for pagination if we were to implement it
    if (!images.isEmpty()) {
        m_lastImage = images.last().filename;
    }

    reply->deleteLater();
}
