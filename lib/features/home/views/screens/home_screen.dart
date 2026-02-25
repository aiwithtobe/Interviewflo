import 'package:dtc6464/core/common/styles/global_text_style.dart';
import 'package:dtc6464/core/utils/constants/colors.dart';
import 'package:dtc6464/core/utils/constants/icon_path.dart';
import 'package:dtc6464/features/background/views/widgets/background.dart';
import 'package:dtc6464/features/home/model/progress_model.dart';
import 'package:dtc6464/features/home/model/recent_activity_model.dart';
import 'package:dtc6464/features/home/model/resumed_questions_model.dart';
import 'package:dtc6464/features/home/views/widgets/quick_action.dart';
import 'package:dtc6464/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/utils/helpers/app_helper.dart';
import '../../../practice/views/screens/ai_coach_mode.dart';
import '../../controller/home_screen_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final HomeScreenController controller = Get.find<HomeScreenController>();
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // show loading screen
      if (controller.isInitializing.value) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.softBlueNormal),
            ),
          ),
        );
      }

      // show error screen
      if (controller.isInitError.value) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Something went wrong'),
                  ElevatedButton(
                    onPressed: controller.retryInit,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          controller.getTodayTips();
          controller.getProTips();
          controller.getResumeInterview();
          controller.getRecentActivity();
          controller.getProgress();
        },
        child: Background(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: Size(double.maxFinite, 80.h),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                title: Text(
                  'Welcome back!',
                  style: getTextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.softPurpleDarker,
                  ),
                ),
                actions: [
                  InkWell(
                    onTap: () => Get.toNamed(AppRoute.viewNotificationsScreen),
                    child: Image.asset(IconPath.notification),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: Size(double.maxFinite, 30.h),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'Ready to ace your next interview?',
                      style: getTextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.softPurpleDarkerHover,
                      ),
                    ).paddingOnly(left: 16.w),
                  ),
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  40.verticalSpace,

                  // Quick Actions
                  QuickAction(),

                  20.verticalSpace,

                  // resumed task
                  Obx(() {
                    final bool isLoading =
                        controller.isResumeInterviewLoading.value;
                    final resumedModel = controller.resumedQuestions.value;
                    final bool isError =
                        controller.isResumeInterviewError.value;

                    // 1. Handle Error State
                    if (isError) {
                      return _buildErrorWidget(
                        title: 'Resumed task',
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFD0F1FF), Color(0xFFB3E8FF)],
                        ),
                      );
                    }

                    // // 2. Handle Loading (If no data yet)
                    // if (isLoading && resumedModel == null) {
                    //   return const Center(child: CircularProgressIndicator());
                    // }

                    // 3. Handle Empty/Null Data
                    if (resumedModel == null ||
                        resumedModel.data.hasResume == false) {
                      // If not loading and no data, show error/empty state
                      if (!isLoading) {
                        return _buildErrorWidget(
                          title: 'Resumed task',
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFD0F1FF), Color(0xFFB3E8FF)],
                          ),
                        );
                      }
                    }

                    // 4. Success State
                    return Skeletonizer(
                      enabled: isLoading,
                      child: Practice(
                        data:
                            resumedModel?.data ??
                            controller.getResumedPlaceholderData(),
                      ),
                    );
                  }),

                  20.verticalSpace,

                  // progress
                  Obx(() {
                    final bool isLoading = controller.isProgressLoading.value;
                    final progress = controller.progress.value;

                    if (controller.isProgressError.value) {
                      return _buildErrorWidget(
                        title: 'Progress',
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter, // 0%
                          end: Alignment.bottomCenter, // 100%
                          colors: [Color(0xFFFFDDC8), Color(0xFFFFECC3)],
                        ),
                      );
                    }
                    return Skeletonizer(
                      enabled: isLoading,
                      child: Progress(
                        data:
                            progress ??
                            controller.getProgressPlaceholderData(),
                      ),
                    );
                  }),

                  20.verticalSpace,

                  // recent activity
                  Obx(() {
                    if (controller.isRecentActivityError.value) {
                      return _buildErrorWidget(
                        title: 'Recent Activity',
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter, // 0%
                          end: Alignment.bottomCenter, // 100%
                          colors: [Color(0xFFFFD4D9), Color(0xFFFFC8E3)],
                        ),
                      );
                    }

                    final bool isLoading =
                        controller.isRecentActivityLoading.value;

                    final List<Datum> activities = isLoading
                        ? controller.getRecentActivityPlaceholderData()
                        : (controller.recentActivity.value?.data ?? []);

                    return Skeletonizer(
                      enabled: isLoading,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: getTextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),

                          12.verticalSpace,
                          Column(
                            children: activities.map((e) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14.r),
                                  color: Colors.white,
                                ),

                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.softPurpleNormal,
                                          size: 18.h,
                                        ),
                                        10.horizontalSpace,
                                        Expanded(
                                          child: Text(
                                            e.title,
                                            overflow: TextOverflow.ellipsis,
                                            style: getTextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors
                                                  .softPurpleNormalHover,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    4.verticalSpace,

                                    Text(
                                      e.timeAgo,
                                      style: getTextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.lightGreyNormal,
                                      ),
                                    ).paddingOnly(left: 27.w),

                                    7.verticalSpace,

                                    Text(
                                      'Behavioral Questions - Score:${e.score ?? 0}%',
                                      style: getTextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF555556),
                                      ),
                                    ).paddingOnly(left: 27.w),
                                  ],
                                ),
                              ).paddingOnly(bottom: 10.h);
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),

                  20.verticalSpace,

                  // today's tips
                  Obx(() {
                    final bool isLoading =
                        controller.isTodayTipsLoading.value;
                    final bool isError = controller.isTodayTipsError.value;
                    final bool hasData =
                        controller.todayTipsData.value != null;

                    if (isLoading) {
                      return _buildSkeletonContent(true);
                    }

                    if (isError && !hasData) {
                      return _buildErrorWidget(
                        title: 'Today\'s Tips',
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter, // 0%
                          end: Alignment.bottomCenter, // 100%
                          colors: [Color(0xFFDFD3FD), Color(0xFFCED3FF)],
                        ),
                      );
                    }

                    return _buildSkeletonContent(false);
                  }),

                  60.verticalSpace,
                ],
              ).paddingSymmetric(horizontal: 16.w),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSkeletonContent(bool enabled) {
    return Skeletonizer(
      enabled: enabled,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC8B4DC).withOpacity(0.12),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFC7EEFF), Color(0xFFDFF5FF)],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48.h,
              width: 48.w,
              padding: EdgeInsets.all(10.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                IconPath.bulb,
                color: AppColors.softBlueNormal,
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Tip",
                    style: getTextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A4A6A),
                    ),
                  ),
                  5.verticalSpace,
                  Text(
                    enabled
                        ? "Loading Topic Name..."
                        : controller.todayTipsData.value!.data.topic,
                    style: getTextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4A4A6A),
                    ),
                  ),
                  8.verticalSpace,
                  Text(
                    enabled
                        ? "This is a placeholder for the tip content which will load shortly from the server."
                        : controller.todayTipsData.value!.data.tip,
                    style: getTextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B6B8A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget({
    required String title,
    required LinearGradient gradient,
  }) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: gradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: getTextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),

          20.verticalSpace,

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 25.sp,
                  color: Colors.red,
                ),

                10.verticalSpace,

                Text(
                  "No data found",
                  style: getTextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Pull to refresh",
                  style: getTextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 80.w),
        ],
      ),
    );
  }
}

class Practice extends StatelessWidget {
  Practice({super.key, required this.data});
  final Data data;
  final controller = Get.find<HomeScreenController>();
  @override
  Widget build(BuildContext context) {
    double progressPercentage = data.totalQuestions > 0
        ? (data.answeredCount / data.totalQuestions)
        : 0.0;

    int percentageText = (progressPercentage * 100).toInt();
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA896E6).withOpacity(0.15),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.205, 0.8352],
          colors: [Color(0xFFF6F3FF), Color(0xFFE5DDFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue Practice',
            style: getTextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A4A6A),
            ),
          ),

          7.verticalSpace,

          Text(
            'You left off at: Behavioral Interview - Question ${data.answeredCount} of ${data.totalQuestions}',
            style: getTextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF4A4A6A),
            ),
          ),

          12.verticalSpace,

          Stack(
            children: [
              Container(
                height: 8.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  color: Colors.white,
                ),
              ),

              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 8.h,
                    width: constraints.maxWidth * progressPercentage,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: const Color(0xFFA896E6),
                    ),
                  );
                },
              ),
            ],
          ),

          12.verticalSpace,

          Text(
            '$percentageText% Complete',
            style: getTextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B6B8A),
            ),
          ),

          12.verticalSpace,

          GestureDetector(
            onTap: () {
              controller.getResumedQuestions(context);
              AppHelperFunctions.navigateToScreen(context, AiCoachMode());
            },
            child: Container(
              height: 45.h,
              width: double.maxFinite,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                gradient: const LinearGradient(
                  begin: Alignment(-0.7, -0.8), // Approx 114 degrees
                  end: Alignment(0.7, 0.8),
                  colors: [
                    Color(0xFFA78BFA), // #A78BFA (15.41%)
                    Color(0xFF5835C0), // #5835C0 (84.59%)
                  ],
                  stops: [0.1541, 0.8459],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Resume Session',
                    style: getTextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  5.horizontalSpace,

                  Image.asset(IconPath.arrowRightFilled, width: 18.w),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Progress extends StatelessWidget {
  const Progress({super.key, required this.data});

  final ProgressModel data;

  @override
  Widget build(BuildContext context) {
    final item = data.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: getTextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        12.verticalSpace,

        Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.476, 1.0],
              colors: [Color(0xFF5A6BFF), Color(0xFF7A86FF), Color(0xFF8A5CF6)],
            ),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      item.yourScore.toString(),
                      style: getTextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    5.verticalSpace,

                    Text(
                      'Your Score',
                      style: getTextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.white, width: 2.w),
                    right: BorderSide(color: Colors.white, width: 2.w),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "${item.avgScore.toStringAsFixed(2)}%",
                      style: getTextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    5.verticalSpace,

                    Text(
                      'Avg Score',
                      style: getTextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      item.streak.toString(),
                      style: getTextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    5.verticalSpace,

                    Text(
                      'Streak',
                      style: getTextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
