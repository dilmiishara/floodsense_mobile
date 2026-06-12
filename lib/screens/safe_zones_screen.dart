import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/safe_location.dart';
import '../services/safe_location_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class SafeZonesScreen extends StatefulWidget {
  const SafeZonesScreen({super.key});

  @override
  State<SafeZonesScreen> createState() => _SafeZonesScreenState();
}

class _SafeZonesScreenState extends State<SafeZonesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SafeLocationService _service = SafeLocationService();
  String _searchQuery = '';
  List<SafeLocation> _safeLocations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSafeLocations();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openGoogleMaps(
      double latitude, double longitude, String name) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_place_name=$name&travelmode=driving',
    );
    final Uri fallbackUri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude($name)',
    );
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri);
    }
  }

  Future<void> _fetchSafeLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final locations = await _service.getSafeLocations();
      setState(() {
        _safeLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load locations. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<SafeLocation> get _filteredLocations {
    if (_searchQuery.isEmpty) return _safeLocations;
    return _safeLocations.where((loc) {
      return loc.locationName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          loc.locationType
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          loc.district
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('school') || t.contains('educational')) {
      return Icons.school_rounded;
    } else if (t.contains('hospital') || t.contains('medical')) {
      return Icons.local_hospital_rounded;
    } else if (t.contains('temple') || t.contains('religious')) {
      return Icons.temple_buddhist_rounded;
    } else if (t.contains('government') || t.contains('secretariat')) {
      return Icons.account_balance_rounded;
    } else if (t.contains('ground') || t.contains('park')) {
      return Icons.park_rounded;
    } else {
      return Icons.location_on_rounded;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Slightly darker background
      backgroundColor: const Color(0xFFE8ECF0),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            if (!_isLoading && _errorMessage == null) _buildSummaryRow(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                // ✅ Bold prominent title
                Text(
                  'Safe Zones',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D2137),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Evacuation centres & shelters',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchSafeLocations,
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0D2137)),
        decoration: InputDecoration(
          hintText: 'Search by name, type or district...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[400],
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[400],
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFE8ECF0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1a3a5c),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _buildSummaryChip(
            Icons.location_on_rounded,
            '${_safeLocations.length} locations',
            const Color(0xFF1a3a5c),
            const Color(0xFFDCE8F5),
          ),
          const SizedBox(width: 10),
          _buildSummaryChip(
            Icons.check_circle_rounded,
            '${_filteredLocations.length} showing',
            const Color(0xFF2D6A0A),
            const Color(0xFFD4EDBA),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1a3a5c)),
      );
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (_filteredLocations.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _filteredLocations.length,
      itemBuilder: (context, index) {
        return _buildLocationCard(_filteredLocations[index]);
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D2137),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchSafeLocations,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D2137),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching with different keywords',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(SafeLocation location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // ✅ Stronger shadow for card depth
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
          // ✅ Card header with colored left border accent
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: const Color(0xFF3B6D11),
                  width: 4,
                ),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4EDBA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(location.locationType),
                    color: const Color(0xFF2D6A0A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Location name — bold and dark
                      Text(
                        location.locationName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0D2137),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // ✅ Type — lighter secondary text
                      Text(
                        location.locationType,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3B6D11),
                        ),
                      ),
                    ],
                  ),
                ),
                // Directions button
                GestureDetector(
                  onTap: () => _openGoogleMaps(
                    location.latitude,
                    location.longitude,
                    location.locationName,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a3a5c),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Go',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ Card details section with divider
          if (location.address.isNotEmpty ||
              location.maxCapacity != null ||
              location.contactNumber != null)
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
                  // Address
                  if (location.address.isNotEmpty)
                    _buildDetailRow(
                      Icons.location_on_rounded,
                      location.address,
                      Colors.grey[600]!,
                    ),
                  // Capacity
                  if (location.maxCapacity != null)
                    _buildDetailRow(
                      Icons.people_rounded,
                      'Capacity: ${location.maxCapacity} people',
                      Colors.grey[600]!,
                    ),
                  // Phone
                  if (location.contactNumber != null)
                    GestureDetector(
                      onTap: () =>
                          _makePhoneCall(location.contactNumber!),
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EDBA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 13,
                              color: Color(0xFF2D6A0A),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              location.contactNumber!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D6A0A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '· tap to call',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF3B6D11),
                              ),
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
  }

  Widget _buildDetailRow(IconData icon, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
      IconData icon, String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}