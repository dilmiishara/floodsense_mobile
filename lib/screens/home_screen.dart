import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/alert_service.dart';
import '../services/safe_location_service.dart';
import '../services/session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlertService _alertService = AlertService();
  final SafeLocationService _safeLocationService = SafeLocationService();

  int _activeAlertsCount = 0;
  int _safeLocationsCount = 0;
  bool _summaryLoading = true;
  String? _userName;

  final List<Map<String, dynamic>> _stations = [
    {
      'name': 'Rathnapura',
      'waterLevel': 28.5,
      'rainfall': 220,
      'risk': 'High',
      'alertLevel': 'Major Flood',
      'threshold': 9.5,
    },
    {
      'name': 'Ellagawa',
      'waterLevel': 11.2,
      'rainfall': 163,
      'risk': 'Medium',
      'alertLevel': 'Minor Flood',
      'threshold': 10.7,
    },
    {
      'name': 'Putupaula',
      'waterLevel': 3.8,
      'rainfall': 95,
      'risk': 'Medium',
      'alertLevel': 'Alert',
      'threshold': 4.0,
    },
    {
      'name': 'Millakanda',
      'waterLevel': 4.2,
      'rainfall': 78,
      'risk': 'Low',
      'alertLevel': 'Normal',
      'threshold': 6.5,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchSummaryCounts();
    _loadUserName();
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
      final alerts = await _alertService.getActiveAlerts();
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

  IconData _getRiskIcon(String risk) {
    switch (risk) {
      case 'High':
        return Icons.warning_rounded;
      case 'Medium':
        return Icons.info_rounded;
      case 'Low':
        return Icons.check_circle_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final highRiskCount =
        _stations.where((s) => s['risk'] == 'High').length;
    final hasHighRisk = highRiskCount > 0;

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
                  // Logo + Title + Greeting
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
                  // Action buttons
                  Row(
                    children: [
                      // Notification bell
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
                                  color: Color(0xFFE24B4A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // ✅ Round profile icon
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

            // Scrollable content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Warning Banner
                  if (hasHighRisk)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCEBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE24B4A).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_rounded,
                              color: Color(0xFFE24B4A),
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
                                    '$highRiskCount station(s) at high risk — take precautions',
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
                          // Active Alerts card
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/alerts'),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCEBEB),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE24B4A)
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
                                        color: Color(0xFFE24B4A),
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
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 6),
                                                  child: _AnimatedDots(
                                                    color: Color(0xFFE24B4A),
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
                                              color: const Color(0xFFA32D2D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 12,
                                      color: Color(0xFFE24B4A),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Safe Locations card
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
                                                  padding: EdgeInsets.symmetric(
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
                                              color: const Color(0xFF3B6D11),
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
                          Text(
                            'Updated just now',
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
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final station = _stations[index];
                        final risk = station['risk'] as String;
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
                              // Card header with colored left border
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 14, 16, 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: _getRiskColor(risk),
                                      width: 4,
                                    ),
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _getRiskBgColor(risk),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _getRiskIcon(risk),
                                            color: _getRiskColor(risk),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              station['name'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0D2137),
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            Text(
                                              station['alertLevel'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: _getRiskColor(risk),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRiskColor(risk),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        risk,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Card body
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 10, 16, 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFBFC),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8ECF0),
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Water Level',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                                Text(
                                                  '${station['waterLevel']}m',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
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
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Rainfall',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                                Text(
                                                  '${station['rainfall']}mm',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
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
                              ),
                            ],
                          ),
                        );
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
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  final Color color;

  const _AnimatedDots({
    this.color = const Color(0xFFE24B4A),
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