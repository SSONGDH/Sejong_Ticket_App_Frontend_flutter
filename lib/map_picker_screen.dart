import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import 'package:passtime/utils/kakao_local_service.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialPlaceName;
  final String? initialAddress;

  const MapPickerScreen({
    super.key,
    this.initialPosition,
    this.initialPlaceName,
    this.initialAddress,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _defaultPosition = LatLng(
    latitude: 37.550946,
    longitude: 126.972317,
  );

  StreamSubscription<CameraMoveEndEvent>? _cameraSubscription;
  late LatLng _selectedPosition;
  String _addressText = '지도를 움직여 위치를 선택하세요';
  bool _isResolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition ?? _defaultPosition;
    _addressText = widget.initialAddress ??
        widget.initialPlaceName ??
        '지도를 움직여 위치를 선택하세요';
  }

  @override
  void dispose() {
    _cameraSubscription?.cancel();
    super.dispose();
  }

  Future<void> _resolveAddress(LatLng position) async {
    setState(() => _isResolvingAddress = true);
    final address = await KakaoLocalService.coordToAddress(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted) return;
    setState(() {
      _addressText = address;
      _isResolvingAddress = false;
    });
  }

  void _onMapCreated(KakaoMapController controller) {
    _cameraSubscription =
        controller.onCameraMoveEndStream.listen((_) async {
      final center = await controller.getCenter();
      if (center == null || !mounted) return;
      setState(() => _selectedPosition = center);
      await _resolveAddress(center);
    });

    _resolveAddress(_selectedPosition);
  }

  void _confirmSelection() {
    final placeName = widget.initialPlaceName?.trim().isNotEmpty == true
        ? widget.initialPlaceName!.trim()
        : _addressText;

    Navigator.pop(
      context,
      KakaoLocalService.buildCustomPlace(
        placeName: placeName,
        addressName: _addressText,
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
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
          '위치 선택',
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
            child: Stack(
              children: [
                KakaoMap(
                  onMapCreated: _onMapCreated,
                  initialPosition: _selectedPosition,
                  initialLevel: 17,
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(
                      Icons.location_on,
                      color: Color(0xFFC10230),
                      size: 42,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '지도를 움직여 핀 위치를 맞춰주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.65),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEEEDE3)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '선택 위치',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _isResolvingAddress
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _addressText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334D61),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      '이 위치로 선택',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
