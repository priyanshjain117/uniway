import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:student_helper/core/nami/apis/campus_nav_api.dart';

class NavigationController extends GetxController {
  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  final Rx<LatLng?> startPoint = Rx<LatLng?>(null);
  final Rx<LatLng?> endPoint = Rx<LatLng?>(null);
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final RxList<Map<String, dynamic>> steps = <Map<String, dynamic>>[].obs;
  final RxBool isNavigating = false.obs;
  final RxBool useCurrentLocation = true.obs;
  final RxBool isLoadingRoute = false.obs;
  final RxBool isLoadingLocation = false.obs;
  final RxInt currentStepIndex = 0.obs;
  final RxDouble currentBearing = 0.0.obs;
  final RxDouble distanceToNextStep = 0.0.obs;
  final RxDouble totalDistance = 0.0.obs;
  final RxDouble estimatedTimeArrival = 0.0.obs;
  final RxBool hasDeviatedFromRoute = false.obs;
  final RxString errorMessage = ''.obs;
  
  final RxList<List<LatLng>> alternativeRoutes = <List<LatLng>>[].obs;
  final RxInt selectedRouteIndex = 0.obs;

  StreamSubscription<Position>? _locationSubscription;
  Timer? _navigationTimer;
  DateTime? _lastRouteUpdate;
  DateTime? _navigationStartTime;
  final FlutterTts tts = FlutterTts();
  final MapController mapController = MapController();

  final List<Map<String, dynamic>> locationSuggestions = [
    {
      'name': 'MUJ Main Gate',
      'lat': 26.841241261658997,
      'lng': 75.5660735192115
    },
    {
      'name': 'MUJ DOM Library',
      'lat': 26.841648544065848,
      'lng': 75.56533929057673
    },
    {
      'name': 'MUJ Law Library',
      'lat': 26.843518600668162,
      'lng': 75.56399292394734
    },
    {'name': 'Old Mess', 'lat': 26.842962294996134, 'lng': 75.5651385090395},
    {'name': 'AIC MUJ', 'lat': 26.843819718587728, 'lng': 75.5665295300519},
    {'name': 'Sharda Pai Auditorium', 'lat': 26.84312477058901, 'lng': 75.56606017796628},
    {'name': 'Vasanti R. Pai Auditorium', 'lat': 26.843761461504357, 'lng': 75.56205834697577},
    {'name': 'Grand Staircase', 'lat': 26.842513504647947, 'lng': 75.56555146541382},
    {
      'name': 'Academic Block 1',
      'lat': 26.84259830237035,
      'lng': 75.56382817072095
    },
    {
      'name': 'Academic Block 2',
      'lat': 26.84328873212543,
      'lng': 75.56604459515161
    },
    {
      'name': 'Academic Block 3',
      'lat': 26.843951810830465,
      'lng': 75.56492052504308
    },
    {
      'name': 'Academic Block 4',
      'lat': 26.843965118302908,
      'lng': 75.56489018652901
    },
    {
      'name': 'Workshop',
      'lat': 26.8437696296453,
      'lng': 75.56701241102105
    },
  ];

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
    _setupReactiveWorkers();
  }

  void _setupReactiveWorkers() {
    ever(currentPosition, (LatLng? position) {
      if (isNavigating.value && useCurrentLocation.value && position != null) {
        mapController.move(position, 18.0);
      }
    });

    ever(currentPosition, (LatLng? position) {
      if (useCurrentLocation.value && position != null) {
        startPoint.value = position;
      }
    });

    ever(useCurrentLocation, (bool useCurrent) {
      if (useCurrent && currentPosition.value != null) {
        startPoint.value = currentPosition.value;
      }
    });
  }

  Future<void> _initializeApp() async {
    await _getCurrentLocation();
    await _setupTTS();
  }

  Future<void> _setupTTS() async {
    try {
      await tts.setLanguage("en-US");
      await tts.setPitch(1.0);
      await tts.setSpeechRate(0.5);
    } catch (e) {
      print("TTS setup error: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;
      errorMessage.value = '';

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled. Please enable location services.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      currentPosition.value = LatLng(position.latitude, position.longitude);
      if (useCurrentLocation.value) {
        startPoint.value = currentPosition.value;
      }
      isLoadingLocation.value = false;

      _startLocationTracking();
    } catch (e) {
      errorMessage.value = "Failed to get location: $e";
      isLoadingLocation.value = false;
    }
  }

  void _startLocationTracking() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
        timeLimit: Duration(seconds: 10),
      ),
    ).listen(
      _onLocationUpdate,
      onError: (error) {
        print("Location tracking error: $error");
      },
    );
  }

  void _onLocationUpdate(Position position) {
    final newPosition = LatLng(position.latitude, position.longitude);
    
    currentPosition.value = newPosition;
    currentBearing.value = position.heading;

    if (isNavigating.value && useCurrentLocation.value) {
      _updateRealTimeNavigation(position);
    }
  }

  void _updateRealTimeNavigation(Position position) {
    if (steps.isEmpty || currentStepIndex.value >= steps.length) return;

    try {
      if (useCurrentLocation.value && endPoint.value != null) {
        _updateRouteFromCurrentPosition(position);
      }

      _checkRouteDeviation(position);
      _updateDistanceToNextStep(position);
      _checkStepProgress(position);
      _updateETA();
    } catch (e) {
      print("Real-time navigation error: $e");
    }
  }

  void _updateRouteFromCurrentPosition(Position position) async {
    final now = DateTime.now();
    if (_lastRouteUpdate != null &&
        now.difference(_lastRouteUpdate!).inSeconds < 30) {
      return;
    }

    final newStartPoint = LatLng(position.latitude, position.longitude);

    if (startPoint.value != null) {
      double distanceMoved = Geolocator.distanceBetween(
        startPoint.value!.latitude,
        startPoint.value!.longitude,
        newStartPoint.latitude,
        newStartPoint.longitude,
      );

      if (distanceMoved < 20) return;
    }

    startPoint.value = newStartPoint;
    _lastRouteUpdate = now;

    try {
      await _getOptimalRouteQuiet();
    } catch (e) {
      print("Failed to update route: $e");
    }
  }

  Future<void> _getOptimalRouteQuiet() async {
    if (startPoint.value == null || endPoint.value == null) return;

    try {
      await _getMultipleRoutes();
      _selectBestRoute();
    } catch (e) {
      print("Silent route update failed: $e");
    }
  }

  void _checkRouteDeviation(Position position) {
    if (routePoints.isEmpty) return;

    double minDistance = double.infinity;
    for (LatLng point in routePoints) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    bool wasDeviated = hasDeviatedFromRoute.value;
    hasDeviatedFromRoute.value = minDistance > 50;

    if (hasDeviatedFromRoute.value && !wasDeviated) {
      speakStep("You have deviated from the route. Recalculating...");
      _recalculateRoute();
    }
  }

  void _updateDistanceToNextStep(Position position) {
    if (currentStepIndex.value < steps.length &&
        steps[currentStepIndex.value]['way_points'] != null) {
      final wayPoints = steps[currentStepIndex.value]['way_points'] as List;
      if (wayPoints.length > 1) {
        final endWaypointIndex = (wayPoints[1] as num).toInt();
        if (endWaypointIndex < routePoints.length) {
          distanceToNextStep.value = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            routePoints[endWaypointIndex].latitude,
            routePoints[endWaypointIndex].longitude,
          );
        }
      }
    }
  }

  void _checkStepProgress(Position position) {
    if (currentStepIndex.value >= steps.length - 1) return;

    try {
      final wayPointsData = steps[currentStepIndex.value]['way_points'];
      if (wayPointsData is List && wayPointsData.length > 1) {
        final int endWaypointIndex = (wayPointsData[1] as num).toInt();

        if (endWaypointIndex < routePoints.length) {
          final double distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            routePoints[endWaypointIndex].latitude,
            routePoints[endWaypointIndex].longitude,
          );

          if (distance < 15) {
            currentStepIndex.value++;

            if (currentStepIndex.value < steps.length) {
              speakStep(steps[currentStepIndex.value]['instruction'].toString());
            } else {
              speakStep("You have arrived at your destination!");
              stopNavigation();
            }
          }
        }
      }
    } catch (e) {
      print("Error checking step progress: $e");
    }
  }

  void _updateETA() {
    if (_navigationStartTime == null || routePoints.isEmpty) return;

    double remainingDistance = 0.0;
    if (currentPosition.value != null && endPoint.value != null) {
      remainingDistance = Geolocator.distanceBetween(
        currentPosition.value!.latitude,
        currentPosition.value!.longitude,
        endPoint.value!.latitude,
        endPoint.value!.longitude,
      );
    }

    estimatedTimeArrival.value = remainingDistance / 1.4;
  }

  Future<void> _recalculateRoute() async {
    if (currentPosition.value != null && endPoint.value != null) {
      startPoint.value = currentPosition.value;
      await getOptimalRoute();
    }
  }

  void _selectBestRoute() {
    selectedRouteIndex.value = 0;
  }

  void startNavigation() {
    if (routePoints.isEmpty || steps.isEmpty) {
      showSnackBar("No route available. Please calculate a route first.");
      return;
    }

    isNavigating.value = true;
    currentStepIndex.value = 0;
    _navigationStartTime = DateTime.now();
    hasDeviatedFromRoute.value = false;

    speakStep("Navigation started. ${steps.first['instruction'].toString()}");

    _navigationTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (isNavigating.value && currentPosition.value != null) {
        _updateRealTimeNavigation(Position(
          latitude: currentPosition.value!.latitude,
          longitude: currentPosition.value!.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: currentBearing.value,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ));
      }
    });
  }

  void stopNavigation() {
    isNavigating.value = false;
    currentStepIndex.value = 0;
    _navigationStartTime = null;
    hasDeviatedFromRoute.value = false;

    _navigationTimer?.cancel();
    _navigationTimer = null;
    tts.stop();
  }

  Future<void> speakStep(String step) async {
    try {
      await tts.speak(step);
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  void showSnackBar(String message) {
    Get.snackbar(
      "Navigation",
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void setStartPoint(LatLng? point, {bool isCurrentLocation = false}) {
    useCurrentLocation.value = isCurrentLocation;
    if (!isCurrentLocation) {
      startPoint.value = point;
    } else if (currentPosition.value != null) {
      startPoint.value = currentPosition.value;
    }
  }

  void setEndPoint(LatLng? point) {
    endPoint.value = point;
  }

  String formatDistance(double distance) {
    if (distance < 1000) {
      return "${distance.round()} m";
    } else {
      return "${(distance / 1000).toStringAsFixed(1)} km";
    }
  }

  String formatTime(double seconds) {
    int minutes = (seconds / 60).round();
    if (minutes < 60) {
      return "$minutes min";
    } else {
      int hours = minutes ~/ 60;
      minutes = minutes % 60;
      return "${hours}h ${minutes}m";
    }
  }

  Future<void> getOptimalRoute() async {
    if (startPoint.value == null || endPoint.value == null) {
      errorMessage.value = "Please set both start and destination points";
      return;
    }

    isLoadingRoute.value = true;
    errorMessage.value = '';
    
    if (isNavigating.value) {
      stopNavigation();
    }

    try {
      await _getMultipleRoutes();
      _selectBestRoute();

      isLoadingRoute.value = false;

      if (steps.isNotEmpty) {
        speakStep("Route calculated. ${steps.first['instruction'].toString()}");

        if (routePoints.isNotEmpty) {
          _fitMapToRoute();
        }
      }
    } catch (e) {
      isLoadingRoute.value = false;
      errorMessage.value = "Failed to calculate route: $e";
    }
  }

  Future<void> _getMultipleRoutes() async {
    alternativeRoutes.clear();
    routePoints.clear();
    steps.clear();

    const String url = 'https://api.openrouteservice.org/v2/directions/foot-walking/geojson';

    await _getSingleRoute(url, 'fastest', true);
    try {
      await _getSingleRoute(url, 'shortest', false);
    } catch (e) {
      print("Could not get alternative route: $e");
    }
  }

  Future<void> _getSingleRoute(String url, String preference, bool isMainRoute) async {
    
    final Map<String, dynamic> body = {
      "coordinates": [
        [startPoint.value!.longitude, startPoint.value!.latitude],
        [endPoint.value!.longitude, endPoint.value!.latitude]
      ],
      "instructions": true,
      "instructions_format": "text",
      "preference": preference,
      "units": "m"
    };

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $campusApi',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        )
        .timeout(Duration(seconds: 20));

    if (response.statusCode == 200) {
      final Map<String, dynamic> routeData = json.decode(response.body);

      if (routeData['features'] != null && routeData['features'].isNotEmpty) {
        final geometry = routeData['features'][0]['geometry']['coordinates'] as List;
        final segments = routeData['features'][0]['properties']['segments'] as List;

        if (segments.isNotEmpty) {
          final instructionList = segments[0]['steps'] as List;
          final distance = segments[0]['distance'] as num;

          final routeOption = geometry.map((coord) => LatLng(coord[1], coord[0])).toList();

          if (isMainRoute) {
            routePoints.value = routeOption;
            steps.value = instructionList.map((step) => step as Map<String, dynamic>).toList();
            totalDistance.value = distance.toDouble();
            currentStepIndex.value = 0;
          }

          alternativeRoutes.add(routeOption);
        }
      }
    } else {
      throw Exception("Failed to fetch route: HTTP ${response.statusCode}");
    }
  }

  void _fitMapToRoute() {
    if (routePoints.isEmpty) return;

    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (LatLng point in routePoints) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat - latPadding, minLng - lngPadding),
          LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
        padding: EdgeInsets.all(50),
      ),
    );
  }

  void centerOnCurrentLocation() {
    if (currentPosition.value != null) {
      mapController.move(currentPosition.value!, 18.0);
    }
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    _navigationTimer?.cancel();
    tts.stop();
    super.onClose();
  }
}
