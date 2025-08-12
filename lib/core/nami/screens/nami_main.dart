import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:student_helper/core/nami/apis/campus_nav_api.dart';
import 'package:http/http.dart' as http;
import 'package:student_helper/core/nami/widgets/location_inputs.dart';

class NamiMain extends StatefulWidget {
  const NamiMain({super.key});

  @override
  State<NamiMain> createState() => _NamiMainState();
}

class _NamiMainState extends State<NamiMain> {
  final FlutterTts tts = FlutterTts();
  final MapController mapController = MapController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  LatLng? startPoint;
  LatLng? endPoint;
  List<LatLng> routePoints = [];
  List<Map<String, dynamic>> steps = [];
  int currentStepIndex = 0;
  bool isLoadingRoute = false;
  bool isLoadingLocation = false;
  bool isNavigating = false;
  bool useCurrentLocation = true;
  LatLng? currentPosition;
  String? errorMessage;

  Timer? navigationTimer;
  double currentBearing = 0.0;
  double distanceToNextStep = 0.0;
  double totalDistance = 0.0;
  double estimatedTimeArrival = 0.0;
  bool hasDeviatedFromRoute = false;
  DateTime? navigationStartTime;

  List<List<LatLng>> alternativeRoutes = [];
  int selectedRouteIndex = 0;

  List<Map<String, dynamic>> locationSuggestions = [
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
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _getCurrentLocation();
    _setupTTS();
  }

  void _setupTTS() async {
    await tts.setLanguage("en-US");
    await tts.setPitch(1.0);
    await tts.setSpeechRate(0.5);
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isLoadingLocation = true;
        errorMessage = null;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            "Location services are disabled. Please enable location services.");
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

      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        if (useCurrentLocation) {
          startPoint = currentPosition;
          startController.text = "Current Location";
        }
        isLoadingLocation = false;
      });

      _startLocationTracking();
    } catch (e) {
      setState(() {
        errorMessage = "Failed to get location: $e";
        isLoadingLocation = false;
      });
    }
  }

  void _startLocationTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
        timeLimit: Duration(seconds: 10),
      ),
    ).listen(
      (Position position) {
        final newPosition = LatLng(position.latitude, position.longitude);

        setState(() {
          currentPosition = newPosition;
          currentBearing = position.heading;
        });

        if (isNavigating) {
          _updateRealTimeNavigation(position);
        }

        if (isNavigating && currentPosition != null) {
          mapController.move(currentPosition!, 18.0);
        }
      },
      onError: (error) {
        print("Location tracking error: $error");
      },
    );
  }

  void _updateRealTimeNavigation(Position position) {
    if (steps.isEmpty || currentStepIndex >= steps.length) return;

    try {
      if (useCurrentLocation && endPoint != null) {
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

    bool wasDeviated = hasDeviatedFromRoute;
    hasDeviatedFromRoute = minDistance > 50;

    if (hasDeviatedFromRoute && !wasDeviated) {
      _speakStep("You have deviated from the route. Recalculating...");
      _recalculateRoute();
    }
  }

  Timer? routeUpdateTimer;
  DateTime? lastRouteUpdate;

  void _updateRouteFromCurrentPosition(Position position) async {
    final now = DateTime.now();
    if (lastRouteUpdate != null &&
        now.difference(lastRouteUpdate!).inSeconds < 30) {
      return;
    }

    final newStartPoint = LatLng(position.latitude, position.longitude);

    if (startPoint != null) {
      double distanceMoved = Geolocator.distanceBetween(
        startPoint!.latitude,
        startPoint!.longitude,
        newStartPoint.latitude,
        newStartPoint.longitude,
      );

      if (distanceMoved < 20) return; 
    }

    setState(() {
      startPoint = newStartPoint;
      lastRouteUpdate = now;
    });

    try {
      await _getOptimalRouteQuiet();
    } catch (e) {
      print("Failed to update route: $e");
    }
  }

  Future<void> _getOptimalRouteQuiet() async {
    if (startPoint == null || endPoint == null) return;

    try {
      await _getMultipleRoutes();
      _selectBestRoute();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Silent route update failed: $e");
    }
  }

  void _updateDistanceToNextStep(Position position) {
    if (currentStepIndex < steps.length &&
        steps[currentStepIndex]['way_points'] != null) {
      final wayPoints = steps[currentStepIndex]['way_points'] as List;
      if (wayPoints.length > 1) {
        final endWaypointIndex = (wayPoints[1] as num).toInt();
        if (endWaypointIndex < routePoints.length) {
          distanceToNextStep = Geolocator.distanceBetween(
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
    if (currentStepIndex >= steps.length - 1) return;

    try {
      final wayPointsData = steps[currentStepIndex]['way_points'];
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
            setState(() {
              currentStepIndex++;
            });

            if (currentStepIndex < steps.length) {
              _speakStep(steps[currentStepIndex]['instruction'].toString());
            } else {
              _speakStep("You have arrived at your destination!");
              _stopNavigation();
            }
          }
        }
      }
    } catch (e) {
      print("Error checking step progress: $e");
    }
  }

  void _updateETA() {
    if (navigationStartTime == null || routePoints.isEmpty) return;

    double remainingDistance = 0.0;
    if (currentPosition != null && endPoint != null) {
      remainingDistance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        endPoint!.latitude,
        endPoint!.longitude,
      );
    }

    estimatedTimeArrival = remainingDistance / 1.4;
  }

  Future<void> _recalculateRoute() async {
    if (currentPosition != null && endPoint != null) {
      setState(() {
        startPoint = currentPosition;
      });
      await _getOptimalRoute();
    }
  }

  void _selectBestRoute() {
    selectedRouteIndex = 0;
  }

  void _startNavigation() {
    if (routePoints.isEmpty || steps.isEmpty) {
      _showSnackBar("No route available. Please calculate a route first.");
      return;
    }

    setState(() {
      isNavigating = true;
      currentStepIndex = 0;
      navigationStartTime = DateTime.now();
      hasDeviatedFromRoute = false;
    });

    _speakStep("Navigation started. ${steps.first['instruction'].toString()}");

    navigationTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (isNavigating && currentPosition != null) {
        _updateRealTimeNavigation(Position(
          latitude: currentPosition!.latitude,
          longitude: currentPosition!.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: currentBearing,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ));
      }
    });
  }

  void _stopNavigation() {
    setState(() {
      isNavigating = false;
      currentStepIndex = 0;
      navigationStartTime = null;
      hasDeviatedFromRoute = false;
    });

    navigationTimer?.cancel();
    navigationTimer = null;

    tts.stop();
  }

  Future<void> _speakStep(String step) async {
    try {
      await tts.speak(step);
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildLocationInput() {
    final showGetRoute =
        (startPoint != null && endPoint != null && !isLoadingRoute);

    return LocationInputWidget(
      startController: startController,
      destinationController: destinationController,
      useCurrentLocation: useCurrentLocation,
      showGetRoute: showGetRoute,
      isNavigating: isNavigating,
      hasRoute: routePoints.isNotEmpty,
      currentPosition: currentPosition,
      locationSuggestions: locationSuggestions,
      onStartLocationChanged: (bool useCurrentLoc, LatLng? position, String text) {
        setState(() {
          useCurrentLocation = useCurrentLoc;
          startPoint = position;
          startController.text = text;
        });
      },
      onDestinationChanged: (LatLng endPoint, String text) {
        setState(() {
          this.endPoint = endPoint;
          destinationController.text = text;
        });
      },
      onGetRoute: _getOptimalRoute,
      onStartNavigation: _startNavigation,
      onStopNavigation: _stopNavigation,
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return "${distance.round()} m";
    } else {
      return "${(distance / 1000).toStringAsFixed(1)} km";
    }
  }

  String _formatTime(double seconds) {
    int minutes = (seconds / 60).round();
    if (minutes < 60) {
      return "$minutes min";
    } else {
      int hours = minutes ~/ 60;
      minutes = minutes % 60;
      return "${hours}h ${minutes}m";
    }
  }

  @override
  void dispose() {
    navigationTimer?.cancel();
    tts.stop();
    startController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<void> _getMultipleRoutes() async {
    setState(() {
      alternativeRoutes.clear();
      routePoints.clear();
      steps.clear();
    });

    const String url =
        'https://api.openrouteservice.org/v2/directions/foot-walking/geojson';

    await _getSingleRoute(url, 'fastest', true);
    try {
      await _getSingleRoute(url, 'shortest', false);
    } catch (e) {
      print("Could not get alternative route: $e");
    }
  }

  Future<void> _getSingleRoute(
      String url, String preference, bool isMainRoute) async {
    final Map<String, dynamic> body = {
      "coordinates": [
        [startPoint!.longitude, startPoint!.latitude],
        [endPoint!.longitude, endPoint!.latitude]
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
        final geometry =
            routeData['features'][0]['geometry']['coordinates'] as List;
        final segments =
            routeData['features'][0]['properties']['segments'] as List;

        if (segments.isNotEmpty) {
          final instructionList = segments[0]['steps'] as List;
          final distance = segments[0]['distance'] as num;

          final routeOption =
              geometry.map((coord) => LatLng(coord[1], coord[0])).toList();

          if (isMainRoute) {
            setState(() {
              routePoints = routeOption;
              steps = instructionList
                  .map((step) => step as Map<String, dynamic>)
                  .toList();
              totalDistance = distance.toDouble();
              currentStepIndex = 0;
            });
          }

          alternativeRoutes.add(routeOption);
        }
      }
    } else {
      throw Exception("Failed to fetch route: HTTP ${response.statusCode}");
    }
  }

  Future<void> _getOptimalRoute() async {
    if (startPoint == null || endPoint == null) {
      setState(() {
        errorMessage = "Please set both start and destination points";
      });
      return;
    }

    setState(() {
      isLoadingRoute = true;
      errorMessage = null;
      if (isNavigating) {
        _stopNavigation();
      }
    });

    try {
      await _getMultipleRoutes();
      _selectBestRoute();

      setState(() {
        isLoadingRoute = false;
      });

      if (steps.isNotEmpty) {
        _speakStep(
            "Route calculated. ${steps.first['instruction'].toString()}");

        if (routePoints.isNotEmpty) {
          _fitMapToRoute();
        }
      }
    } catch (e) {
      setState(() {
        isLoadingRoute = false;
        errorMessage = "Failed to calculate route: $e";
      });
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

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Column(
        children: [
          _buildLocationInput(),
          Expanded(
            child: Stack(
              children: [
                if (currentPosition != null || startPoint != null)
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: currentPosition ??
                          startPoint ??
                          LatLng(26.8475, 75.5672),
                      initialZoom: 17.0,
                      minZoom: 10.0,
                      maxZoom: 20.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName:
                            'com.example.student_helper',
                      ),
                      if (routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              color: isNavigating
                                  ?  const Color.fromARGB(255, 2, 136, 245)
                                  : Colors.blue.withAlpha(200),
                              strokeWidth: 5.0,
                            )
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (currentPosition != null)
                            Marker(
                              point: currentPosition!,
                              width: 40.0,
                              height: 40.0,
                              child: Transform.rotate(
                                angle: currentBearing * math.pi / 180,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          if (startPoint != null && !useCurrentLocation)
                            Marker(
                              point: startPoint!,
                              width: 40.0,
                              height: 40.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
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
                                ),
                              ),
                            ),
                          if (endPoint != null)
                            Marker(
                              point: endPoint!,
                              width: 40.0,
                              height: 40.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
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
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                if (isLoadingLocation)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Getting your location..."),
                      ],
                    ),
                  ),
                if (isLoadingRoute)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Calculating optimal route..."),
                      ],
                    ),
                  ),
                if (errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            style: TextStyle(
                                color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initializeApp,
                            child: Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isNavigating && steps.isNotEmpty)
                  Positioned(
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
                              Icon(Icons.directions,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Step ${currentStepIndex + 1} of ${steps.length}",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12),
                                ),
                              ),
                              if (distanceToNextStep > 0)
                                Text(
                                  _formatDistance(distanceToNextStep),
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            steps[currentStepIndex]['instruction']
                                .toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (estimatedTimeArrival > 0) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    color: Colors.white70, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "ETA: ${_formatTime(estimatedTimeArrival)}",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                          if (hasDeviatedFromRoute)
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    "Route deviation detected",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (currentPosition != null && !isLoadingLocation)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () {
                        if (currentPosition != null) {
                          mapController.move(currentPosition!, 18.0);
                        }
                      },
                      child: Icon(Icons.my_location),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
