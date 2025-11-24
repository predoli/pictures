#ifndef IMAGEMODEL_H
#define IMAGEMODEL_H

#include <QAbstractListModel>
#include <QList>
#include <QString>
#include <QUrl>
#include <QDateTime>

struct ImageEntry {
    QString filename;
    QString filePath;
    QString url;
    QString mimeType;
    qint64 size;
    int width;
    int height;
    QDateTime modifiedDate;
};

class ImageModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ImageRoles {
        FilenameRole = Qt::UserRole + 1,
        FilePathRole,
        UrlRole,
        MimeTypeRole,
        SizeRole,
        WidthRole,
        HeightRole,
        ModifiedDateRole
    };

    explicit ImageModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setImages(const QList<ImageEntry> &images);
    void clear();

private:
    QList<ImageEntry> m_images;
};

#endif // IMAGEMODEL_H
