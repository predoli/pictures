#include "ImageModel.h"

ImageModel::ImageModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ImageModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_images.count();
}

QVariant ImageModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_images.count())
        return QVariant();

    const ImageEntry &image = m_images[index.row()];

    switch (role) {
    case FilenameRole:
        return image.filename;
    case FilePathRole:
        return image.filePath;
    case UrlRole:
        return image.url;
    case MimeTypeRole:
        return image.mimeType;
    case SizeRole:
        return image.size;
    case WidthRole:
        return image.width;
    case HeightRole:
        return image.height;
    case ModifiedDateRole:
        return image.modifiedDate;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ImageModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[FilenameRole] = "filename";
    roles[FilePathRole] = "filePath";
    roles[UrlRole] = "url";
    roles[MimeTypeRole] = "mimeType";
    roles[SizeRole] = "size";
    roles[WidthRole] = "width";
    roles[HeightRole] = "height";
    roles[ModifiedDateRole] = "modifiedDate";
    return roles;
}

QVariantMap ImageModel::get(int row) const
{
    if (row < 0 || row >= m_images.count())
        return QVariantMap();

    const ImageEntry &image = m_images[row];
    QVariantMap map;
    map["filename"] = image.filename;
    map["filePath"] = image.filePath;
    map["url"] = image.url;
    map["mimeType"] = image.mimeType;
    map["size"] = image.size;
    map["width"] = image.width;
    map["height"] = image.height;
    map["modifiedDate"] = image.modifiedDate;
    return map;
}

void ImageModel::setImages(const QList<ImageEntry> &images)
{
    beginResetModel();
    m_images = images;
    endResetModel();
}

void ImageModel::clear()
{
    beginResetModel();
    m_images.clear();
    endResetModel();
}
