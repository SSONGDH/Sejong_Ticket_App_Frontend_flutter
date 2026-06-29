import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';

Future<Uint8List> _createRedMarkerBytes() async {
  const double width = 60;
  const double height = 70;
  const Color red = Color(0xFFC10230);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

  final fill = Paint()..color = red;
  final headCenter = Offset(width / 2, 25);

  canvas.drawCircle(headCenter, 20, fill);

  final tip = Path()
    ..moveTo(width / 2, height - 2)
    ..lineTo(width / 2 - 14, 40)
    ..lineTo(width / 2 + 14, 40)
    ..close();
  canvas.drawPath(tip, fill);

  canvas.drawCircle(
    headCenter,
    8,
    Paint()..color = Colors.white,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

class MapViewScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? addressName;

  const MapViewScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.addressName,
  });

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  static const String _markerId = 'ticket_location';
  static const String _markerStyleId = 'ticket_marker_style';

  LatLng get _eventPosition => LatLng(
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

  Future<void> _onMapCreated(KakaoMapController controller) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final markerBytes = await _createRedMarkerBytes();

    await controller.registerMarkerStyles(
      styles: [
        MarkerStyle(
          styleId: _markerStyleId,
          perLevels: [
            MarkerPerLevelStyle.fromBytes(bytes: markerBytes),
          ],
        ),
      ],
    );
    await controller.addMarkerLayer(
      layerId: KakaoMapController.defaultLabelLayerId,
      zOrder: 1000,
      clickable: false,
    );
    await controller.addMarker(
      markerOption: MarkerOption(
        id: _markerId,
        latLng: _eventPosition,
        rank: 9999,
        styleId: _markerStyleId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 25,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          '행사 위치',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEDE3)),
          Expanded(
            child: KakaoMap(
              onMapCreated: _onMapCreated,
              initialPosition: _eventPosition,
              initialLevel: 17,
            ),
          ),
          if (widget.placeName != null || widget.addressName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEDE3))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.placeName != null &&
                      widget.placeName!.isNotEmpty) ...[
                    Text(
                      widget.placeName!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (widget.addressName != null &&
                      widget.addressName!.isNotEmpty)
                    Text(
                      widget.addressName!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
