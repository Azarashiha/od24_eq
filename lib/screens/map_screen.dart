import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap; // MapboxMapインスタンス

  @override
  void dispose() {
    mapboxMap?.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    // ここでのloadStyleURIは不要です。styleUriはMapWidgetで指定しています。
  }

  void _onStyleLoadedCallback(StyleLoadedEventData data) {
    // スタイルがロードされた後にベクタタイルソースとレイヤーを追加
    _addVectorTileSourceAndLayer();
  }

  Future<void> _addVectorTileSourceAndLayer() async {
    if (mapboxMap == null) return;

    try {
      // ベクタタイルソースを追加
      await mapboxMap!.style.addSource(VectorSource(
        id: 'custom-vector-source',
        tiles: [
          'https://azarashiha.github.io/tokyo_od_2024/tiles/{z}/{x}/{y}.pbf'
        ],
        minzoom: 0,
        maxzoom: 14,
      ));

      // ベクタタイルレイヤーを追加
      await mapboxMap!.style.addLayer(LineLayer(
        id: 'custom-vector-layer',
        sourceId: 'custom-vector-source',
        sourceLayer: 'N022023_m2024', // ベクタタイルのレイヤー名
        lineColorExpression: [
          'match',
          ['get', 'N02_003'], // N02_003プロパティを取得
          '池上線',
          '#f988fc',
          '大井町線',
          '#ff9933',
          '#595959',
        ],
        lineWidth: 2.0,
      ));
    } catch (e) {
      print('Error adding vector tile source or layer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: ValueKey('mapWidget'),
      // アクセストークンはmain.dartで初期化しているため、ここでは指定不要
      styleUri: 'mapbox://styles/mapbox/light-v11', // ベース地図のスタイルURI
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(139.711713, 35.633635), // 東京の座標
        ),
        zoom: 12.0, // 初期ズームレベル
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoadedCallback, // ここでコールバックを設定
    );
  }
}
