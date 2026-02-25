import 'dart:convert';

import 'package:dtc6464/core/utils/constants/colors.dart';
import 'package:dtc6464/core/utils/constants/icon_path.dart';
import 'package:dtc6464/core/utils/logging/logger.dart';
import 'package:dtc6464/features/collect_info/model/ai_brief_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/services/network_caller.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/constants/api_constants.dart';
import '../../../core/utils/constants/snackbar_constant.dart';
import '../../../routes/app_routes.dart';

class CollectInfoController extends GetxController {
  final NetworkCaller _networkCaller = Get.find<NetworkCaller>();
  RxInt currentPageIndex = 0.obs;
  // text controllers
  final TextEditingController roleController = TextEditingController();
  final TextEditingController rolePreparingController = TextEditingController();
  final TextEditingController interviewingCompanyController =
      TextEditingController();
  final TextEditingController jobDescriptionController =
      TextEditingController();

  RxString searchText = ''.obs;

  // upload loading
  RxBool isUploading = false.obs;

  // The list of companies
  final List<String> companies = [
    'Google',
    'Facebook',
    'Amazon',
    'Netflix',
    'Apple',
    'Microsoft',
    'Shopify',
    'Spotify',
    'Startup',
  ];

  // Reactive list to store selected items
  var selectedCompanies = <String>[].obs;

  void addCustomCompany(TextEditingController textController) {
    final name = textController.text.trim();
    if (name.isEmpty) return;
    if (!companies.contains(name)) {
      companies.add(name);
    }
    if (!selectedCompanies.contains(name)) {
      selectedCompanies.add(name);
    }
    textController.clear();
    searchText.value = ''; // add this
  }

  void toggleSelection(String name) {
    if (selectedCompanies.contains(name)) {
      selectedCompanies.remove(name);
    } else {
      selectedCompanies.add(name);
    }
  }

  // List of levels
  final List<String> levels = ['Beginner', 'Intermediate', 'Advanced'];

  // ai breaf data
  Rx<AiBriefModel?> aiBriefData = Rx<AiBriefModel?>(null);

  // Reactive variable for the selected level (initially Beginner)
  RxString selectedLevel = 'Beginner'.obs;

  void selectLevel(String level) {
    selectedLevel.value = level;
  }

  final List<String> goals = [
    'Improve behavioral answers',
    'Boost interview confidence',
    'Strengthen technical skills',
    'Track my progress',
    'Master STAR method',
    'Prepare for promotion',
    'Improve system design',
    'Prepare for upcoming interview',
  ].obs;

  final List<String> goalsIcon = [
    IconPath.star,
    IconPath.mic,
    IconPath.brain,
    IconPath.grow,
    IconPath.puzzle,
    IconPath.rocket,
    IconPath.gear,
    IconPath.bag,
  ];

  // Using a set or list to allow multiple selection
  var selectedGoals = <String>[].obs;

  void toggleGoal(String goal) {
    if (selectedGoals.contains(goal)) {
      // If it's already selected, always allow removing it
      selectedGoals.remove(goal);
    } else {
      // Only add if the current count is less than 3
      if (selectedGoals.length < 3) {
        selectedGoals.add(goal);
      } else {
        // Optional: Show a message to the user
        Get.snackbar(
          "Limit Reached",
          "You can only select up to 3 goals",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.softPurpleDarker,
          colorText: AppColors.whiteLight,
          margin: EdgeInsets.all(15.w),
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        );
      }
    }
  }

  // weak areas
  final List<String> areas = [
    'Interview anxiety',
    'STAR structure',
    'Long answers',
    'Lack metrics',
    'System design',
    'Technical depth',
    'Thinking Of examples',
    'Filler words',
  ].obs;

  final List<String> areasIcon = [
    IconPath.anxiety,
    IconPath.crown,
    IconPath.noteBook,
    IconPath.human,
    IconPath.monitor,
    IconPath.monitorSetting,
    IconPath.pencil,
    IconPath.speaker,
  ].obs;

  // Using a set or list to allow multiple selection
  var selectedAreas = <String>[].obs;

  void toggleArea(String area) {
    if (selectedAreas.contains(area)) {
      selectedAreas.remove(area);
    } else {
      selectedAreas.add(area);
    }
  }

  var resumes = <int, ResumeModel?>{1: null, 2: null, 3: null}.obs;

  // Logic to check if at least one resume exists
  bool get hasAtLeastOneResume => resumes.values.any((file) => file != null);

  Future<void> pickResume(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      final fileSizeMB = file.size / 1024 / 1024;
      if (fileSizeMB > 5) {
        Get.snackbar(
          "File Too Large",
          "Please upload a file smaller than 5MB",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.softPurpleDarker,
          colorText: AppColors.whiteLight,
        );
        return;
      }


      // Conversion logic as before...
      resumes[index] = ResumeModel(
        name: file.name,
        size: "${(file.size / 1024 / 1024).toStringAsFixed(1)} MB",
        path: file.path ?? '',
      );
    }
  }

  void validateAndNext(PageController pageController) {
    String errorMessage = "";

    // Check which page the user is currently on
    switch (currentPageIndex.value) {
      case 0:
        if (roleController.text.trim().isEmpty) {
          errorMessage = "Please enter your current role";
        }
      case 1: // Roles & Company TextFields
        if (rolePreparingController.text.trim().isEmpty)
          errorMessage = "Please enter the role you are preparing for";
        break;

      case 2: // Company Selection (Chips)
        if (selectedCompanies.isEmpty)
          errorMessage = "Please select at least one company";
        break;

      case 3: // Experience Level (Always has Beginner selected, but safe to check)
        if (selectedLevel.value.isEmpty)
          errorMessage = "Please select your experience level";
        break;

      case 4: // Career Goals (Must be exactly 3)
        if (selectedGoals.length < 3)
          errorMessage = "Please select 3 career goals to continue";
        break;

      case 5: // Weak Areas
        if (selectedAreas.isEmpty)
          errorMessage = "Please select at least one area to improve";
        break;

      case 6:
        if (jobDescriptionController.text.trim().isEmpty)
          errorMessage = "Please write job description";
        break;
      case 7: // Resume Upload
        if (!hasAtLeastOneResume)
          errorMessage = "Please upload at least one resume";
        break;
    }

    // If there is an error message, show the snackbar and STOP
    if (errorMessage.isNotEmpty) {
      Get.snackbar(
        "Required Information",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.softPurpleDarker,
        colorText: AppColors.whiteLight,
        margin: EdgeInsets.all(15.w),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
    } else {
      pageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }


  Future<void> analyzeProfile() async {
    try {
      isUploading.value = true;

      final Map<String, String> body = {
        'currentRole': roleController.text.trim(),
        'targetRole': rolePreparingController.text.trim(),
        'experienceLevel': selectedLevel.value,
        'jobDescription': jobDescriptionController.text.trim(),
        'targetCompany': jsonEncode(selectedCompanies),
        'careerGoals': jsonEncode(selectedGoals),
        'weakAreas': jsonEncode(selectedAreas),
        'strengths': jsonEncode([]),
      };

      List<String> resumePaths = resumes.values
          .where((resume) => resume != null)
          .map((resume) => resume!.path)
          .toList();

      final response = await _networkCaller.postMultipartRequest(
        ApiConstant.baseUrl + ApiConstant.analyze,
        fields: body,
        filePaths: resumePaths,
      );

      if (response.isSuccess) {
        aiBriefData.value = AiBriefModel.fromJson(response.responseData);
        await StorageService.saveUserProfileId(aiBriefData.value!.data.userProfileId);
        SnackBarConstant.success(title: "Success", message: "Profile analyzed successfully!");
        Get.offAllNamed(AppRoute.getAiBriefScreen());
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Error', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(response.errorMessage, style: const TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(15),
            duration: const Duration(seconds: 3),
          ),
        );
        Get.back();
      }
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Error', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text(e.toString(), style: const TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(15),
          duration: const Duration(seconds: 3),
        ),
      );
      Get.back();
    } finally {
      isUploading.value = false;
    }
  }


}

class ResumeModel {
  final String name;
  final String size;
  final String path;

  ResumeModel({required this.name, required this.size, required this.path});
}
