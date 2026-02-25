import 'package:dtc6464/core/services/network_caller.dart';
import 'package:dtc6464/features/home/model/notifications_model.dart' hide Datum;
import 'package:dtc6464/features/home/model/progress_model.dart' hide Data;
import 'package:dtc6464/features/home/model/recent_activity_model.dart';
import 'package:dtc6464/features/home/model/resumed_questions_model.dart';
import 'package:dtc6464/features/home/model/today_tips_model.dart' hide Data;
import 'package:dtc6464/features/practice/controller/practice_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/utils/constants/api_constants.dart';
import '../../../core/utils/constants/snackbar_constant.dart';
import '../../../core/utils/logging/logger.dart';
import '../../../routes/app_routes.dart';
import '../../practice/model/question_model.dart' hide Data;
import '../model/pro_tips_model.dart' hide Data;

class HomeScreenController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _initializeScreen();
  }

  final NetworkCaller _networkCaller = Get.find<NetworkCaller>();
  final PracticeController controller = Get.find<PracticeController>();

  RxBool isInitializing = true.obs; // screen loading flag
  RxBool isInitError = false.obs;
  RxBool isTodayTipsLoading = false.obs;
  RxBool isTodayTipsError = false.obs;
  RxBool isProTipsLoading = false.obs;
  RxBool isProTipsError = false.obs;
  RxBool isResumeInterviewLoading = false.obs;
  RxBool isResumeInterviewError = false.obs;
  RxBool isRecentActivityLoading = false.obs;
  RxBool isRecentActivityError = false.obs;
  RxBool isProgressLoading = false.obs;
  RxBool isProgressError = false.obs;
  RxBool isNotificationLoading = false.obs;
  RxBool isNotificationError = false.obs;


  Rx<TodayTipsModel?> todayTipsData = Rx<TodayTipsModel?>(null);
  Rx<ProTipsModel?> proTipsData = Rx<ProTipsModel?>(null);
  Rx<ResumedQuestionsModel?> resumedQuestions = Rx<ResumedQuestionsModel?>(null);
  Rx<RecentActivityModel?> recentActivity = Rx<RecentActivityModel?>(null);
  Rx<ProgressModel?> progress = Rx<ProgressModel?>(null);
  Rx<NotificationsModel?> notifications = Rx<NotificationsModel?>(null);

  Future<void> _initializeScreen() async {
    try {
      isInitializing.value = true;
      isInitError.value = false;

      // 1st: get current refresh token from storage
      final currentRefreshToken = StorageService.refreshToken;

      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        Get.offAllNamed(AppRoute.getOnboardingScreen2());
        return;
      }

      // 2nd: call the token refresh API to get fresh tokens
      final response = await _networkCaller.postRequest(
        ApiConstant.baseUrl + ApiConstant.token,
        body: {'refreshToken': currentRefreshToken},
      );

      if (!response.isSuccess) {
        // token is invalid/expired → go to login
        await StorageService.logoutUser();
        Get.offAllNamed(AppRoute.getOnboardingScreen2());
        return;
      }

      // 3rd: save new tokens
      final data = response.responseData['data'];
      await StorageService.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'] ?? currentRefreshToken,
        userId: StorageService.userId ?? '',
      );

      isInitializing.value = false;
      isInitError.value = false;

      AppLoggerHelper.debug('Tokens refreshed successfully on home init');

      // 4th: now run all fetches in parallel with fresh token
      await Future.wait([
        getTodayTips(),
        getProTips(),
        getResumeInterview(),
        getRecentActivity(),
        getProgress(),
      ]);

    } catch (e) {
      isInitError.value = true;
      AppLoggerHelper.error('Init Error: $e');
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> retryInit() async {
    await _initializeScreen();
  }

  Future<void> getTodayTips() async {
    try {
      isTodayTipsLoading.value = true;
      final token = StorageService.accessToken;
      final response = await _networkCaller.getRequest(
        ApiConstant.baseUrl + ApiConstant.todayTips,
        token: token,
      );

      if (!response.isSuccess) {
        isTodayTipsLoading.value = false;
        isTodayTipsError.value = true;
        SnackBarConstant.errorThin(title: 'Failed', message: response.errorMessage);
        return;
      }

      todayTipsData.value = TodayTipsModel.fromJson(response.responseData);
      isTodayTipsLoading.value = false;
      isTodayTipsError.value = false;
    } catch (e) {
      isTodayTipsLoading.value = false;
      isTodayTipsError.value = true;
      AppLoggerHelper.error(e.toString());
      SnackBarConstant.errorThin(title: 'Failed', message: e.toString());
    } finally {
      isTodayTipsLoading.value = false;
    }
  }

  Future<void> getProTips() async {
    try {
      isProTipsLoading.value = true;
      final token = StorageService.accessToken;
      final response = await _networkCaller.getRequest(
        ApiConstant.baseUrl + ApiConstant.proTips,
        token: token,
      );

      if (!response.isSuccess) {
        isProTipsLoading.value = false;
        isProTipsError.value = true;
        SnackBarConstant.errorThin(title: 'Failed', message: response.errorMessage);
        return;
      }

      proTipsData.value = ProTipsModel.fromJson(response.responseData);
      isProTipsLoading.value = false;
      isProTipsError.value = false;
    } catch (e) {
      isProTipsLoading.value = false;
      isProTipsError.value = true;
      AppLoggerHelper.error(e.toString());
      SnackBarConstant.errorThin(title: 'Failed', message: e.toString());
    } finally {
      isProTipsLoading.value = false;
    }
  }

  Future<void> getResumeInterview() async {
    try {
      isResumeInterviewLoading.value = true;
      isResumeInterviewError.value = false;

      final token = StorageService.accessToken;
      // Check if token is null early
      if (token == null || token.isEmpty) {
        throw Exception("Access token is missing");
      }

      final response = await _networkCaller.getRequest(
        "${ApiConstant.baseUrl}${ApiConstant.resumeInterview}",
        token: token,
      );

      print('Data: ${response.responseData}');

      if (!response.isSuccess || response.responseData == null) {
        isResumeInterviewError.value = true;
        SnackBarConstant.errorThin(
            title: 'Failed',
            message: response.errorMessage ?? "Unknown error"
        );
        return;
      }

      resumedQuestions.value = ResumedQuestionsModel.fromJson(response.responseData);
      isResumeInterviewError.value = false;
    } catch (e) {
      isResumeInterviewError.value = true;
      AppLoggerHelper.error("Resume Interview Error: $e");
    } finally {
      isResumeInterviewLoading.value = false;
    }
  }

  Future<void> getResumedQuestions(BuildContext context) async {
    try {
      controller.resetData();
      controller.isStartPracticeLoading.value = true;
      final token = StorageService.accessToken;
      final response = await _networkCaller.getRequest(
        ApiConstant.baseUrl + ApiConstant.resumedQuestions + resumedQuestions.value!.data.sessionId,
        token: token,
      );
      if (response.isSuccess) {
        controller.questions.value = QuestionsModel.fromJson(response.responseData);
      } else {
        SnackBarConstant.errorThin(title: 'Failed', message: response.errorMessage);
        Navigator.pop(context);
      }
    } catch (e) {
      controller.isStartPracticeLoading.value = false;
      AppLoggerHelper.error(e.toString());
      SnackBarConstant.errorThin(title: 'Error', message: e.toString());
      Navigator.pop(context);
    } finally {
      controller.isStartPracticeLoading.value = false;
    }
  }

  Future<void> getRecentActivity() async {
    try {
      isRecentActivityLoading.value = true;
      isRecentActivityError.value = false;
      final token = StorageService.accessToken;
      final response = await _networkCaller.getRequest(
        ApiConstant.baseUrl + ApiConstant.recentActivity,
        token: token,
      );

      if(!response.isSuccess) {
        isRecentActivityLoading.value = false;
        isRecentActivityError.value = true;
        SnackBarConstant.errorThin(title: 'Failed', message: response.errorMessage);
        return;
      }

      recentActivity.value = RecentActivityModel.fromJson(response.responseData);
      isRecentActivityLoading.value = false;
      isRecentActivityError.value = false;
    } catch (e) {
      isRecentActivityLoading.value = false;
      isRecentActivityError.value = true;
      AppLoggerHelper.error(e.toString());
      SnackBarConstant.errorThin(title: 'Failed', message: e.toString());
    } finally {
      isRecentActivityLoading.value = false;
    }
  }

  Future<void> getProgress() async {
    try {
      isProgressLoading.value = true;
      isProgressError.value = false;
      final token = StorageService.accessToken;
      final response = await _networkCaller.getRequest(
        ApiConstant.baseUrl + ApiConstant.progress,
        token: token,
      );

      if(!response.isSuccess) {
        isProgressLoading.value = false;
        isProgressError.value = true;
        SnackBarConstant.errorThin(title: 'Failed', message: response.errorMessage);
        return;
      }

      progress.value = ProgressModel.fromJson(response.responseData);
      isProgressLoading.value = false;
      isProgressError.value = false;
    } catch (e) {
      isProgressLoading.value = false;
      isProgressError.value = true;
      AppLoggerHelper.error(e.toString());
      SnackBarConstant.errorThin(title: 'Failed', message: e.toString());
    } finally {
      isProgressLoading.value = false;
    }
  }

  Future<void> getNotification() async {
    try {
      isNotificationLoading.value = true;
      isNotificationError.value = false;
      final token = StorageService.accessToken;
      final response = await _networkCaller.getRequest(
        ApiConstant.baseUrl + ApiConstant.notifications,
        token: token,
      );

      if(!response.isSuccess) {
        isNotificationLoading.value = false;
        isNotificationError.value = true;
        SnackBarConstant.errorThin(title: 'Failed', message: response.errorMessage);
        return;
      }

      notifications.value = NotificationsModel.fromJson(response.responseData);
      isNotificationLoading.value = false;
      isNotificationError.value = false;
    } catch (e) {
      isNotificationLoading.value = false;
      isNotificationError.value = true;
      AppLoggerHelper.error(e.toString());
      SnackBarConstant.errorThin(title: 'Failed', message: e.toString());
    } finally {
      isNotificationLoading.value = false;
    }
  }


  Data getResumedPlaceholderData() {
    return Data(
      hasResume: false,
      sessionId: "",
      type: "Loading...",
      category: "Loading...",
      answeredCount: 0,
      totalQuestions: 10,
      status: "active",
      updatedAt: DateTime.now(),
    );
  }

  List<Datum> getRecentActivityPlaceholderData() {
    return List.generate(3, (index) => Datum(
      id: "$index",
      title: 'Some',
      subtitle: "some",
      score: 0,
      timeAgo: "Loading...",
      answeredCount: 0,
      totalQuestions: 10,
    ));
  }

  ProgressModel getProgressPlaceholderData() {
    return ProgressModel(
      success: false,
      message: "Loading...",
      data: Datam(
        yourScore: 0,
        avgScore: 0.0,
        streak: 0,
      ),
    );
  }
}
