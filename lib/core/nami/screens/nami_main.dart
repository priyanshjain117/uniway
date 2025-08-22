import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:student_helper/core/nami/controllers/navigation_controller.dart';
import 'package:student_helper/core/nami/screens/admin_location.dart';
import 'package:student_helper/core/nami/widgets/location_inputs.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter/services.dart';

class NamiMain extends StatelessWidget {
  const NamiMain({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.put(NavigationController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: theme.colorScheme.surface,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary.withAlpha(160),
        title: Text(
          "NAMI",
          style: GoogleFonts.exo2(
            fontWeight: FontWeight.w700,
            fontSize: 26.sp,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
              onPressed: () {
                Get.to(()=>AdminLocationPage());
              },
              icon: Icon(
                Icons.admin_panel_settings,
                size: 32.sp,
              ))
        ],
      ),
      body: Column(
        children: [
          _buildLocationInput(navController),
          Expanded(
            child: Stack(
              children: [
                _buildMap(navController),
                _buildLoadingIndicators(navController),
                _buildErrorDisplay(navController),
                _buildNavigationUI(navController),
                _buildLocationButton(navController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationInfo(
      BuildContext context, String title, String name, String description,LatLng position) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, 
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: title.contains("From")
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        title.contains("From") ? Icons.flag : Icons.location_on,
                        color:
                            title.contains("From") ? Colors.green : Colors.red,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.exo2(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            name.isNotEmpty ? name : "Unknown Location",
                            style: GoogleFonts.exo2(
                              fontSize: 14.sp,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1.h,
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                color: Colors.grey.shade200,
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(20.w),
                  itemCount: _getLocationInfoItems(position,description).length,
                  itemBuilder: (context, index) {
                    final items = _getLocationInfoItems(position,description);
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: items[index],
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final coords =
                              "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
                          Clipboard.setData(ClipboardData(text: coords));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Copied to clipboard!")),
                          );
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.copy, size: 18.sp),
                        label: Text(
                          "Copy Coords",
                          style: GoogleFonts.exo2(fontSize: 14.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, size: 18.sp),
                        label: Text(
                          "Close",
                          style: GoogleFonts.exo2(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _getLocationInfoItems(LatLng position, String description) {
    return [
      _buildInfoCard(
        Get.context!,
        icon: Icons.gps_fixed,
        iconColor: Colors.blue,
        title: "Coordinates",
        children: [
          _buildInfoRow(
            Get.context!,
            label: "Latitude",
            value: "${position.latitude.toStringAsFixed(6)}°",
            icon: Icons.arrow_upward,
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(
            Get.context!,
            label: "Longitude",
            value: "${position.longitude.toStringAsFixed(6)}°",
            icon: Icons.arrow_forward,
          ),
        ],
      ),

      _buildInfoCard(
        Get.context!,
        icon: Icons.info_outline,
        iconColor: Colors.orange,
        title: "Location Details",
        children: [
          _buildInfoRow(
            Get.context!,
            label: "Information",
            value: description,
            icon: Icons.straighten,
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(
            Get.context!,
            label: "Precision",
            value: "High (±5m)",
            icon: Icons.straighten,
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(
            Get.context!,
            label: "Format",
            value: "Decimal Degrees",
            icon: Icons.format_list_numbered,
          ),
        ],
      ),

      // _buildInfoCard(
      //   Get.context!,
      //   icon: Icons.straighten,
      //   iconColor: Colors.purple,
      //   title: "Distance Info",
      //   children: [
      //     _buildInfoRow(
      //       Get.context!,
      //       label: "From Current",
      //       value: "Calculating...",
      //       icon: Icons.my_location,
      //     ),
      //     SizedBox(height: 8.h),
      //     _buildInfoRow(
      //       Get.context!,
      //       label: "Elevation",
      //       value: "Unknown",
      //       icon: Icons.terrain,
      //     ),
      //   ],
      // ),
    ];
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: GoogleFonts.exo2(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        SizedBox(width: 8.w),
        Expanded(
          flex: 2,
          child: Text(
            "$label:",
            style: GoogleFonts.exo2(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.exo2(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInput(NavigationController controller) {
    return Obx(() {
      final showGetRoute = (controller.startPoint.value != null &&
          controller.endPoint.value != null &&
          !controller.isLoadingRoute.value);

      return LocationInputWidget(
        startController: TextEditingController(
            text: controller.useCurrentLocation.value
                ? "Current Location"
                : _getLocationName(controller.startPoint.value)),
        destinationController: TextEditingController(
            text: _getLocationName(controller.endPoint.value)),
        useCurrentLocation: controller.useCurrentLocation.value,
        showGetRoute: showGetRoute,
        isNavigating: controller.isNavigating.value,
        hasRoute: controller.routePoints.isNotEmpty,
        currentPosition: controller.currentPosition.value,
        locationSuggestions: controller.locationSuggestions,
        onStartLocationChanged:
            (bool useCurrentLoc, LatLng? position, String text) {
          controller.setStartPoint(position, isCurrentLocation: useCurrentLoc);
        },
        onDestinationChanged: (LatLng endPoint, String text) {
          controller.setEndPoint(endPoint);
        },
        onGetRoute: controller.getOptimalRoute,
        onStartNavigation: controller.startNavigation,
        onStopNavigation: controller.stopNavigation,
      );
    });
  }
  Widget _buildMap(NavigationController controller) {
    return Obx(() {
      if (controller.currentPosition.value == null &&
          controller.startPoint.value == null) {
        return Container();
      }

      return FlutterMap(
        mapController: controller.mapController,
        options: MapOptions(
          initialCenter: controller.currentPosition.value ??
              controller.startPoint.value ??
              LatLng(26.8475, 75.5672),
          initialZoom: 17.0,
          minZoom: 10.0,
          maxZoom: 20.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.student_helper',
          ),
          _buildPolylineLayer(controller),
          _buildMarkerLayer(controller),
        ],
      );
    });
  }

  Widget _buildPolylineLayer(NavigationController controller) {
    return Obx(() {
      if (controller.routePoints.isEmpty) return Container();

      return PolylineLayer(
        polylines: [
          Polyline(
            points: controller.routePoints,
            color: controller.isNavigating.value
                ? const Color.fromARGB(255, 2, 136, 245)
                : Colors.blue.withAlpha(200),
            strokeWidth: 5.0,
          )
        ],
      );
    });
  }

  Widget _buildMarkerLayer(NavigationController controller) {
    return Obx(() {
      List<Marker> markers = [];

      if (controller.currentPosition.value != null) {
        markers.add(
          Marker(
            point: controller.currentPosition.value!,
            width: 40.0,
            height: 40.0,
            child: Transform.rotate(
              angle: controller.currentBearing.value * math.pi / 180,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }

      if (controller.startPoint.value != null &&
          !controller.useCurrentLocation.value) {
        markers.add(
          Marker(
            point: controller.startPoint.value!,
            width: 40.0,
            height: 40.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.flag,
                color: Colors.white,
                size: 24,
              ).onLongPress(() {
                _showLocationInfo(
                  Get.context!,
                  "From Location",
                  _getLocationName(controller.startPoint.value),
                  _getLocationDescription(controller.startPoint.value),
                  controller.startPoint.value!,
                );
              }, key),
            ),
          ),
        );
      }

      if (controller.endPoint.value != null) {
        markers.add(
          Marker(
            point: controller.endPoint.value!,
            width: 40.0,
            height: 40.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
              ).onLongPress(() {
                _showLocationInfo(
                  Get.context!,
                  "To Location",
                  _getLocationName(controller.endPoint.value),
                  _getLocationDescription(controller.endPoint.value),
                  controller.endPoint.value!,
                );
              }, key),
            ),
          ),
        );
      }

      return MarkerLayer(markers: markers);
    });
  }

  Widget _buildLoadingIndicators(NavigationController controller) {
    return Obx(() {
      if (controller.isLoadingLocation.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Getting your location..."),
            ],
          ),
        );
      }

      if (controller.isLoadingRoute.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Calculating optimal route..."),
            ],
          ),
        );
      }

      return Container();
    });
  }

  Widget _buildErrorDisplay(NavigationController controller) {
    return Obx(() {
      if (controller.errorMessage.value.isEmpty) return Container();

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                controller.errorMessage.value,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  controller.errorMessage.value = '';
                  controller.getCurrentLocation();
                },
                child: Text("Retry"),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNavigationUI(NavigationController controller) {
    return Obx(() {
      if (!controller.isNavigating.value || controller.steps.isEmpty) {
        return Container();
      }

      return Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Step ${controller.currentStepIndex.value + 1} of ${controller.steps.length}",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  if (controller.distanceToNextStep.value > 0)
                    Text(
                      controller
                          .formatDistance(controller.distanceToNextStep.value),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                controller.currentStepIndex.value < controller.steps.length
                    ? controller.steps[controller.currentStepIndex.value]
                            ['instruction']
                        .toString()
                    : "",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (controller.estimatedTimeArrival.value > 0) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "ETA: ${controller.formatTime(controller.estimatedTimeArrival.value)}",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (controller.hasDeviatedFromRoute.value)
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "Route deviation detected",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLocationButton(NavigationController controller) {
    return Obx(() {
      if (controller.currentPosition.value == null ||
          controller.isLoadingLocation.value) {
        return Container();
      }

      return Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton(
          mini: true,
          onPressed: controller.centerOnCurrentLocation,
          child: Icon(Icons.my_location),
        ),
      );
    });
  }

  String _getLocationName(LatLng? position) {
    if (position == null) return "";

    for (var location in Get.find<NavigationController>().locationSuggestions) {
      if ((location['lat'] - position.latitude).abs() < 0.0001 &&
          (location['lng'] - position.longitude).abs() < 0.0001) {
        return location['name'];
      }
    }

    return "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
  }
  String _getLocationDescription(LatLng? position) {
    if (position == null) return "description as a placeholder";

    for (var location in Get.find<NavigationController>().locationSuggestions) {
      if ((location['lat'] - position.latitude).abs() < 0.0001 &&
          (location['lng'] - position.longitude).abs() < 0.0001) {
        return location['description'];
      }
    }

    return "description as a placeholder";
  }
}
