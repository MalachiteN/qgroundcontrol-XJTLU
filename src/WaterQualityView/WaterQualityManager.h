#pragma once

#include <QObject>
#include <QWebSocket>
#include <QMap>
#include <QPointF>
#include <QList>
#include <QVariant>
#include <QTimer>
#include <QQmlEngine>
#include <QLoggingCategory>
#include <QGeoCoordinate>

#include "QmlObjectListModel.h"

Q_DECLARE_LOGGING_CATEGORY(WaterQualityManagerLog)

// A single water-quality sample anchored to a geographic position.
// coordinate is captured from the active vehicle when the sample arrived;
// summary is the concatenation of all sensor readings in that WebSocket frame.
class WaterQualitySamplePoint : public QObject {
    Q_OBJECT
    Q_PROPERTY(QGeoCoordinate coordinate READ coordinate CONSTANT)
    Q_PROPERTY(QString        summary   READ summary   CONSTANT)
    Q_PROPERTY(double         timestamp READ timestamp CONSTANT)

public:
    WaterQualitySamplePoint(QGeoCoordinate coordinate, QString summary, double timestamp, QObject* parent = nullptr)
        : QObject(parent), _coordinate(std::move(coordinate)), _summary(std::move(summary)), _timestamp(timestamp) {}

    QGeoCoordinate coordinate() const { return _coordinate; }
    QString        summary()   const { return _summary; }
    double         timestamp() const { return _timestamp; }

private:
    QGeoCoordinate _coordinate;
    QString        _summary;
    double         _timestamp = 0;
};

class WaterQualityManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString currentBoatName READ currentBoatName WRITE connectToBoat NOTIFY currentBoatNameChanged)
    Q_PROPERTY(QStringList sensorList READ sensorList NOTIFY sensorListChanged)
    Q_PROPERTY(double yAxisMin READ yAxisMin NOTIFY axisRangeChanged)
    Q_PROPERTY(double yAxisMax READ yAxisMax NOTIFY axisRangeChanged)
    Q_PROPERTY(QmlObjectListModel* samplePoints READ samplePoints NOTIFY samplePointsChanged)

public:
    static WaterQualityManager* instance();
    static WaterQualityManager* create(QQmlEngine*, QJSEngine*) { return instance(); }
    
    WaterQualityManager(QObject* parent = nullptr);
    ~WaterQualityManager();

    QString currentBoatName() const { return _currentBoatName; }
    QStringList sensorList() const { return _sensorList; }

    double yAxisMin() const { return _yMin; }
    double yAxisMax() const { return _yMax; }

    QmlObjectListModel* samplePoints() const { return _samplePoints; }

    Q_INVOKABLE void connectToBoat(const QString& name);
    Q_INVOKABLE void setServerConfig(const QString& ip, const QString& port, const QString& station);
    Q_INVOKABLE void setSensorVisible(const QString& name, bool visible);
    Q_INVOKABLE bool isSensorVisible(const QString& name);
    Q_INVOKABLE QList<QPointF> getHistory(const QString& name);
    Q_INVOKABLE void clearData();
    // Fed by the Fly view layer so WS samples can be anchored to the live vehicle position.
    Q_INVOKABLE void updateVehicleCoordinate(const QGeoCoordinate& coordinate);

signals:
    void currentBoatNameChanged();
    void sensorListChanged();
    void axisRangeChanged();
    void newDataPoint(QString name, double x, double y);
    void samplePointsChanged();

private slots:
    void _onConnected();
    void _onTextMessageReceived(const QString& message);
    void _onClosed();

private:
    void _recalculateRange();
    void _addSamplePoint(const QString& summary, double t);

    static WaterQualityManager* _instance;

    QmlObjectListModel* _samplePoints = nullptr;
    QGeoCoordinate      _lastVehicleCoordinate;
    
    QWebSocket _socket;
    QString _currentBoatName;
    QStringList _sensorList;
    
    QString _serverIp;
    QString _wsPort;
    QString _stationName;
    
    // Data Storage
    // Key: Sensor Name
    QMap<QString, QList<QPointF>> _history;
    QMap<QString, double> _minMap;
    QMap<QString, double> _maxMap;
    QMap<QString, bool> _visibleMap;
    
    double _yMin = 0;
    double _yMax = 10;
    
    qint64 _startTime = 0;
};