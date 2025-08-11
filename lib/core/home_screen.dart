import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:student_helper/core/nami/screens/nami_main.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:student_helper/core/ai_query_solver/screens/ai_query_solver.dart';
import 'package:student_helper/core/common/screens/work_in_progress.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> features = [
      {
        "title": "AI Query Solver",
        "icon": Icons.auto_awesome,
        "screen": () => const AiQuerySolver(),
      },
      {
        "title": "Assignments",
        "icon": Icons.assignment,
        "screen":() => WorkInProgressScreen(title: "Assignments"),
      },
      {
        "title": "Timetable",
        "icon": Icons.schedule,
        "screen": () => WorkInProgressScreen(title: "Timetable"),
      },
      {
        "title": "Results",
        "icon": Icons.bar_chart,
        "screen": () => WorkInProgressScreen(title: "Results"),
      },
      {
        "title": "Clubs",
        "icon": Icons.group,
        "screen": () => WorkInProgressScreen(title: "Clubs"),
      },
      {
        "title": "Events",
        "icon": Icons.event,
        "screen": () => WorkInProgressScreen(title: "Events"),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surfaceDim,
        title: Text(
          "Student Helper",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withAlpha(222),
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withAlpha(204),
              theme.colorScheme.surfaceDim,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Personal Campus Guide",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(222),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 20.sp,
                    color: theme.colorScheme.onSurface.withAlpha(222),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                height: 180.h,
                width: 350.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface.withAlpha(178),
                      theme.colorScheme.surface.withAlpha(77),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(51),
                    width: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 4.h,
                      left: 20.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "NAMI",
                            style:  GoogleFonts.exo2(
                              color: theme.colorScheme.secondary.withAlpha(235),
                              fontSize: 50.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(
                            width: 200.w,
                            child: Text(
                              "Your friendly compass through every path of campus life",
                              style:  GoogleFonts.exo2(
                                color: theme.colorScheme.secondary.withAlpha(222),
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -20.w,
                      bottom: -16.h,
                      child: Lottie.asset(
                        'assets/lottie/gps_navigation.json',
                        width: 200,
                        height: 200,
                        repeat: true,
                      ),
                    ),
                  ],
                ),
              ).onTap((){
                Get.to(() => NamiMain());
              }),
              SizedBox(height: 24.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Learning Assistance",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(222),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 20.sp,
                    color: theme.colorScheme.onSurface.withAlpha(222),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: GridView.builder(
                  itemCount: features.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 1.45,
                  ),
                  itemBuilder: (context, index) {
                    final feature = features[index];
                    return VxBox(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            feature['icon'],
                            size: 32.sp,
                            color: theme.colorScheme.onSurface.withAlpha(200),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            feature['title'],
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ).centered(),
                    )
                        .withGradient(LinearGradient(
                          colors: [
                            theme.colorScheme.surface.withAlpha(178),
                            theme.colorScheme.surface.withAlpha(77),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ))
                        .border(
                          color: theme.colorScheme.primary.withAlpha(51),
                          width: .2,
                        )
                        .rounded
                        .make()
                        .onTap(() {
                      Get.to(feature['screen']);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
