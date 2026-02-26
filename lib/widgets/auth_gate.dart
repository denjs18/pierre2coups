import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/firebase_auth_service.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/home_screen.dart';
import '../theme/app_theme.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    return StreamBuilder<AppUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplash();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        return const WelcomeScreen();
      },
    );
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentPrimary, width: 2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.gps_fixed,
                size: 64,
                color: AppTheme.accentPrimary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'PIERRE2COUPS',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'INITIALISATION...',
              style: TextStyle(
                color: AppTheme.accentPrimary,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppTheme.accentPrimary,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
