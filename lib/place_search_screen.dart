import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    // 초기 화면에서 검색 안내 문구가 보이도록 _isSearchActive를 true로 설정
    _isSearchActive = true;
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;

    final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeQueryComponent(query)}');
    print('Request URL: $url');

    final response = await http.get(url, headers: {
      'Authorization': 'KakaoAK ${dotenv.env['KAKAO_REST_API_KEY']}',
    });

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      setState(() {
        _places = List<Map<String, dynamic>>.from(decodedData['documents']);
        _isSearchActive = true;
      });
    } else {
      print('Failed to load places');
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
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
            const Divider(
              // ⭐ 앱바 아래에 Divider 추가
              height: 1,
              thickness: 1,
              color: Color(0xFFEEEDE3),
            ),
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
                  onTap: () {
                    setState(() {
                      _isSearchActive = true;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '장소 검색',
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
                  onSubmitted: (value) {
                    _searchPlace(value);
                  },
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isSearchActive
                  ? (_places.isNotEmpty
                      ? ListView.builder(
                          itemCount: _places.length,
                          itemBuilder: (context, index) {
                            final place = _places[index];
                            return InkWell(
                              onTap: () {
                                Navigator.pop(context, place);
                              },
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
                                    horizontal: 16.0, vertical: 12.0),
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
                      : Center(
                          child: Text(
                            _searchController.text.isNotEmpty
                                ? '검색 결과가 없습니다.'
                                : '장소, 주소, 도로명을 검색해주세요.',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ))
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
