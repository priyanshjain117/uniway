import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiQuerySolver extends StatelessWidget {
  const AiQuerySolver({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surfaceDim,
        title: Text(
          "AI Query Solver",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withAlpha(222),
            fontWeight: FontWeight.w500,
            fontSize: 24.sp,
          ),
        ),
        centerTitle: false,
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
              
            ],
          ),
        ),
      ),
  
    );
  }
}
