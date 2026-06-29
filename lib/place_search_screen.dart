import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart' as kakao_maps;
import 'package:passtime/map_picker_screen.dart';
import 'package:passtime/utils/kakao_local_service.dart';

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  _PlaceSearchScreenState createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  late KakaoMapController mapController;
  final TextEditingController _searchController = TextEditingController();
  final List<Marker> _markers = [];
  final List<Polygon> _polygons = [];
  final List<Circle> _circles = [];
  final List<CustomOverlay> _customOverlays = [];
  final List<Polyline> _polylines = [];
  List<Map<String, dynamic>> _places = [];
  bool _isSearchActive = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _isSearchActive = true;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _isSearchActive = true;
    });

    final places = await KakaoLocalService.searchPlaces(query);

    if (!mounted) return;
    setState(() {
      _places = places;
      _isSearching = false;
    });
  }

  Future<void> _openMapPicker({String? query}) async {
    kakao_maps.LatLng? initialPosition;
    String? initialAddress;
    String? initialPlaceName;

    if (query?.trim().isNotEmpty == true) {
      final trimmedQuery = query!.trim();
      initialPlaceName = trimmedQuery;
      final place = await KakaoLocalService.geocodeAddress(trimmedQuery);
      if (place != null) {
        initialPosition = kakao_maps.LatLng(
          latitude: double.parse(place['y'].toString()),
          longitude: double.parse(place['x'].toString()),
        );
        initialAddress =
            place['address_name']?.toString() ?? place['place_name']?.toString();
      }
    }

    if (!mounted) return;

    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialPosition: initialPosition,
          initialPlaceName: initialPlaceName,
          initialAddress: initialAddress,
        ),
      ),
    );

    if (selected != null && mounted) {
      Navigator.pop(context, selected);
    }
  }

  void _onMapCreated(KakaoMapController controller) {
    mapController = controller;
  }

  void _onBackPress() {
    if (_isSearchActive && _searchController.text.isNotEmpty) {
      setState(() {
        _isSearchActive = false;
        _places = [];
        _searchController.clear();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildDirectSelectActions(String query) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Text(
            query.isNotEmpty ? '검색 결과가 없습니다.' : '장소, 주소, 도로명을 검색해주세요.',
            style: TextStyle(
              color: Colors.black.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => _openMapPicker(query: query),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF334D61)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  '"$query" 주소로 지도에서 위치 지정',
                  style: const TextStyle(
                    color: Color(0xFF334D61),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
            onPressed: _onBackPress,
          ),
          centerTitle: true,
          title: const Text(
            '장소 검색',
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
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF334D61).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: TextField(
                  controller: _searchController,
                  onTap: () => setState(() => _isSearchActive = true),
                  decoration: InputDecoration(
                    hintText: '장소, 주소, 도로명 검색',
                    hintStyle: TextStyle(
                      color: Colors.black.withOpacity(0.3),
                      fontSize: 16,
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF999999)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel,
                                color: Color(0xFF999999)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _places = [];
                                _isSearchActive = true;
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                  ),
                  onSubmitted: _searchPlace,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isSearchActive
                  ? (_isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : (_places.isNotEmpty
                          ? ListView.builder(
                              itemCount: _places.length,
                              itemBuilder: (context, index) {
                                final place = _places[index];
                                return InkWell(
                                  onTap: () => Navigator.pop(context, place),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFEFEFEF),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 12.0,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Color(0xFF4C87F4),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                place['place_name'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF282727),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                place['address_name'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6F6F6F),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : _buildDirectSelectActions(query)))
                  : KakaoMap(
                      currentLevel: 5,
                      onMapCreated: _onMapCreated,
                      markers: _markers,
                      polygons: _polygons,
                      circles: _circles,
                      customOverlays: _customOverlays,
                      polylines: _polylines,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
