import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../core/app_theme.dart';
import '../services/menu_service.dart';
import '../services/offline/database_service.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Remove the native splash screen now that we are ready to show our custom one
    FlutterNativeSplash.remove();

    _syncData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  Future<void> _syncData() async {
    try {
      // Fetch latest data from Supabase
      final items = await MenuService.fetchAvailableItems();
      final tables = await MenuService.fetchTables();

      // Save to local cache
      await DatabaseService.saveMenuItems(items);
      await DatabaseService.saveTables(tables);
      
      print('Splash: Local cache updated successfully');
    } catch (e) {
      print('Splash: Sync failed (using existing cache): $e');
    } finally {
      // Ensure splash finishes even if sync fails
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) widget.onComplete();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Large Illustration
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: SvgPicture.asset(
                        'assets/splash.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bottom Content
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Catchy Typography
                Column(
                  children: [
                    const Text(
                      'NELLAI',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 48,
                        height: 0.9,
                        letterSpacing: -2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryYellow,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black,
                            offset: Offset(4, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'PUNJABI',
                        style: TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'RESTAURANT MANAGEMENT SYSTEM',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 3,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.black.withValues(alpha: 0.1),
                    color: AppColors.primaryYellow,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
