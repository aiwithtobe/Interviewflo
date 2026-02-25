import 'package:dtc6464/core/services/network_caller.dart';
import 'package:dtc6464/core/services/storage_service.dart';
import 'package:dtc6464/core/utils/constants/api_constants.dart';
import 'package:dtc6464/core/utils/helpers/app_helper.dart';
import 'package:dtc6464/features/nav_screens/profile/edit/views/screens/edit_profile_screen.dart';
import 'package:dtc6464/features/nav_screens/profile/history/views/screens/history_screen.dart';
import 'package:dtc6464/features/nav_screens/profile/notifications/views/screens/notifications_screen.dart';
import 'package:dtc6464/routes/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/constants/snackbar_constant.dart';
import '../model/profile_model.dart';

class ProfileController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    getProfile();
  }
  final NetworkCaller _networkCaller = Get.find<NetworkCaller>();
  Rx<String> userName = 'Loading Name...'.obs;
  Rx<String> userAvatar = ''.obs;

  RxBool isProfileLoading = false.obs;
  RxBool isProfileError = false.obs;
  Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);

  Future<void> getProfile() async {
    try {
      isProfileLoading.value = true;
      isProfileError.value = false;

      final response = await _networkCaller.getRequest(
        ApiConstant.baseUrl + ApiConstant.profile,
        token: StorageService.accessToken,
      );

      // Fixed logic: Check for response success instead of the data itself
      if (!response.isSuccess) {
        isProfileError.value = true;
        SnackBarConstant.errorThin(title: 'Failed', message: response.errorMessage);
        return;
      }

      final model = ProfileModel.fromJson(response.responseData);
      profile.value = model;

      // Update UI observables
      userName.value = model.data!.profile!.fullName;
      userAvatar.value = "https://api.datatechcon.com${model.data!.profile!.profilePicture!.fileUrl}";
      isProfileLoading.value = false;
      isProfileError.value = false;
    } catch (e) {
      isProfileError.value = true;
      SnackBarConstant.errorThin(title: 'Error', message: e.toString());
    } finally {
      isProfileLoading.value = false;
    }
  }

  Future<void> logout() async {
    await StorageService.logoutUser();
    Get.offAllNamed(AppRoute.getSignInScreen());
    SnackBarConstant.errorThin(title: 'Success', message: 'Logged out');
  }

  void navigateToStatistics() {
    Get.toNamed(AppRoute.statisticsScreen);
  }

  void navigateToNotifications(BuildContext context) {
    AppHelperFunctions.navigateToScreen(context, NotificationsScreen());
  }

  void navigateToHistory(BuildContext context) {
    AppHelperFunctions.navigateToScreen(context, HistoryScreen());
  }

  void navigateToEditProfile(BuildContext context) {
    AppHelperFunctions.navigateToScreen(context, EditProfileScreen());
  }
}
