import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;
  WebSocketChannel? _channel;
  bool _isSwitchOn = false;

  @override
  void dispose() {
    mapboxMap?.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
  }

  void _onStyleLoadedCallback(StyleLoadedEventData data) {
    _addVectorTileSourceAndLayer();
  }

  Future<void> _addVectorTileSourceAndLayer() async {
    if (mapboxMap == null) return;

    try {
      await mapboxMap!.style.addSource(VectorSource(
        id: 'custom-vector-source',
        tiles: [
          'https://azarashiha.github.io/tokyo_od_2024/tiles/{z}/{x}/{y}.pbf'
        ],
        minzoom: 0,
        maxzoom: 14,
      ));

      await mapboxMap!.style.addLayer(LineLayer(
        id: 'custom-vector-layer',
        sourceId: 'custom-vector-source',
        sourceLayer: 'N022023_m2024',
        lineColorExpression: [
          'match',
          ['get', 'N02_003'],
          '池上線', '#f988fc',
          '#595959',
        ],
        lineWidth: 2.0,
      ));
    } catch (e) {
      print('Error adding vector tile source or layer: $e');
    }
  }

  void _toggleSwitch(bool value) {
    setState(() {
      _isSwitchOn = value;
    });

    if (_isSwitchOn) {
      _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.1.15:5136/ws'));
      _channel!.stream.listen((data) {
        _onDataReceived(data);
      }, onError: (error) {
        print('WebSocket Error: $error');
      }, onDone: () {
        print('WebSocket Closed');
      });
    } else {
      _channel?.sink.close();
      _channel = null;
      _removeGeoJsonLayer();
    }
  }

  Future<void> _onDataReceived(String data) async {
    if (mapboxMap == null) return;

    try {
      // 受信したGeoJSONデータをMapに変換
      Map<String, dynamic> geoJsonData = json.decode(data);

      // GeoJSONデータをJSON文字列に変換
      String geoJsonString = jsonEncode(geoJsonData);

      // ソースが存在するか確認
      bool sourceExists = await mapboxMap!.style.styleSourceExists('earthquake-source');
      if (sourceExists) {
        // 既存のGeoJsonSourceを取得
        var source = await mapboxMap!.style.getSource('earthquake-source') as GeoJsonSource?;
        if (source != null) {
          // GeoJSONデータを更新
          await source.updateGeoJSON(geoJsonString);
        }
      } else {
        // GeoJsonSource を追加
        await mapboxMap!.style.addSource(GeoJsonSource(
          id: 'earthquake-source',
          data: geoJsonString,
        ));

        // サークルレイヤーを追加
        await mapboxMap!.style.addLayer(CircleLayer(
          id: 'earthquake-layer',
          sourceId: 'earthquake-source',
          circleColorExpression: ['get', 'color'],
          circleRadius: 6.0,
        ));
      }
    } catch (e) {
      print('Error processing GeoJSON data: $e');
    }
  }

  Future<void> _removeGeoJsonLayer() async {
    if (mapboxMap == null) return;

    try {
      await mapboxMap!.style.removeStyleLayer('earthquake-layer');
      await mapboxMap!.style.removeStyleSource('earthquake-source');
    } catch (e) {
      // レイヤーやソースが存在しない場合のエラーを無視
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapWidget(
        key: ValueKey('mapWidget'),
        styleUri: 'mapbox://styles/mapbox/light-v11',
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: Position(139.711713, 35.633635),
          ),
          zoom: 12.0,
        ),
        onMapCreated: _onMapCreated,
        onStyleLoadedListener: _onStyleLoadedCallback,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _toggleSwitch(!_isSwitchOn),
        child: Icon(_isSwitchOn ? Icons.pause : Icons.play_arrow),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
