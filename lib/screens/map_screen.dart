import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../services/prediction_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'dart:ui' as ui;
import '../services/connectivity_service.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final PredictionService _predictionService = PredictionService();

  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _selectedStation;
  DateTime? _lastUpdated;
  bool _isOffline = false;

  // Fixed coordinates for each station
  final Map<String, List<double>> _stationCoords = {
    'Ellagawa':   [6.730, 80.213],
    'Putupaula':  [6.612, 80.060],
    'Rathnapura': [6.690, 80.380],
  };

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

Future<void> _loadPredictions() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  try {
    final online = await ConnectivityService.isOnline();
    setState(() => _isOffline = !online);

    final data = await _predictionService.getLatestPredictions();
    if (mounted) {
      setState(() {
        _predictions = data;
        _isLoading = false;
        _lastUpdated = DateTime.now();
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _errorMessage = 'Could not load predictions';
        _isLoading = false;
      });
    }
  }
}

Color _getRiskColor(String? risk) {
  switch ((risk ?? '').toLowerCase()) {
    case 'major flood':
      return const Color(0xFFEF4444);
    case 'minor flood':
      return const Color(0xFFF97316);
    case 'alert':
      return const Color(0xFFEAB308);
    case 'normal':
      return const Color(0xFF22C55E);
    default:
      return Colors.grey;
  }
}

Color _getRiskBgColor(String? risk) {
  switch ((risk ?? '').toLowerCase()) {
    case 'major flood':
      return const Color(0xFFFEF2F2);
    case 'minor flood':
      return const Color(0xFFFFF7ED);
    case 'alert':
      return const Color(0xFFFEFCE8);
    case 'normal':
      return const Color(0xFFF0FDF4);
    default:
      return Colors.grey[100]!;
  }
}

  bool _isFlooding(String? risk) {
    final r = (risk ?? '').toLowerCase();
    return r == 'major flood' || r == 'minor flood' || r == 'alert';
  }

  double _getRadius(dynamic areaSqKm) {
    if (areaSqKm == null) return 0;
    final area = double.tryParse(areaSqKm.toString()) ?? 0.0;
    if (area <= 0) return 0;
    return sqrt(area * 1000000 / pi);
  }

  String _formatForecastTime(String? forecastTime) {
    if (forecastTime == null) return '—';
    try {
      final dt = DateTime.parse(forecastTime).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day.toString().padLeft(2,'0')} ${months[dt.month-1]}, '
             '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (e) {
      return forecastTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get forecast time from first prediction
    final forecastTime = _predictions.isNotEmpty
        ? _formatForecastTime(_predictions[0]['forecast_time']?.toString())
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF0),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECF0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF1a3a5c),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Predicted Flood Area',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D2137),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Kalu Ganga Basin · Rathnapura',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: _loadPredictions,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECF0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF1a3a5c),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Offline banner
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFF1a3a5c),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Offline — map tiles unavailable, showing cached data',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Forecast time bar ─────────────────────────────────────
            if (forecastTime != null && !_isLoading)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Color(0xFF185FA5),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Forecast Time',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        forecastTime,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF185FA5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Map ──────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1a3a5c)),
                    )
                  : _errorMessage != null
                      ? _buildErrorState()
                      : Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: const LatLng(6.7056, 80.3847),
                                initialZoom: 11.0,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                                ),
                                onTap: (_, __) => setState(
                                    () => _selectedStation = null),
                              ),
                              children: [
                                FutureBuilder(
                                  future: getApplicationDocumentsDirectory(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return const SizedBox();
                                    final cacheStore = HiveCacheStore(
                                      snapshot.data!.path,
                                      hiveBoxName: 'flutter_map_cache',
                                    );
                                    return TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.floodsense_mobile',
                                      tileProvider: CachedTileProvider(
                                        store: cacheStore,
                                      ),
                                    );
                                  },
                                ),

                                // Affected area circles
                                CircleLayer(
                                  circles: _predictions
                                      .where((s) => _isFlooding(
                                          s['flood_risk_level']
                                              ?.toString()))
                                      .where((s) => _stationCoords
                                          .containsKey(s['station_name']))
                                      .map((s) {
                                    final color = _getRiskColor(
                                        s['flood_risk_level']?.toString());
                                    final coords = _stationCoords[
                                        s['station_name']]!;
                                    return CircleMarker(
                                      point:
                                          LatLng(coords[0], coords[1]),
                                      radius: _getRadius(
                                          s['affected_area_sqkm']),
                                      useRadiusInMeter: true,
                                      color: color.withOpacity(0.18),
                                      borderColor:
                                          color.withOpacity(0.6),
                                      borderStrokeWidth: 2,
                                    );
                                  }).toList(),
                                ),

                                // Station markers
                                MarkerLayer(
                                  markers: _predictions
                                      .where((s) => _stationCoords
                                          .containsKey(s['station_name']))
                                      .map((station) {
                                    final coords = _stationCoords[
                                        station['station_name']]!;
                                    final risk = station['flood_risk_level']
                                        ?.toString();
                                    final isSelected =
                                        _selectedStation?['station_name'] ==
                                            station['station_name'];
                                    return Marker(
                                      point: LatLng(coords[0], coords[1]),
                                      width: isSelected ? 90 : 80,
                                      height: isSelected ? 80 : 70,
                                      child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Station name label
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1a3a5c),
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.25),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            station['station_name']?.toString() ?? '',
                                            style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        // Pin circle
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: isSelected ? 38 : 30,
                                          height: isSelected ? 38 : 30,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _getRiskColor(risk),
                                              width: isSelected ? 3.5 : 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                    isSelected ? 0.35 : 0.25),
                                                blurRadius: isSelected ? 16 : 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.sensors_rounded,
                                            color: _getRiskColor(risk),
                                            size: isSelected ? 20 : 16,
                                          ),
                                        ),
                                        // Triangle pointer
                                        CustomPaint(
                                          size: const Size(12, 6),
                                          painter: _TrianglePainter(
                                            color: _getRiskColor(risk),
                                          ),
                                        ),
                                      ],
                                    ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),

                            // Legend
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LEGEND',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[500],
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildLegendItem('Major Flood', const Color(0xFFEF4444)),
                                    _buildLegendItem('Minor Flood', const Color(0xFFF97316)),
                                    _buildLegendItem('Alert',       const Color(0xFFEAB308)),
                                    _buildLegendItem('Normal',      const Color(0xFF22C55E)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
            ),

            // ── Station cards panel ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Station Status',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D2137),
                          ),
                        ),
                        if (_lastUpdated != null)
                          Text(
                            'Updated ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Horizontal scrollable station cards
                  SizedBox(
                    height: 118,
                    child: _predictions.isEmpty
                        ? Center(
                            child: Text(
                              'No predictions available',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            itemCount: _predictions.length,
                            itemBuilder: (context, index) {
                              final station = _predictions[index];
                              final risk = station['flood_risk_level']
                                  ?.toString();
                              final coords = _stationCoords[
                                  station['station_name']];
                              final isSelected =
                                  _selectedStation?['station_name'] ==
                                      station['station_name'];

                              return GestureDetector(
                                onTap: () {
                                  setState(
                                      () => _selectedStation = station);
                                  if (coords != null) {
                                    _mapController.move(
                                      LatLng(coords[0], coords[1]),
                                      12.5,
                                    );
                                  }
                                },
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  width: 165,
                                  margin:
                                      const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _getRiskBgColor(risk)
                                        : const Color(0xFFFAFBFC),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border(
                                      left: BorderSide(
                                        color: _getRiskColor(risk),
                                        width: 4,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                            isSelected ? 0.08 : 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(11),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name + badge
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              station['station_name']
                                                      ?.toString() ??
                                                  '',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(
                                                    0xFF0D2137),
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getRiskColor(risk),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              risk ?? 'Normal',
                                              style: GoogleFonts.poppins(
                                                fontSize: 7,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Water level
                                      _buildCardRow(
                                        Icons.water,
                                        'Water',
                                        '${station['predicted_water_level'] ?? '-'}m',
                                        const Color(0xFF185FA5),
                                      ),
                                      const SizedBox(height: 3),
                                      // Rainfall
                                      _buildCardRow(
                                        Icons.grain,
                                        'Rain',
                                        '${station['rainfall'] ?? '-'}mm',
                                        const Color(0xFF185FA5),
                                      ),
                                      // Affected area
                                      if ((double.tryParse(station['affected_area_sqkm']?.toString() ?? '0') ?? 0.0) > 0.0) ...
                                      [
                                        const SizedBox(height: 3),
                                        _buildCardRow(
                                          Icons.crop_free_rounded,
                                          'Area',
                                          '${double.tryParse(station['affected_area_sqkm']?.toString() ?? '0')?.toStringAsFixed(1) ?? '0'} km²',
                                          _getRiskColor(risk),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildCardRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D2137),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Could not load predictions',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPredictions,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a3a5c),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}