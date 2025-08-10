import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_dashboard_new.dart';
import 'screens/create_doctor_screen.dart';
import 'screens/doctor_schedule_screen.dart';
import 'screens/emergency_triage_screen.dart';
import 'screens/doctor_assignment_screen.dart';
import 'screens/hospital_duties_screen.dart';
import 'screens/my_plans_screen.dart';
import 'services/auth_service.dart';
import 'utils/admin_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase zaten başlatılmış mı kontrol et
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        print('✅ Firebase başarıyla başlatıldı');
      }
    } else {
      if (kDebugMode) {
        print('🔄 Firebase zaten başlatılmış');
      }
    }

    // Admin hesabını kontrol et ve oluştur
    await AdminSetup.createAdminIfNotExists();
  } catch (e) {
    if (kDebugMode) {
      print('❌ Firebase başlatma hatası: $e');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const HastaneAcilApp(),
    ),
  );
}

class HastaneAcilApp extends StatelessWidget {
  const HastaneAcilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hastane Acil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red.shade600,
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/register',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/admin-new': (context) => const AdminDashboard(),
        '/admin/create-doctor': (context) => const CreateDoctorScreen(),
        '/doctor-schedule': (context) => const DoctorScheduleScreen(),
        '/emergency-triage': (context) => const EmergencyTriageScreen(),
        '/doctor-assignment': (context) => const DoctorAssignmentScreen(),
        '/hospital-duties': (context) => const HospitalDutiesScreen(),
        '/my-plans': (context) => const MyPlansScreen(),
      },
    );
  }
}
