import 'package:dtc6464/core/services/storage_service.dart';
import 'package:dtc6464/core/utils/constants/image_path.dart';
import 'package:dtc6464/features/background/views/widgets/background.dart';
import 'package:dtc6464/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (StorageService.isFirstTimer == null ||
        StorageService.isFirstTimer == false) {
      Get.offAllNamed(AppRoute.getOnboardingScreen1());
    } else if (StorageService.hasToken()) {
      Get.offAllNamed(AppRoute.getBottomNavBar());
    } else {
      Get.offAllNamed(AppRoute.getOnboardingScreen2());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Background(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // logo
              Image.asset(ImagePath.logo, width: 120.w),

              30.verticalSpace,
              // text logo
              Image.asset(ImagePath.textLogo, width: 191.w),
            ],
          ),
        ),
      ),
    );
  }
}
