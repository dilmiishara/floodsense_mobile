import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/prediction_alert_service.dart';
import '../services/safe_location_service.dart';
import '../services/session_service.dart';
import '../services/water_level_service.dart';
import '../services/location_service.dart';
import '../services/connectivity_service.dart';
import '../models/water_level_log.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ✅ Add WidgetsBindingObserver for foreground detection
class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final PredictionAlertService _alertService = PredictionAlertService();
  final SafeLocationService _safeLocationService = SafeLocationService();
  final WaterLevelService _waterLevelService = WaterLevelService();

  int _activeAlertsCount = 0;
  int _safeLocationsCount = 0;
  bool _summaryLoading = true;
  bool _stationsLoading = true;
  bool _isOffline = false;
  String? _userName;
  List<WaterLevelLog> _stations = [];
  String? _lastUpdated;

  @override
  void initState() {
    super.initState();
    // ✅ Register observer for foreground detection
    WidgetsBinding.instance.addObserver(this);
    _fetchSummaryCounts();
    _loadUserName();
    _fetchStations();
  }

  @override
  void dispose() {
    // ✅ Remove observer when screen disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ Trigger 2 — Foreground detection
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📍 App came to foreground — updating location');
      // Update location silently when app comes to foreground
      LocationService.requestAndSaveLocation();
      // Also refresh data
      _fetchStations();
      _fetchSummaryCounts();
    }
  }

  Future<void> _loadUserName() async {
    final user = await SessionService.getUser();
    if (user != null && mounted) {
      setState(() {
        _userName = (user['name'] as String).split(' ')[0];
      });
    }
  }

  Future<void> _fetchSummaryCounts() async {
    try {
      final alerts = await _alertService.getPredictionAlerts();
      final locations = await _safeLocationService.getSafeLocations();
      if (mounted) {
        setState(() {
          _activeAlertsCount = alerts.length;
          _safeLocationsCount = locations.length;
          _summaryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summaryLoading = false;
        });
      }
    }
  }

  Future<void> _fetchStations() async {
    final online = await ConnectivityService.isOnline();
    setState(() => _isOffline = !online);

    try {
      final stations = await _waterLevelService.getLatestPerStation();
      if (mounted) {
        setState(() {
          _stations = stations;
          _stationsLoading = false;
          if (stations.isNotEmpty) {
            _lastUpdated = _formatTime(stations[0].recordedAt);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _stationsLoading = false);
      }
    }
  }

  // ✅ Trigger 3 — Pull to refresh
  Future<void> _onRefresh() async {
    print('🔄 Pull to refresh — updating location and data');
    // Update location
    await LocationService.requestAndSaveLocation();
    // Refresh all data
    await Future.wait([
      _fetchStations(),
      _fetchSummaryCounts(),
    ]);
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (e) {
      return '';
    }
  }

  String _formatSourceTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}, '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'MAJOR FLOOD':
        return const Color(0xFFEF4444);
      case 'MINOR FLOOD':
        return const Color(0xFFF97316);
      case 'ALERT':
        return const Color(0xFFEAB308);
      case 'NORMAL':
        return const Color(0xFF22C55E);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'MAJOR FLOOD':
        return const Color(0xFFFEF2F2);
      case 'MINOR FLOOD':
        return const Color(0xFFFFF7ED);
      case 'ALERT':
        return const Color(0xFFFEFCE8);
      case 'NORMAL':
        return const Color(0xFFF0FDF4);
      default:
        return Colors.grey[100]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'MAJOR FLOOD':
        return Icons.warning_rounded;
      case 'MINOR FLOOD':
        return Icons.water_rounded;
      case 'ALERT':
        return Icons.info_rounded;
      case 'NORMAL':
        return Icons.check_circle_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasHighRisk = _stations.any(
      (s) => s.alertStatus.toUpperCase() != 'NORMAL',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF0),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a3a5c),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FloodSense',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D2137),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            _userName != null
                                ? 'Hello, $_userName 👋'
                                : 'Flood early warning',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/alerts'),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8ECF0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFF1a3a5c),
                                size: 20,
                              ),
                            ),
                          ),
                          if (hasHighRisk)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/profile'),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1a3a5c),
                            shape: BoxShape.circle,
                          ),
                          child: _userName != null
                              ? Center(
                                  child: Text(
                                    _userName!
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
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
                      'You are offline — showing cached data',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // ✅ Scrollable content with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFF1a3a5c),
                child: CustomScrollView(
                  slivers: [
                    // Warning Banner
                    if (hasHighRisk && !_stationsLoading)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_rounded,
                                color: Color(0xFFEF4444),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Flood Warning Active',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF791F1F),
                                      ),
                                    ),
                                    Text(
                                      'One or more stations at elevated risk',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: const Color(0xFFA32D2D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Summary Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/alerts'),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444)
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.notifications_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _summaryLoading
                                                ? const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 6),
                                                    child: _AnimatedDots(
                                                      color: Color(0xFFEF4444),
                                                    ),
                                                  )
                                                : Text(
                                                    '$_activeAlertsCount',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                          0xFF791F1F),
                                                    ),
                                                  ),
                                            Text(
                                              'Active Alerts',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color:
                                                    const Color(0xFFA32D2D),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 12,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, '/safe-zones'),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF3DE),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF3B6D11)
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.shield_rounded,
                                          color: Color(0xFF3B6D11),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _summaryLoading
                                                ? const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 6),
                                                    child: _AnimatedDots(
                                                      color: Color(0xFF3B6D11),
                                                    ),
                                                  )
                                                : Text(
                                                    '$_safeLocationsCount',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                          0xFF27500A),
                                                    ),
                                                  ),
                                            Text(
                                              'Safe Locations',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color:
                                                    const Color(0xFF3B6D11),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 12,
                                        color: Color(0xFF3B6D11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Section title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Flood Risk Status',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (_lastUpdated != null)
                              Text(
                                'Updated $_lastUpdated',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Station cards
                    _stationsLoading
                        ? const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1a3a5c),
                                ),
                              ),
                            ),
                          )
                        : _stations.isEmpty
                            ? SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Text(
                                      'No station data available',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final station = _stations[index];
                                    return _buildStationCard(station);
                                  },
                                  childCount: _stations.length,
                                ),
                              ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildStationCard(WaterLevelLog station) {
    final status = station.alertStatus;
    final change = station.waterLevelChange;
    final isRising = station.isRising;
    final isFalling = station.isFalling;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _getStatusColor(status),
                  width: 4,
                ),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.stationName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D2137),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          station.riverName,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isRising || isFalling)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isRising
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isRising
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 14,
                              color: isRising
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isRising ? 'Rising' : 'Falling',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isRising
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Card body
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8ECF0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.water,
                              size: 16,
                              color: Color(0xFF185FA5),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Water Level',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Text(
                                  '${station.waterLevel.toStringAsFixed(2)}m',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0D2137),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8ECF0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.grain,
                              size: 16,
                              color: Color(0xFF185FA5),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rainfall',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Text(
                                  '${station.rainfallMm.toStringAsFixed(1)}mm',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0D2137),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          change >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: change >= 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}m from previous',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: change >= 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Data: ${_formatSourceTime(station.recordedAt)}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  final Color color;

  const _AnimatedDots({
    this.color = const Color(0xFFEF4444),
  });

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}