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

Q_DECLARE_LOGGING_CATEGORY(WaterQualityManagerLog)

class WaterQualityManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    
    Q_PROPERTY(QString currentBoatName READ currentBoatName WRITE connectToBoat NOTIFY currentBoatNameChanged)
    Q_PROPERTY(QStringList sensorList READ sensorList NOTIFY sensorListChanged)
    Q_PROPERTY(double yAxisMin READ yAxisMin NOTIFY axisRangeChanged)
    Q_PROPERTY(double yAxisMax READ yAxisMax NOTIFY axisRangeChanged)

public:
    static WaterQualityManager* instance();
    static WaterQualityManager* create(QQmlEngine*, QJSEngine*) { return instance(); }
    
    WaterQualityManager(QObject* parent = nullptr);
    ~WaterQualityManager();

    QString currentBoatName() const { return _currentBoatName; }
    QStringList sensorList() const { return _sensorList; }
    
    double yAxisMin() const { return _yMin; }
    double yAxisMax() const { return _yMax; }

    Q_INVOKABLE void connectToBoat(const QString& name);
    Q_INVOKABLE void setServerConfig(const QString& ip, const QString& port, const QString& station);
    Q_INVOKABLE void setSensorVisible(const QString& name, bool visible);
    Q_INVOKABLE bool isSensorVisible(const QString& name);
    Q_INVOKABLE QList<QPointF> getHistory(const QString& name);
    Q_INVOKABLE void clearData();

signals:
    void currentBoatNameChanged();
    void sensorListChanged();
    void axisRangeChanged();
    void newDataPoint(QString name, double x, double y);

private slots:
    void _onConnected();
    void _onTextMessageReceived(const QString& message);
    void _onClosed();

private:
    void _recalculateRange();

    static WaterQualityManager* _instance;
    
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