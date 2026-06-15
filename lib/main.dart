import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'services/session_service.dart';
import 'services/fcm_service.dart';
import 'services/sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/map_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/safe_zones_screen.dart';
import 'screens/profile_screen.dart';
import 'services/location_service.dart';
import 'utils/navigator_key.dart';

// ✅ Background task name
const String backgroundSyncTask = 'floodsense_background_sync';

// ✅ Background task handler — runs even when app is closed
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundSyncTask) {
      print('🔄 Background sync running...');
      await SyncService.syncAll();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM
  await FCMService().initialize();

  // Initialize background sync
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Register background sync task — runs every 30 minutes
  await Workmanager().registerPeriodicTask(
    backgroundSyncTask,
    backgroundSyncTask,
    frequency: const Duration(minutes: 30),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FloodSense',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a3a5c),
        ),
        useMaterial3: true,
      ),
      home: const _SplashRouter(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/map': (context) => const MapScreen(),
        '/alerts': (context) => const AlertsScreen(),
        '/safe-zones': (context) => const SafeZonesScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// ✅ Splash screen — checks session + pre-fetches all data
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  String _statusMessage = 'Starting...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

Future<void> _initialize() async {
  setState(() => _statusMessage = 'Syncing data...');
  await SyncService.syncAll();

  // ✅ Request and save location
  setState(() => _statusMessage = 'Getting location...');
  await LocationService.requestAndSaveLocation();

  setState(() => _statusMessage = 'Loading...');
  await Future.delayed(const Duration(milliseconds: 300));

  final isLoggedIn = await SessionService.isLoggedIn();

  if (mounted) {
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a5c),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FloodSense',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Flood early warning · Sri Lanka',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}