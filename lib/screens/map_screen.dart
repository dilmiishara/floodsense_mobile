import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedStation;

  final List<Map<String, dynamic>> _stations = [
    {
      'name': 'Rathnapura',
      'lat': 6.6828,
      'lng': 80.3992,
      'risk': 'High',
      'waterLevel': 28.5,
      'rainfall': 220,
      'alertLevel': 'Major Flood',
      'affectedArea': 120.0,
    },
    {
      'name': 'Ellagawa',
      'lat': 6.7167,
      'lng': 80.2833,
      'risk': 'Medium',
      'waterLevel': 11.2,
      'rainfall': 163,
      'alertLevel': 'Minor Flood',
      'affectedArea': 45.0,
    },
    {
      'name': 'Putupaula',
      'lat': 6.6500,
      'lng': 80.4500,
      'risk': 'Medium',
      'waterLevel': 3.8,
      'rainfall': 95,
      'alertLevel': 'Alert',
      'affectedArea': 30.0,
    },
    {
      'name': 'Millakanda',
      'lat': 6.7500,
      'lng': 80.3500,
      'risk': 'Low',
      'waterLevel': 4.2,
      'rainfall': 78,
      'alertLevel': 'Normal',
      'affectedArea': 0.0,
    },
  ];

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'High':
        return const Color(0xFFE24B4A);
      case 'Medium':
        return const Color(0xFFBA7517);
      case 'Low':
        return const Color(0xFF3B6D11);
      default:
        return Colors.grey;
    }
  }

  Color _getRiskBgColor(String risk) {
    switch (risk) {
      case 'High':
        return const Color(0xFFFCEBEB);
      case 'Medium':
        return const Color(0xFFFAEEDA);
      case 'Low':
        return const Color(0xFFEAF3DE);
      default:
        return Colors.grey[100]!;
    }
  }

  // Calculate radius from affected area (sq km)
  double _getRadius(double areaSqKm) {
    if (areaSqKm <= 0) return 0;
    return sqrt(areaSqKm * 1000000 / pi);
  }

  bool _isFlooding(String risk) => risk != 'Low' && risk != 'Normal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF0),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Affected Areas Map',
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
                ],
              ),
            ),

            // ── Map ──────────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(6.7056, 80.3847),
                      initialZoom: 11.0,
                      onTap: (_, __) =>
                          setState(() => _selectedStation = null),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.floodsense_mobile',
                      ),

                      // ── Affected area circles ─────────────────────────
                      CircleLayer(
                        circles: _stations
                            .where((s) => _isFlooding(s['risk']))
                            .map((s) {
                          final color = _getRiskColor(s['risk']);
                          return CircleMarker(
                            point: LatLng(s['lat'], s['lng']),
                            radius: _getRadius(
                                (s['affectedArea'] as double)),
                            useRadiusInMeter: true,
                            color: color.withOpacity(0.18),
                            borderColor: color.withOpacity(0.6),
                            borderStrokeWidth: 2,
                          );
                        }).toList(),
                      ),

                      // ── Station markers ───────────────────────────────
                      MarkerLayer(
                        markers: _stations.map((station) {
                          final isSelected =
                              _selectedStation?['name'] ==
                                  station['name'];
                          return Marker(
                            point: LatLng(
                                station['lat'], station['lng']),
                            width: isSelected ? 48 : 38,
                            height: isSelected ? 48 : 38,
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _selectedStation = station),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: _getRiskColor(station['risk']),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white,
                                    width: isSelected ? 3 : 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRiskColor(
                                              station['risk'])
                                          .withOpacity(
                                              isSelected ? 0.6 : 0.35),
                                      blurRadius: isSelected ? 14 : 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.water_drop_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // ── Legend ────────────────────────────────────────────
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
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          _buildLegendItem(
                              'Major Flood', const Color(0xFFE24B4A)),
                          _buildLegendItem(
                              'Minor Flood', const Color(0xFFBA7517)),
                          _buildLegendItem(
                              'Normal', const Color(0xFF3B6D11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Station cards panel ───────────────────────────────────────
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
                  // Panel title
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Station Status',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D2137),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8ECF0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_stations.length} stations',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Horizontal scrollable station cards
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      itemCount: _stations.length,
                      itemBuilder: (context, index) {
                        final station = _stations[index];
                        final risk = station['risk'] as String;
                        final isSelected =
                            _selectedStation?['name'] ==
                                station['name'];

                        return GestureDetector(
                          onTap: () {
                            setState(
                                () => _selectedStation = station);
                            _mapController.move(
                              LatLng(station['lat'],
                                  station['lng']),
                              12.0,
                            );
                          },
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            width: 160,
                            margin: const EdgeInsets.only(right: 10),
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
                                  color: Colors.black
                                      .withOpacity(
                                          isSelected ? 0.08 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
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
                                        station['name'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              const Color(0xFF0D2137),
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
                                        risk,
                                        style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  station['alertLevel'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: _getRiskColor(risk),
                                  ),
                                ),
                                const Spacer(),
                                // Details row
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.water,
                                      size: 11,
                                      color: Color(0xFF185FA5),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${station['waterLevel']}m',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            const Color(0xFF0D2137),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.grain,
                                      size: 11,
                                      color: Color(0xFF185FA5),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${station['rainfall']}mm',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            const Color(0xFF0D2137),
                                      ),
                                    ),
                                  ],
                                ),
                                if (station['affectedArea'] > 0) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.crop_free_rounded,
                                        size: 11,
                                        color: _getRiskColor(risk),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${station['affectedArea']} sq km',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _getRiskColor(risk),
                                        ),
                                      ),
                                    ],
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
}