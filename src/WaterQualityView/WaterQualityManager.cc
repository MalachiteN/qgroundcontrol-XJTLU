#include "WaterQualityManager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QtMath>
#include <limits>
#include <QUrl>
#include <QDebug>

Q_LOGGING_CATEGORY(WaterQualityManagerLog, "WaterQualityManager")

WaterQualityManager* WaterQualityManager::_instance = nullptr;

WaterQualityManager* WaterQualityManager::instance() {
    if (!_instance) {
        _instance = new WaterQualityManager();
    }
    return _instance;
}

WaterQualityManager::WaterQualityManager(QObject* parent) : QObject(parent) {
    qCDebug(WaterQualityManagerLog) << "WaterQualityManager Created";
    connect(&_socket, &QWebSocket::connected, this, &WaterQualityManager::_onConnected);
    connect(&_socket, &QWebSocket::textMessageReceived, this, &WaterQualityManager::_onTextMessageReceived);
    connect(&_socket, &QWebSocket::disconnected, this, &WaterQualityManager::_onClosed);
    connect(&_socket, QOverload<QAbstractSocket::SocketError>::of(&QWebSocket::error), this, [](QAbstractSocket::SocketError error){
        qCDebug(WaterQualityManagerLog) << "WaterQualityManager WS Error:" << error;
    });
}

WaterQualityManager::~WaterQualityManager() {
    _socket.close();
}

void WaterQualityManager::setServerConfig(const QString& ip, const QString& port, const QString& station) {
    _serverIp = ip;
    _wsPort = port;
    _stationName = station;
}

void WaterQualityManager::connectToBoat(const QString& name) {
    if (_currentBoatName == name && _socket.state() == QAbstractSocket::ConnectedState) return;
    
    _currentBoatName = name;
    emit currentBoatNameChanged();
    
    clearData();
    
    _socket.close();
    QString url = QString("ws://%1:%2/gcs/%3/%4").arg(_serverIp, _wsPort, _stationName, name);
    qCDebug(WaterQualityManagerLog) << "WaterQualityManager Connecting to:" << url;
    _socket.open(QUrl(url));
}

void WaterQualityManager::clearData() {
    _history.clear();
    _minMap.clear();
    _maxMap.clear();
    _visibleMap.clear();
    _sensorList.clear();
    _startTime = 0;
    
    _yMin = 0;
    _yMax = 10;
    
    emit sensorListChanged();
    emit axisRangeChanged();
}

void WaterQualityManager::setSensorVisible(const QString& name, bool visible) {
    if (_visibleMap.value(name, true) != visible) {
        _visibleMap[name] = visible;
        _recalculateRange();
    }
}

bool WaterQualityManager::isSensorVisible(const QString& name) {
    return _visibleMap.value(name, true);
}

QList<QPointF> WaterQualityManager::getHistory(const QString& name) {
    return _history.value(name);
}

void WaterQualityManager::_onConnected() {
    qCDebug(WaterQualityManagerLog) << "WaterQualityManager WS Connected!";
}

void WaterQualityManager::_onClosed() {
    // Optional: Log disconnect
}

void WaterQualityManager::_onTextMessageReceived(const QString& message) {
    // qDebug() << "WaterQualityManager RX:" << message; // Verbose
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8());
    QJsonObject obj = doc.object();
    if (!obj.contains("data")) {
        qCWarning(WaterQualityManagerLog) << "WaterQualityManager RX invalid JSON (no data field):" << message;
        return;
    }
    // qCDebug(WaterQualityManagerLog) << "RX OK, items:" << obj["data"].toArray().size();
    
    qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (_startTime == 0) _startTime = now;
    
    double t = (now - _startTime) / 1000.0;
    
    QJsonArray data = obj["data"].toArray();
    bool rangeUpdated = false;
    
    for (const auto& itemRef : data) {
        QJsonObject item = itemRef.toObject();
        QString name = item["name"].toString();
        double value = item["value"].toDouble();
        
        // New Sensor?
        if (!_history.contains(name)) {
            _sensorList.append(name);
            _history[name] = QList<QPointF>();
            _minMap[name] = std::numeric_limits<double>::max();
            _maxMap[name] = std::numeric_limits<double>::lowest();
            _visibleMap[name] = true; // Default visible
            emit sensorListChanged();
        }
        
        // Append Data
        _history[name].append(QPointF(t, value));
        
        // Prune (Keep last 1000)
        if (_history[name].size() > 1000) {
            _history[name].removeFirst();
        }
        
        // Update Min/Max
        if (value < _minMap[name]) { _minMap[name] = value; if (_visibleMap.value(name, true)) rangeUpdated = true; }
        if (value > _maxMap[name]) { _maxMap[name] = value; if (_visibleMap.value(name, true)) rangeUpdated = true; }
        
        emit newDataPoint(name, t, value);
    }
    
    if (rangeUpdated) {
        _recalculateRange();
    }
}

void WaterQualityManager::_recalculateRange() {
    double gMin = std::numeric_limits<double>::max();
    double gMax = std::numeric_limits<double>::lowest();
    bool anyVisible = false;
    
    for (const QString& name : _sensorList) {
        if (_visibleMap.value(name, true)) {
            // Use cached min/max
            if (_minMap.contains(name) && _minMap[name] < gMin) gMin = _minMap[name];
            if (_maxMap.contains(name) && _maxMap[name] > gMax) gMax = _maxMap[name];
            anyVisible = true;
        }
    }
    
    if (!anyVisible || gMin > gMax) {
        gMin = 0; 
        gMax = 10;
    } else {
        // Add some padding
        double range = gMax - gMin;
        if (range < 0.1) range = 0.1;
        gMin -= range * 0.1;
        gMax += range * 0.1;
    }
    
    if (qAbs(gMin - _yMin) > 0.01 || qAbs(gMax - _yMax) > 0.01) {
        _yMin = gMin;
        _yMax = gMax;
        emit axisRangeChanged();
    }
}