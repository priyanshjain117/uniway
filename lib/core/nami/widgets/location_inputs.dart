import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as Math;

class LocationInputWidget extends StatefulWidget {
  final TextEditingController startController;
  final TextEditingController destinationController;
  final bool useCurrentLocation;
  final bool showGetRoute;
  final bool isNavigating;
  final bool hasRoute;
  final LatLng? currentPosition;
  final List<Map<String, dynamic>> locationSuggestions;
  final Function(bool useCurrentLocation, LatLng? position, String text)
      onStartLocationChanged;
  final Function(LatLng endPoint, String text) onDestinationChanged;
  final VoidCallback? onGetRoute;
  final VoidCallback? onStartNavigation;
  final VoidCallback? onStopNavigation;

  const LocationInputWidget({
    super.key,
    required this.startController,
    required this.destinationController,
    required this.useCurrentLocation,
    required this.showGetRoute,
    required this.isNavigating,
    required this.hasRoute,
    required this.currentPosition,
    required this.locationSuggestions,
    required this.onStartLocationChanged,
    required this.onDestinationChanged,
    this.onGetRoute,
    this.onStartNavigation,
    this.onStopNavigation,
  });

  @override
  State<LocationInputWidget> createState() => _LocationInputWidgetState();
}

class _LocationInputWidgetState extends State<LocationInputWidget> {
  void _useCurrentLocation() {
    widget.onStartLocationChanged(
      true,
      widget.currentPosition,
      "Current Location",
    );
  }

  void _selectLocation(String type, Map<String, dynamic> location) {
    final point = LatLng(location['lat'], location['lng']);
    if (type == 'start') {
      widget.onStartLocationChanged(false, point, location['name']);
    } else {
      widget.onDestinationChanged(point, location['name']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withAlpha(160),
            theme.colorScheme.primary.withAlpha(80),
            theme.colorScheme.surfaceDim,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TypeAheadLocationField(
            controller: widget.startController,
            labelText: 'From',
            prefixIcon: Icons.my_location,
            locationSuggestions: widget.locationSuggestions,
            currentPosition: widget.currentPosition,
            onLocationSelected: (location) => _selectLocation('start', location),
            onUseCurrentLocation: _useCurrentLocation,
            showCurrentLocationOption: true,
            suffixIcon: CurrentLocationButton(
              onPressed: _useCurrentLocation,
              isActive: widget.useCurrentLocation,
            ),
            helperText: widget.useCurrentLocation ? "📍 Live location tracking enabled" : null,
          ),
          const SizedBox(height: 12),
          TypeAheadLocationField(
            controller: widget.destinationController,
            labelText: 'To',
            prefixIcon: Icons.location_on,
            locationSuggestions: widget.locationSuggestions,
            onLocationSelected: (location) => _selectLocation('destination', location),
            showCurrentLocationOption: false,
          ),
          const SizedBox(height: 12),
          RouteActionButtons(
            showGetRoute: widget.showGetRoute,
            isNavigating: widget.isNavigating,
            hasRoute: widget.hasRoute,
            onGetRoute: widget.onGetRoute,
            onStartNavigation: widget.onStartNavigation,
            onStopNavigation: widget.onStopNavigation,
          ),
        ],
      ),
    );
  }
}

class TypeAheadLocationField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final List<Map<String, dynamic>> locationSuggestions;
  final Function(Map<String, dynamic>) onLocationSelected;
  final VoidCallback? onUseCurrentLocation;
  final LatLng? currentPosition;
  final bool showCurrentLocationOption;
  final Widget? suffixIcon;
  final String? helperText;
  final int maxSuggestions;
  final Duration debounceDelay;

  const TypeAheadLocationField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    required this.locationSuggestions,
    required this.onLocationSelected,
    this.onUseCurrentLocation,
    this.currentPosition,
    this.showCurrentLocationOption = false,
    this.suffixIcon,
    this.helperText,
    this.maxSuggestions = 8,
    this.debounceDelay = const Duration(milliseconds: 200),
  });

  @override
  State<TypeAheadLocationField> createState() => _TypeAheadLocationFieldState();
}

class _TypeAheadLocationFieldState extends State<TypeAheadLocationField>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _filteredSuggestions = [];
  AnimationController? _animationController;
  Animation<double>? _animation;
  String? _debounceTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _hideOverlay();
    _focusNode.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Add small delay to allow for tap on suggestions
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_focusNode.hasFocus) {
          _hideOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    // Debounce for better performance
    final currentText = widget.controller.text;
    _debounceTimer = currentText;
    
    Future.delayed(widget.debounceDelay, () {
      if (_debounceTimer == currentText && mounted) {
        _filterSuggestions(currentText);
      }
    });
  }

  void _filterSuggestions(String query) {
    setState(() {
      _isLoading = true;
    });

    final normalizedQuery = query.toLowerCase().trim();

    if (normalizedQuery.isEmpty) {
      _filteredSuggestions = widget.locationSuggestions
          .take(widget.maxSuggestions)
          .toList();
    } else {
      _filteredSuggestions = widget.locationSuggestions.where((location) {
        final name = location['name'].toString().toLowerCase();
        final address = location['address']?.toString().toLowerCase() ?? '';
        return name.contains(normalizedQuery) || address.contains(normalizedQuery);
      }).toList();

      // Enhanced sorting with fuzzy matching
      _filteredSuggestions.sort((a, b) {
        final aName = a['name'].toString().toLowerCase();
        final bName = b['name'].toString().toLowerCase();
        final aAddress = a['address']?.toString().toLowerCase() ?? '';
        final bAddress = b['address']?.toString().toLowerCase() ?? '';

        int getMatchScore(String name, String address) {
          // Exact match gets highest score
          if (name == normalizedQuery) return 10000;
          
          // Name starts with query
          if (name.startsWith(normalizedQuery)) {
            return 5000 + (100 - normalizedQuery.length);
          }
          
          // Address starts with query
          if (address.startsWith(normalizedQuery)) {
            return 4500 + (100 - normalizedQuery.length);
          }

          // Word-level matching in name
          final nameWords = name.split(RegExp(r'[\s\-_,]+'));
          int nameWordScore = 0;
          for (int i = 0; i < nameWords.length; i++) {
            final word = nameWords[i];
            if (word == normalizedQuery) {
              nameWordScore = Math.max(nameWordScore, 4000 - (i * 100));
            } else if (word.startsWith(normalizedQuery)) {
              nameWordScore = Math.max(nameWordScore, 3000 - (i * 100));
            }
          }

          // Word-level matching in address
          final addressWords = address.split(RegExp(r'[\s\-_,]+'));
          int addressWordScore = 0;
          for (int i = 0; i < addressWords.length; i++) {
            final word = addressWords[i];
            if (word == normalizedQuery) {
              addressWordScore = Math.max(addressWordScore, 3500 - (i * 100));
            } else if (word.startsWith(normalizedQuery)) {
              addressWordScore = Math.max(addressWordScore, 2500 - (i * 100));
            }
          }

          int bestWordScore = Math.max(nameWordScore, addressWordScore);
          if (bestWordScore > 0) return bestWordScore;

          // Contains in name
          final nameIndex = name.indexOf(normalizedQuery);
          if (nameIndex != -1) {
            return 2000 - nameIndex;
          }

          // Contains in address
          final addressIndex = address.indexOf(normalizedQuery);
          if (addressIndex != -1) {
            return 1500 - addressIndex;
          }

          return 0;
        }

        final scoreA = getMatchScore(aName, aAddress);
        final scoreB = getMatchScore(bName, bAddress);

        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA);
        }

        // Secondary sort by length (shorter names first)
        final lengthDiff = aName.length.compareTo(bName.length);
        if (lengthDiff != 0) {
          return lengthDiff;
        }

        return aName.compareTo(bName);
      });

      // Limit results
      if (_filteredSuggestions.length > widget.maxSuggestions) {
        _filteredSuggestions = _filteredSuggestions.take(widget.maxSuggestions).toList();
      }
    }

    setState(() {
      _isLoading = false;
    });
    _updateOverlay();
  }

  void _showOverlay() {
    if (_filteredSuggestions.isEmpty) {
      _filteredSuggestions = widget.locationSuggestions
          .take(widget.maxSuggestions)
          .toList();
    }
    
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _animationController?.forward();
    } else {
      _updateOverlay();
    }
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _animationController?.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    }
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject()! as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final remainingSpace = screenHeight - offset.dy - size.height;
    final maxHeight = remainingSpace > 300 ? 300.0 : remainingSpace - 20;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5.0,
        width: size.width,
        child: AnimatedBuilder(
          animation: _animation!,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation!.value,
              alignment: Alignment.topCenter,
              child: Opacity(
                opacity: _animation!.value,
                child: Material(
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(12.0),
                  shadowColor: Colors.black26,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _buildSuggestionsList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final suggestions = <Widget>[];

    // Current location option
    if (widget.showCurrentLocationOption &&
        widget.currentPosition != null &&
        widget.onUseCurrentLocation != null) {
      suggestions.add(
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(25),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(
              Icons.gps_fixed,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
            title: const Text(
              "Use Current Location", 
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)
            ),
            subtitle: const Text(
              "Live location tracking", 
              style: TextStyle(fontSize: 12)
            ),
            trailing: Icon(
              Icons.my_location,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              widget.controller.text = "Current Location";
              widget.onUseCurrentLocation!();
              _focusNode.unfocus();
            },
          ),
        ),
      );

      if (_filteredSuggestions.isNotEmpty) {
        suggestions.add(Divider(height: 1, color: Colors.grey.shade300));
      }
    }

    // Loading indicator
    if (_isLoading) {
      suggestions.add(
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text("Searching...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    } else {
      // Location suggestions
      suggestions.addAll(_filteredSuggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final location = entry.value;
        final query = widget.controller.text.toLowerCase();
        final name = location['name'].toString();
        final address = location['address']?.toString();
        final isLast = index == _filteredSuggestions.length - 1;

        return Container(
          decoration: BoxDecoration(
            borderRadius: isLast 
                ? const BorderRadius.vertical(bottom: Radius.circular(12))
                : null,
          ),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.location_on, size: 20, color: Colors.grey),
            title: _buildHighlightedText(name, query),
            subtitle: address != null && address.isNotEmpty
                ? Text(
                    address,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
            onTap: () {
              widget.controller.text = name;
              widget.onLocationSelected(location);
              _focusNode.unfocus();
            },
          ),
        );
      }));
    }

    // Empty state
    if (suggestions.isEmpty || 
        (suggestions.length == 1 && widget.showCurrentLocationOption)) {
      final hasCurrentLocationOnly = suggestions.length == 1;
      suggestions.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (hasCurrentLocationOnly) const Divider(height: 1),
              const SizedBox(height: 8),
              Icon(Icons.search_off, size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                "No locations found",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "Try a different search term",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: suggestions,
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 14));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    if (!lowerText.contains(lowerQuery)) {
      return Text(text, style: const TextStyle(fontSize: 14));
    }

    final matches = <TextSpan>[];
    var lastMatchEnd = 0;

    // Find all matches for better highlighting
    var searchIndex = 0;
    while (searchIndex < lowerText.length) {
      final matchIndex = lowerText.indexOf(lowerQuery, searchIndex);
      if (matchIndex == -1) break;

      // Add text before match
      if (matchIndex > lastMatchEnd) {
        matches.add(TextSpan(
          text: text.substring(lastMatchEnd, matchIndex),
        ));
      }

      // Add highlighted match
      matches.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + query.length),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
        ),
      ));

      lastMatchEnd = matchIndex + query.length;
      searchIndex = lastMatchEnd;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      matches.add(TextSpan(
        text: text.substring(lastMatchEnd),
      ));
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
        children: matches,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          prefixIcon: Icon(widget.prefixIcon),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    widget.controller.clear();
                    _focusNode.requestFocus();
                  },
                  tooltip: "Clear",
                ),
              if (widget.suffixIcon != null) widget.suffixIcon!,
            ],
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          helperText: widget.helperText,
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }
}

class CurrentLocationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const CurrentLocationButton({
    super.key,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.gps_fixed, 
        color: isActive ? Theme.of(context).colorScheme.primary : null
      ),
      onPressed: onPressed,
      tooltip: "Use current location",
    );
  }
}

class RouteActionButtons extends StatelessWidget {
  final bool showGetRoute;
  final bool isNavigating;
  final bool hasRoute;
  final VoidCallback? onGetRoute;
  final VoidCallback? onStartNavigation;
  final VoidCallback? onStopNavigation;

  const RouteActionButtons({
    super.key,
    required this.showGetRoute,
    required this.isNavigating,
    required this.hasRoute,
    this.onGetRoute,
    this.onStartNavigation,
    this.onStopNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: showGetRoute ? onGetRoute : null,
            icon: Icon(
              Icons.route,
              color: showGetRoute ? Theme.of(context).colorScheme.primary : Colors.white,
            ),
            label: Text(
              'Get Route',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: showGetRoute ? Theme.of(context).colorScheme.primary : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (hasRoute && !isNavigating)
                ? onStartNavigation
                : isNavigating
                    ? onStopNavigation
                    : null,
            icon: Icon(
              isNavigating ? Icons.stop : Icons.navigation,
              color: hasRoute ? Theme.of(context).colorScheme.primary : Colors.white
            ),
            label: Text(
              isNavigating ? 'Stop' : 'Navigate',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: hasRoute ? Theme.of(context).colorScheme.primary : Colors.white
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isNavigating ? Colors.red : null,
            ),
          ),
        ),
      ],
    );
  }
}