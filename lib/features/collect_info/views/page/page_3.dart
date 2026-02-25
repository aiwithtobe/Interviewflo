import 'package:dtc6464/core/common/styles/global_text_style.dart';
import 'package:dtc6464/core/common/widgets/custom_filled_button.dart';
import 'package:dtc6464/features/background/views/widgets/background.dart';
import 'package:dtc6464/features/collect_info/controller/collect_info_controller.dart';
import 'package:dtc6464/features/collect_info/views/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/utils/constants/colors.dart';
import '../widgets/selection_chip.dart';

class Page3 extends StatelessWidget {
  Page3({super.key, required this.pageController, required this.controller});

  final CollectInfoController controller;
  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    return Background(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              'Which company are you interviewing with?',
              style: getTextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.softPurpleDarker,
              ),
            ).paddingOnly(left: 26.w),

            20.verticalSpace,

            Obx(() => CustomTextField(
              controller: controller.interviewingCompanyController,
              hintText: "IT Company",
              suffixIcon: controller.searchText.value.trim().isNotEmpty
                  ? GestureDetector(
                onTap: () => controller.addCustomCompany(
                  controller.interviewingCompanyController,
                ),
                child: Icon(Icons.add, color: AppColors.softPurpleDarker),
              )
                  : SizedBox.shrink(),
              onChanged: (value) => controller.searchText.value = value,
            )),

            12.verticalSpace,

            Obx(
                  () => Wrap(
                spacing: 5.w,
                runSpacing: 15.h,
                children: controller.companies.map((company) {
                  final isSelected = controller.selectedCompanies.contains(company);
                  return SelectionChip(
                    label: company,
                    isSelected: isSelected,
                    onTap: () => controller.toggleSelection(company),
                  );
                }).toList(),
              ),
            ),
          ],
        ).paddingSymmetric(horizontal: 16.w),
      ),
    );
  }
}
