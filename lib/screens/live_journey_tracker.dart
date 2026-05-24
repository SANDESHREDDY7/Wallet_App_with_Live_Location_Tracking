import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../models/ticket_item.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';

class LiveJourneyTrackerScreen extends StatefulWidget {
  final TicketItem ticket;

  const LiveJourneyTrackerScreen({super.key, required this.ticket});

  @override
  State<LiveJourneyTrackerScreen> createState() => _LiveJourneyTrackerScreenState();
}

class _LiveJourneyTrackerScreenState extends State<LiveJourneyTrackerScreen> with SingleTickerProviderStateMixin {
  late List<String> _stops;
  late AnimationController _progressController;
  
  bool _isSimulating = false;
  double _simulationProgress = 0.05; // starts slightly in
  Timer? _simTimer;
  StreamSubscription<Position>? _positionStreamSub;

  // Real-time tracking telemetry
  double _currentSpeed = 0.0;
  double _altitude = 0.0; // for flights
  double _distanceRemaining = 0.0;
  String _currentStatus = 'Preparing to depart...';
  String _nextStop = '';
  int _completedStopsCount = 0;
  String _etaText = '--';

  // Major Indian hubs coordinates DB for dynamic route projection
  static const Map<String, Map<String, double>> _cityCoordsDB = {
    'DEL': {'lat': 28.5562, 'lng': 77.1000},
    'NDLS': {'lat': 28.6430, 'lng': 77.2201},
    'BOM': {'lat': 19.0896, 'lng': 72.8656},
    'CSMT': {'lat': 18.9400, 'lng': 72.8353},
    'BLR': {'lat': 13.1986, 'lng': 77.7066},
    'SBC': {'lat': 12.9784, 'lng': 77.5694},
    'MAA': {'lat': 12.9941, 'lng': 80.1807},
    'MAS': {'lat': 13.0827, 'lng': 80.2707},
    'CCU': {'lat': 22.6547, 'lng': 88.4467},
    'HWH': {'lat': 22.5851, 'lng': 88.3386},
    'HYD': {'lat': 17.2403, 'lng': 78.4294},
    'HYB': {'lat': 17.3840, 'lng': 78.4564},
    'SC': {'lat': 17.4344, 'lng': 78.5015},
    'KCG': {'lat': 17.3878, 'lng': 78.4962},
    'PNQ': {'lat': 18.5822, 'lng': 73.9197},
    'PUNE': {'lat': 18.5289, 'lng': 73.8744},
    'VTZ': {'lat': 17.7282, 'lng': 83.2244},
    'VSKP': {'lat': 17.7282, 'lng': 83.2244},
    'VGA': {'lat': 16.5062, 'lng': 80.6480},
    'BZA': {'lat': 16.5089, 'lng': 80.6209},
    'TPTY': {'lat': 13.6288, 'lng': 79.4192},
    'RU': {'lat': 13.6373, 'lng': 79.3492},
    'GNT': {'lat': 16.3067, 'lng': 80.4365},
    'LKO': {'lat': 26.7606, 'lng': 80.8893},
    'LJN': {'lat': 26.8300, 'lng': 80.9200},
    'GOI': {'lat': 15.3797, 'lng': 73.8314},
    'MAO': {'lat': 15.2736, 'lng': 73.9580},
    'AMD': {'lat': 23.0734, 'lng': 72.6347},
    'ADI': {'lat': 23.0276, 'lng': 72.5996},
    'COK': {'lat': 10.1520, 'lng': 76.4019},
    'ERN': {'lat': 9.9824, 'lng': 76.2995},
    'JAI': {'lat': 26.8242, 'lng': 75.8122},
    'JP': {'lat': 26.9200, 'lng': 75.8000},
    'SURYAPET': {'lat': 17.1500, 'lng': 79.6200},
    'KODAD': {'lat': 16.9946, 'lng': 79.9691},
    'NANDIGAMA': {'lat': 16.7725, 'lng': 80.2917},
    'PAT': {'lat': 25.5941, 'lng': 85.1376},
    'PNBE': {'lat': 25.6020, 'lng': 85.1376},
    'ATQ': {'lat': 31.6340, 'lng': 74.8723},
    'ASR': {'lat': 31.6200, 'lng': 74.8700},
    'GHY': {'lat': 26.1445, 'lng': 91.7362},
    'GAU': {'lat': 26.1060, 'lng': 91.5859},
    'BPL': {'lat': 23.2599, 'lng': 77.4126},
    'IDR': {'lat': 22.7196, 'lng': 75.8577},
    'INDB': {'lat': 22.7200, 'lng': 75.8600},
    'NAG': {'lat': 21.1458, 'lng': 79.0882},
    'NGP': {'lat': 21.1500, 'lng': 79.0800},
    'CJB': {'lat': 11.0168, 'lng': 76.9558},
    'CBE': {'lat': 11.0000, 'lng': 76.9600},
    'IXC': {'lat': 30.7333, 'lng': 76.7794},
    'CDG': {'lat': 30.7200, 'lng': 76.7800},
    'ST': {'lat': 21.1702, 'lng': 72.8311},
    'BDQ': {'lat': 22.3072, 'lng': 73.1812},
    'BRC': {'lat': 22.3100, 'lng': 73.1800},
    'TRV': {'lat': 8.5241, 'lng': 76.9366},
    'TVC': {'lat': 8.4800, 'lng': 76.9500},
    'IXM': {'lat': 9.9252, 'lng': 78.1198},
    'MDU': {'lat': 9.9100, 'lng': 78.1200},
    'BBI': {'lat': 20.2961, 'lng': 85.8245},
    'BBS': {'lat': 20.2600, 'lng': 85.8400},
    'IXR': {'lat': 23.3441, 'lng': 85.3096},
    'RNC': {'lat': 23.3500, 'lng': 85.3300},
    'RPR': {'lat': 21.2514, 'lng': 81.6296},
    'R': {'lat': 21.2500, 'lng': 81.6300},
    'DED': {'lat': 30.3165, 'lng': 78.0322},
    'DDN': {'lat': 30.3200, 'lng': 78.0300},
    'VNS': {'lat': 25.3176, 'lng': 82.9739},
    'BSB': {'lat': 25.3200, 'lng': 82.9700},
    'CNB': {'lat': 26.4499, 'lng': 80.3319},
    'AGR': {'lat': 27.1767, 'lng': 78.0081},
    'AGC': {'lat': 27.1800, 'lng': 78.0100},
    'JHS': {'lat': 25.4484, 'lng': 78.5685},
    'JBP': {'lat': 22.1700, 'lng': 79.9300},
    'IXD': {'lat': 25.4358, 'lng': 81.8463},
    'PRYJ': {'lat': 25.4500, 'lng': 81.8500},
    'GWL': {'lat': 26.2124, 'lng': 78.1772},
    'SXR': {'lat': 34.0837, 'lng': 74.7973},
    'IXJ': {'lat': 32.7266, 'lng': 74.8570},
    'JAT': {'lat': 32.7100, 'lng': 74.8600},
    'JDH': {'lat': 26.2389, 'lng': 73.0243},
    'JU': {'lat': 26.2400, 'lng': 73.0200},
    'UDR': {'lat': 24.5854, 'lng': 73.7125},
    'UDZ': {'lat': 24.5800, 'lng': 73.6900},
    'CCJ': {'lat': 11.2588, 'lng': 75.7804},
    'CLT': {'lat': 11.2500, 'lng': 75.7800},
    'IXE': {'lat': 12.9141, 'lng': 74.8560},
    'MAQ': {'lat': 12.8700, 'lng': 74.8400},
    'TRZ': {'lat': 10.7905, 'lng': 78.7047},
    'TPJ': {'lat': 10.7900, 'lng': 78.7000},
    'RJA': {'lat': 17.0005, 'lng': 81.8040},
    'RJY': {'lat': 17.0100, 'lng': 81.7900},
  };

  @override
  void initState() {
    super.initState();
    _stops = _generateStops(widget.ticket.boardingPoint, widget.ticket.destinationPoint, widget.ticket.type);
    _nextStop = _stops[1];
    
    // Auto-engage GPS tracking on load
    _startHardwareGPSTracking();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _positionStreamSub?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _markTripCompleted() async {
    HapticFeedback.heavyImpact();
    
    final updatedTicket = widget.ticket.copyWith(isCompleted: true);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    await ticketProvider.updateTicket(updatedTicket);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Journey Completed! 🎉',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'You have successfully arrived at ${widget.ticket.destinationPoint}.',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.3), width: 1),
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.pop(context);
  }

  List<String> _generateStops(String from, String to, String type) {
    final cleanFrom = TicketItem.getPlaceFullName(from);
    final cleanTo = TicketItem.getPlaceFullName(to);

    // 1. Flights: just boarding place and destination, absolutely nothing in between!
    if (type == 'flight') {
      return [cleanFrom, cleanTo];
    }

    // 2. Trains and Buses: generate intermediate stops dynamically using geographical projection
    final fromCoords = _getCityCoords(from);
    final toCoords = _getCityCoords(to);

    // If coordinates are invalid/default, fallback to standard list
    final bool isFromDefault = fromCoords['lat'] == 28.5562 && fromCoords['lng'] == 77.1000 && 
        from.trim().toUpperCase() != 'DEL' && from.trim().toUpperCase() != 'NDLS';
    final bool isToDefault = toCoords['lat'] == 28.5562 && toCoords['lng'] == 77.1000 && 
        to.trim().toUpperCase() != 'DEL' && to.trim().toUpperCase() != 'NDLS';

    if (isFromDefault || isToDefault) {
      return [cleanFrom, cleanTo];
    }

    final double latA = fromCoords['lat']!;
    final double lngA = fromCoords['lng']!;
    final double latB = toCoords['lat']!;
    final double lngB = toCoords['lng']!;

    final double uX = latB - latA;
    final double uY = lngB - lngA;
    final double lenSq = uX * uX + uY * uY;

    if (lenSq == 0) return [cleanFrom, cleanTo];

    // List of candidate intermediate stop cities in India (with their names and coords)
    final List<Map<String, dynamic>> candidates = [];
    _cityCoordsDB.forEach((key, coords) {
      final name = TicketItem.getPlaceFullName(key);
      if (name == cleanFrom || name == cleanTo) return;

      // Avoid adding duplicate names in candidates list
      if (candidates.any((c) => c['name'] == name)) return;

      candidates.add({
        'name': name,
        'lat': coords['lat']!,
        'lng': coords['lng']!,
      });
    });

    // Evaluate each candidate
    final List<Map<String, dynamic>> validStops = [];
    for (var c in candidates) {
      final double latC = c['lat'];
      final double lngC = c['lng'];

      final double vX = latC - latA;
      final double vY = lngC - lngA;

      // Projection factor t
      final double t = (vX * uX + vY * uY) / lenSq;

      // We want stops that are geographically between A and B
      if (t > 0.15 && t < 0.85) {
        // Perpendicular distance squared
        final double distSq = (vX * vX + vY * vY) - (t * t * lenSq);
        validStops.add({
          'name': c['name'],
          't': t,
          'distSq': distSq,
        });
      }
    }

    // Sort valid stops by perpendicular distance (closest to the path first)
    validStops.sort((a, b) => (a['distSq'] as double).compareTo(b['distSq'] as double));

    // Select the best 2-3 intermediate stops
    final int maxStops = 3;
    final List<Map<String, dynamic>> selectedStops = validStops.take(maxStops).toList();

    // Sort selected stops by t projection factor so they are in correct order from A to B
    selectedStops.sort((a, b) => (a['t'] as double).compareTo(b['t'] as double));

    final List<String> result = [cleanFrom];
    for (var s in selectedStops) {
      result.add(s['name'] as String);
    }
    result.add(cleanTo);

    return result;
  }

  Map<String, double> _getCityCoords(String cityCode) {
    final clean = cityCode.trim().toUpperCase();
    
    // 1. Direct code dictionary lookup
    if (_cityCoordsDB.containsKey(clean)) {
      return _cityCoordsDB[clean]!;
    }
    
    // 2. Fuzzy match to resolve multi-format user inputs or full city names
    final lower = clean.toLowerCase();
    
    const Map<String, Map<String, double>> cityNameCoords = {
      'delhi': {'lat': 28.5562, 'lng': 77.1000},
      'new delhi': {'lat': 28.6430, 'lng': 77.2201},
      'mumbai': {'lat': 19.0896, 'lng': 72.8656},
      'bangalore': {'lat': 13.1986, 'lng': 77.7066},
      'bengaluru': {'lat': 13.1986, 'lng': 77.7066},
      'chennai': {'lat': 12.9941, 'lng': 80.1807},
      'kolkata': {'lat': 22.6547, 'lng': 88.4467},
      'hyderabad': {'lat': 17.2403, 'lng': 78.4294},
      'secunderabad': {'lat': 17.4344, 'lng': 78.5015},
      'pune': {'lat': 18.5822, 'lng': 73.9197},
      'visakhapatnam': {'lat': 17.7282, 'lng': 83.2244},
      'vizag': {'lat': 17.7282, 'lng': 83.2244},
      'vijayawada': {'lat': 16.5062, 'lng': 80.6480},
      'tirupati': {'lat': 13.6288, 'lng': 79.4192},
      'guntur': {'lat': 16.3067, 'lng': 80.4365},
      'lucknow': {'lat': 26.7606, 'lng': 80.8893},
      'patna': {'lat': 25.5941, 'lng': 85.1376},
      'kochi': {'lat': 10.1520, 'lng': 76.4019},
      'goa': {'lat': 15.3797, 'lng': 73.8314},
      'amritsar': {'lat': 31.6340, 'lng': 74.8723},
      'guwahati': {'lat': 26.1445, 'lng': 91.7362},
      'bhopal': {'lat': 23.2599, 'lng': 77.4126},
      'indore': {'lat': 22.7196, 'lng': 75.8577},
      'nagpur': {'lat': 21.1458, 'lng': 79.0882},
      'coimbatore': {'lat': 11.0168, 'lng': 76.9558},
      'chandigarh': {'lat': 30.7333, 'lng': 76.7794},
      'surat': {'lat': 21.1702, 'lng': 72.8311},
      'vadodara': {'lat': 22.3072, 'lng': 73.1812},
      'trivandrum': {'lat': 8.5241, 'lng': 76.9366},
      'thiruvananthapuram': {'lat': 8.5241, 'lng': 76.9366},
      'madurai': {'lat': 9.9252, 'lng': 78.1198},
      'bhubaneswar': {'lat': 20.2961, 'lng': 85.8245},
      'ranchi': {'lat': 23.3441, 'lng': 85.3096},
      'raipur': {'lat': 21.2514, 'lng': 81.6296},
      'dehradun': {'lat': 30.3165, 'lng': 78.0322},
      'varanasi': {'lat': 25.3176, 'lng': 82.9739},
      'kanpur': {'lat': 26.4499, 'lng': 80.3319},
      'agra': {'lat': 27.1767, 'lng': 78.0081},
      'jhansi': {'lat': 25.4484, 'lng': 78.5685},
      'jabalpur': {'lat': 22.1700, 'lng': 79.9300},
      'prayagraj': {'lat': 25.4358, 'lng': 81.8463},
      'allahabad': {'lat': 25.4358, 'lng': 81.8463},
      'gwalior': {'lat': 26.2124, 'lng': 78.1772},
      'srinagar': {'lat': 34.0837, 'lng': 74.7973},
      'jammu': {'lat': 32.7266, 'lng': 74.8570},
      'jodhpur': {'lat': 26.2389, 'lng': 73.0243},
      'udaipur': {'lat': 24.5854, 'lng': 73.7125},
      'calicut': {'lat': 11.2588, 'lng': 75.7804},
      'mangalore': {'lat': 12.9141, 'lng': 74.8560},
      'trichy': {'lat': 10.7905, 'lng': 78.7047},
      'rajahmundry': {'lat': 17.0005, 'lng': 81.8040},
      'suryapet': {'lat': 17.1500, 'lng': 79.6200},
      'kodad': {'lat': 16.9946, 'lng': 79.9691},
      'nandigama': {'lat': 16.7725, 'lng': 80.2917},
    };

    for (var entry in cityNameCoords.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default fallback to New Delhi
    return {'lat': 28.5562, 'lng': 77.1000};
  }

  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // Earth radius in km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180.0;
  }

  double _calculateRouteProgress({
    required double userLat,
    required double userLng,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final double abX = endLat - startLat;
    final double abY = endLng - startLng;
    final double apX = userLat - startLat;
    final double apY = userLng - startLng;
    
    final double abLenSq = abX * abX + abY * abY;
    if (abLenSq == 0) return 0.0;
    
    double t = (apX * abX + apY * abY) / abLenSq;
    if (t < 0.0) t = 0.0;
    if (t > 1.0) t = 1.0;
    return t;
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location services are disabled. Please enable them in settings.')));
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')));
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      }
      return false;
    }

    return true;
  }

  void _updateETA() {
    if (_simulationProgress >= 1.0 || _distanceRemaining <= 0) {
      _etaText = 'Arrived';
      return;
    }

    double speed = _currentSpeed;
    if (speed <= 5) {
      speed = widget.ticket.type == 'flight' 
          ? 800.0 
          : (widget.ticket.type == 'train' ? 100.0 : 60.0);
    }

    final double hoursRemaining = _distanceRemaining / speed;
    final int totalMinutes = (hoursRemaining * 60).round();
    
    if (totalMinutes <= 0) {
      _etaText = 'Arrived';
      return;
    }

    final etaDateTime = DateTime.now().add(Duration(minutes: totalMinutes));
    final formattedEta = intl.DateFormat('hh:mm a').format(etaDateTime);
    
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      _etaText = '${hours}h ${mins}m\n($formattedEta)';
    } else {
      _etaText = '${totalMinutes}m\n($formattedEta)';
    }
  }

  void _startHardwareGPSTracking() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() => _isSimulating = true);
      _startTelemetrySimulation();
      return;
    }

    // Cancel simulator stream
    _simTimer?.cancel();
    _positionStreamSub?.cancel();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (!mounted || _isSimulating) return;

      setState(() {
        final fromCoords = _getCityCoords(widget.ticket.boardingPoint);
        final toCoords = _getCityCoords(widget.ticket.destinationPoint);

        _simulationProgress = _calculateRouteProgress(
          userLat: position.latitude,
          userLng: position.longitude,
          startLat: fromCoords['lat']!,
          startLng: fromCoords['lng']!,
          endLat: toCoords['lat']!,
          endLng: toCoords['lng']!,
        );

        _currentSpeed = position.speed * 3.6; // convert m/s to km/h
        _altitude = position.altitude;
        _currentStatus = 'Tracking with physical device GPS';

        // Calculate actual physical distance remaining using high-fidelity Haversine
        final remainingKm = _calculateHaversineDistance(
          position.latitude,
          position.longitude,
          toCoords['lat']!,
          toCoords['lng']!,
        );
        _distanceRemaining = remainingKm.roundToDouble();

        // Calculate progress steps dynamically
        final totalStops = _stops.length;
        final stopSpan = 1.0 / (totalStops - 1);
        
        if (_distanceRemaining < 2.0 || _simulationProgress >= 0.99) {
          _simulationProgress = 1.0;
          _nextStop = 'Destination Arrived';
          _distanceRemaining = 0;
          _completedStopsCount = totalStops - 1;
        } else {
          _completedStopsCount = (_simulationProgress / stopSpan).floor();
          if (_completedStopsCount >= totalStops - 1) {
            _completedStopsCount = totalStops - 2;
          }
          _nextStop = _stops[_completedStopsCount + 1];
        }
        _updateETA();
      });
    }, onError: (err) {
      debugPrint('[GPS Tracker] Stream error: $err');
    });
  }

  void _startTelemetrySimulation() {
    _positionStreamSub?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) return;

      setState(() {
        if (_isSimulating) {
          _simulationProgress += 0.015;
          if (_simulationProgress >= 1.0) {
            _simulationProgress = 1.0;
            _simTimer?.cancel();
          }
        }

        final totalStops = _stops.length;
        final stopSpan = 1.0 / (totalStops - 1);
        _completedStopsCount = (_simulationProgress / stopSpan).floor();
        
        if (_completedStopsCount >= totalStops - 1) {
          _nextStop = 'Destination Arrived';
          _currentStatus = 'Welcome to your destination!';
          _distanceRemaining = 0;
          _currentSpeed = 0;
          _altitude = 0;
        } else {
          _nextStop = _stops[_completedStopsCount + 1];
          final simLatLng = _getSimulatedLatLng(_simulationProgress);
          final toCoords = _getCityCoords(widget.ticket.destinationPoint);
          final remainingKm = _calculateHaversineDistance(
            simLatLng['lat']!,
            simLatLng['lng']!,
            toCoords['lat']!,
            toCoords['lng']!,
          );
          _distanceRemaining = remainingKm.roundToDouble();

          final rand = math.Random();
          if (widget.ticket.type == 'flight') {
            _currentSpeed = 780 + rand.nextDouble() * 60;
            _altitude = _simulationProgress < 0.15 
                ? (_simulationProgress / 0.15) * 32000 
                : _simulationProgress > 0.85 
                    ? ((1.0 - _simulationProgress) / 0.15) * 32000 
                    : 32000 + (rand.nextDouble() * 200);
            _currentStatus = _simulationProgress < 0.15 
                ? 'Ascending to cruising altitude...' 
                : _simulationProgress > 0.85 
                    ? 'Descending for approach...' 
                    : 'Cruising smoothly at 32,000 ft';
          } else if (widget.ticket.type == 'train') {
            _currentSpeed = 95 + rand.nextDouble() * 25;
            _altitude = 0.0;
            _currentStatus = 'En route at high speed';
          } else {
            _currentSpeed = 65 + rand.nextDouble() * 15;
            _altitude = 0.0;
            _currentStatus = 'Cruising national highway';
          }
        }
        _updateETA();
      });
    });
  }

  Map<String, double> _getSimulatedLatLng(double t) {
    if (_stops.isEmpty) return {'lat': 0.0, 'lng': 0.0};
    if (_stops.length < 2) return _getCityCoords(_stops.first);
    
    final List<Map<String, double>> coords = _stops.map((s) => _getCityCoords(s)).toList();
    final double scaledT = t * (coords.length - 1);
    final int index = scaledT.floor().clamp(0, coords.length - 2);
    final double localT = scaledT - index;

    final p0 = coords[index];
    final p1 = coords[index + 1];

    final cp1Lat = p0['lat']! - (p0['lat']! - p1['lat']!) / 2;
    final cp1Lng = p0['lng']! - (p0['lng']! - p1['lng']!) / 2;
    final cp2Lat = p1['lat']! + (p0['lat']! - p1['lat']!) / 2;
    final cp2Lng = p1['lng']! + (p0['lng']! - p1['lng']!) / 2;

    final double mt = 1.0 - localT;
    final double mt2 = mt * mt;
    final double mt3 = mt2 * mt;
    final double t2 = localT * localT;
    final double t3 = t2 * localT;

    final double lat = mt3 * p0['lat']! + 
                     3.0 * mt2 * localT * cp1Lat + 
                     3.0 * mt * t2 * cp2Lat + 
                     t3 * p1['lat']!;
                     
    final double lng = mt3 * p0['lng']! + 
                     3.0 * mt2 * localT * cp1Lng + 
                     3.0 * mt * t2 * cp2Lng + 
                     t3 * p1['lng']!;

    return {'lat': lat, 'lng': lng};
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.ticket.type == 'flight' 
        ? AppTheme.primaryPurple 
        : widget.ticket.type == 'train' 
            ? Colors.redAccent 
            : Colors.greenAccent;

    final typeIcon = widget.ticket.type == 'flight' 
        ? LucideIcons.plane 
        : widget.ticket.type == 'train' 
            ? LucideIcons.train 
            : LucideIcons.bus;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: _GridBackground(themeColor: themeColor),
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: Material(
                        color: Colors.white10,
                        child: IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Journey Map',
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.ticket.boardingPointName} ➔ ${widget.ticket.destinationPointName}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    _buildPulseIndicator(themeColor),
                  ],
                ),
              ),
              Expanded(
                child: _LiveRouteMapCanvas(
                  stops: _stops,
                  progress: _simulationProgress,
                  pulseVal: _progressController,
                  themeColor: themeColor,
                  typeIcon: typeIcon,
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).padding.bottom + 20),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(color: Colors.white10, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.navigation, color: themeColor, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _currentStatus,
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(_simulationProgress * 100).toInt()}% Done',
                            style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTelemetryItem(
                            icon: LucideIcons.gauge,
                            label: 'Speed',
                            value: '${_currentSpeed.toInt()} km/h',
                            color: themeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.ticket.type == 'flight')
                          Expanded(
                            child: _buildTelemetryItem(
                              icon: LucideIcons.chevronsUp,
                              label: 'Altitude',
                              value: '${_altitude.toInt()} ft',
                              color: Colors.blueAccent,
                            ),
                          )
                        else
                          Expanded(
                            child: _buildTelemetryItem(
                              icon: LucideIcons.mapPin,
                              label: 'Next Stop',
                              value: _nextStop,
                              color: Colors.amberAccent,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTelemetryItem(
                            icon: LucideIcons.hourglass,
                            label: 'Remaining',
                            value: '${_distanceRemaining.toInt()} km',
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTelemetryItem(
                            icon: LucideIcons.clock,
                            label: 'Reaching',
                            value: _etaText,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phone GPS Tracking',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isSimulating ? 'Simulating transit speed...' : 'Tracking with physical GPS...',
                                style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                'Simulate',
                                style: TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Switch.adaptive(
                                value: _isSimulating,
                                activeColor: themeColor,
                                onChanged: (v) {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    _isSimulating = v;
                                    if (_isSimulating) {
                                      _startTelemetrySimulation();
                                    } else {
                                      _startHardwareGPSTracking();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                                  // Reached Destination Slider
                    Builder(
                      builder: (context) {
                        final hasReached = _simulationProgress >= 0.99 || _distanceRemaining <= 0;
                        final isCompleted = widget.ticket.isCompleted;
                        
                        return _SlideToComplete(
                          from: widget.ticket.boardingPoint,
                          to: widget.ticket.destinationPoint,
                          icon: typeIcon,
                          themeColor: themeColor,
                          isCompleted: isCompleted,
                          isLocked: !hasReached && !isCompleted,
                          onCompleted: _markTripCompleted,
                        );
                      }
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isSimulating ? Colors.redAccent.withValues(alpha: 0.1) : Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isSimulating ? Colors.redAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.activity, color: _isSimulating ? Colors.redAccent : Colors.greenAccent, size: 12),
          const SizedBox(width: 6),
          Text(
            _isSimulating ? 'SIMULATION' : 'GPS REALTIME',
            style: TextStyle(color: _isSimulating ? Colors.redAccent : Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _LiveRouteMapCanvas extends StatelessWidget {
  final List<String> stops;
  final double progress;
  final Animation<double> pulseVal;
  final Color themeColor;
  final IconData typeIcon;

  const _LiveRouteMapCanvas({
    required this.stops,
    required this.progress,
    required this.pulseVal,
    required this.themeColor,
    required this.typeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseVal,
      builder: (context, _) {
        return CustomPaint(
          painter: _RoutePainter(
            stops: stops,
            progress: progress,
            pulse: pulseVal.value,
            themeColor: themeColor,
          ),
        );
      },
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<String> stops;
  final double progress;
  final double pulse;
  final Color themeColor;

  _RoutePainter({
    required this.stops,
    required this.progress,
    required this.pulse,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.5;
    
    // Flat 2D layout boundaries (Start at bottom, flow upwards to top)
    final double startY = size.height * 0.85;
    final double endY = size.height * 0.15;
    final double pathLength = endY - startY;

    // Generate Flat Spline Nodes for Bezier curve calculations
    final List<Offset> nodes = [];
    final totalStops = stops.length;
    final divisor = totalStops > 1 ? totalStops - 1 : 1;
    
    for (int i = 0; i < totalStops; i++) {
      final t = i / divisor;
      final y = startY + t * pathLength; 
      final x = centerX + 48.0 * math.sin(t * math.pi * 2.2);
      nodes.add(Offset(x, y));
    }

    // Spline evaluator for high-resolution smooth curves
    Offset getBezierPoint(List<Offset> nodes, double t) {
      if (nodes.length < 2) return Offset.zero;
      
      final double scaledT = t * (nodes.length - 1);
      final int index = scaledT.floor().clamp(0, nodes.length - 2);
      final double localT = scaledT - index;

      final p0 = nodes[index];
      final p1 = nodes[index + 1];

      final controlPoint1 = Offset(p0.dx, p0.dy - (p0.dy - p1.dy) / 2);
      final controlPoint2 = Offset(p1.dx, p1.dy + (p0.dy - p1.dy) / 2);

      final double mt = 1.0 - localT;
      final double mt2 = mt * mt;
      final double mt3 = mt2 * mt;
      final double t2 = localT * localT;
      final double t3 = t2 * localT;

      final double x = mt3 * p0.dx + 
                       3.0 * mt2 * localT * controlPoint1.dx + 
                       3.0 * mt * t2 * controlPoint2.dx + 
                       t3 * p1.dx;
                       
      final double y = mt3 * p0.dy + 
                       3.0 * mt2 * localT * controlPoint1.dy + 
                       3.0 * mt * t2 * controlPoint2.dy + 
                       t3 * p1.dy;

      return Offset(x, y);
    }

    // Generate high-resolution curve points for drawing and tracking
    final List<Offset> curvePoints = [];
    final int curveSamples = 100;
    for (int i = 0; i <= curveSamples; i++) {
      final double t = i / curveSamples;
      curvePoints.add(getBezierPoint(nodes, t));
    }

    // -------------------------------------------------------------------------
    // 2. Draw Clean, Solid Background Track (Inactive portion)
    // -------------------------------------------------------------------------
    final backgroundPath = Path();
    if (curvePoints.isNotEmpty) {
      backgroundPath.moveTo(curvePoints[0].dx, curvePoints[0].dy);
      for (int i = 1; i < curvePoints.length; i++) {
        backgroundPath.lineTo(curvePoints[i].dx, curvePoints[i].dy);
      }
    }

    canvas.drawPath(backgroundPath, Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0);

    // -------------------------------------------------------------------------
    // 3. Draw Active Progress Track (Clean, Smooth Neon Curve with Glow)
    // -------------------------------------------------------------------------
    final activePath = Path();
    final double maxActiveIdx = curveSamples * progress;
    final int baseIdx = maxActiveIdx.floor();
    final double frac = maxActiveIdx - baseIdx;

    if (curvePoints.isNotEmpty && progress > 0) {
      activePath.moveTo(curvePoints[0].dx, curvePoints[0].dy);
      for (int i = 1; i <= baseIdx; i++) {
        activePath.lineTo(curvePoints[i].dx, curvePoints[i].dy);
      }
      if (frac > 0 && baseIdx < curvePoints.length - 1) {
        final Offset p1 = curvePoints[baseIdx];
        final Offset nextPt = curvePoints[baseIdx + 1];
        final Offset p2 = Offset(p1.dx + (nextPt.dx - p1.dx) * frac, p1.dy + (nextPt.dy - p1.dy) * frac);
        activePath.lineTo(p2.dx, p2.dy);
      }
    }

    if (progress > 0) {
      // Glow Outer Layer
      canvas.drawPath(activePath, Paint()
        ..color = themeColor.withValues(alpha: 0.24)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0);

      // Core Neon Layer
      canvas.drawPath(activePath, Paint()
        ..color = themeColor
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0);
    }

    // -------------------------------------------------------------------------
    // 4. Draw Traveler Locator Dot (Centered on progress)
    // -------------------------------------------------------------------------
    if (curvePoints.isNotEmpty) {
      final Offset locatorPos = getBezierPoint(nodes, progress.clamp(0.0, 1.0));

      // Expanding concentric radar wave
      canvas.drawCircle(locatorPos, 28.0 * pulse, Paint()
        ..color = themeColor.withValues(alpha: 0.16 * (1.0 - pulse))
        ..style = PaintingStyle.fill);

      // Glowing locator orb
      canvas.drawCircle(locatorPos, 9.0, Paint()
        ..color = themeColor
        ..style = PaintingStyle.fill);

      // White high-contrast ring
      canvas.drawCircle(locatorPos, 9.0, Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke);
    }

    // -------------------------------------------------------------------------
    // 5. Draw Station Nodes & Elegant Typography Labels
    // -------------------------------------------------------------------------
    for (int i = 0; i < nodes.length; i++) {
      final Offset nodePos = nodes[i];
      final stopKey = i / divisor;
      final isVisited = progress >= stopKey;
      final nodeColor = isVisited ? themeColor : AppTheme.textGrey;

      // Glowing visited halo outer bubble
      canvas.drawCircle(nodePos, 14.0, Paint()
        ..color = isVisited ? themeColor.withValues(alpha: 0.18) : Colors.white12
        ..style = PaintingStyle.fill);

      // Inner white / dark core
      canvas.drawCircle(nodePos, 5.5, Paint()
        ..color = isVisited ? Colors.white : AppTheme.bgDark
        ..style = PaintingStyle.fill);

      // Outer border circle stroke
      canvas.drawCircle(nodePos, 5.5, Paint()
        ..color = nodeColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke);

      // Draw elegant Text Label
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: stops[i],
          style: TextStyle(
            color: isVisited ? Colors.white : AppTheme.textGrey.withValues(alpha: 0.85),
            fontSize: 11.5,
            fontWeight: isVisited ? FontWeight.bold : FontWeight.w500,
            shadows: isVisited ? [
              Shadow(color: themeColor.withValues(alpha: 0.6), blurRadius: 4.0),
            ] : null,
          ),
        ),
      );
      textPainter.layout();

      // Alternate label placing (left or right of curves to maximize visibility)
      final labelOffset = i % 2 == 0
          ? Offset(nodePos.dx + 20.0, nodePos.dy - 6.0)
          : Offset(nodePos.dx - textPainter.width - 20.0, nodePos.dy - 6.0);

      textPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SlideToComplete extends StatefulWidget {
  final VoidCallback onCompleted;
  final String from;
  final String to;
  final IconData icon;
  final Color themeColor;
  final bool isCompleted;
  final bool isLocked;

  const _SlideToComplete({
    required this.onCompleted,
    required this.from,
    required this.to,
    required this.icon,
    required this.themeColor,
    this.isCompleted = false,
    this.isLocked = false,
  });

  @override
  State<_SlideToComplete> createState() => _SlideToCompleteState();
}

class _SlideToCompleteState extends State<_SlideToComplete> with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  bool _isFinished = false;

  late final AnimationController _snapController;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDistance) {
    if (widget.isCompleted || widget.isLocked || _isFinished) return;
    
    setState(() {
      _dragValue = (_dragValue + details.delta.dx / maxDistance).clamp(0.0, 1.0);
    });
  }

  void _onDragEnd() async {
    if (widget.isCompleted || widget.isLocked || _isFinished) return;

    if (_dragValue >= 0.9) {
      // Complete!
      setState(() {
        _dragValue = 1.0;
        _isFinished = true;
      });
      HapticFeedback.heavyImpact();
      widget.onCompleted();
    } else {
      // Snap back!
      _snapController.duration = Duration(milliseconds: (200 * _dragValue).toInt().clamp(50, 250));
      final double startVal = _dragValue;
      _snapController.reset();
      _snapController.addListener(() {
        setState(() {
          _dragValue = startVal * (1.0 - _snapController.value);
        });
      });
      await _snapController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        const double buttonSize = 50.0;
        final double maxDistance = trackWidth - buttonSize - 8.0; // 4px padding on each side

        if (widget.isCompleted) {
          _dragValue = 1.0;
        }

        return Container(
          width: double.infinity,
          height: 58,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.isCompleted
                ? Colors.white10
                : (widget.isLocked 
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.white.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(29),
            border: Border.all(
              color: widget.isCompleted
                  ? Colors.white10
                  : (widget.isLocked 
                      ? Colors.white12
                      : widget.themeColor.withValues(alpha: 0.2)),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Starting label ("FROM" city code) - shifted right so it never overlaps the start position of the button
              Positioned(
                left: 64,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Opacity(
                    opacity: (1.0 - _dragValue * 2.5).clamp(0.0, 1.0),
                    child: Text(
                      widget.from,
                      style: TextStyle(
                        color: widget.isCompleted
                            ? Colors.white30
                            : (widget.isLocked
                                ? Colors.white24
                                : widget.themeColor.withValues(alpha: 0.8)),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Ending label ("TO" city code) - shifted left so it never overlaps the end position of the button
              Positioned(
                right: 64,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Opacity(
                    opacity: (1.0 - (_dragValue - 0.6).clamp(0.0, 0.4) / 0.4).clamp(0.0, 1.0),
                    child: Text(
                      widget.to,
                      style: TextStyle(
                        color: widget.isCompleted
                            ? Colors.white30
                            : (widget.isLocked
                                ? Colors.white24
                                : widget.themeColor.withValues(alpha: 0.9)),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Sliding Text Instruction
              Center(
                child: Opacity(
                  opacity: (1.0 - _dragValue * 1.5).clamp(0.0, 1.0),
                  child: Text(
                    widget.isLocked 
                        ? 'IN TRANSIT (LOCKED)' 
                        : (widget.isCompleted ? 'JOURNEY COMPLETED' : 'SLIDE TO END TRIP'),
                    style: TextStyle(
                      color: widget.isLocked ? Colors.white30 : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

              // Sliding Thumb (The Vehicle Button)
              Positioned(
                left: _dragValue * maxDistance,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDistance),
                  onHorizontalDragEnd: (details) => _onDragEnd(),
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: widget.isCompleted
                          ? Colors.white24
                          : (widget.isLocked
                              ? Colors.white10
                              : widget.themeColor),
                      shape: BoxShape.circle,
                      boxShadow: widget.isCompleted || widget.isLocked
                          ? null
                          : [
                              BoxShadow(
                                color: widget.themeColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.isCompleted || widget.isLocked
                          ? Colors.white30
                          : Colors.black,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridBackground extends StatelessWidget {
  final Color themeColor;
  const _GridBackground({required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(themeColor: themeColor),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color themeColor;
  _GridPainter({required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    // Vertical grid lines
    final int verticalGridLines = 10;
    for (int i = 0; i <= verticalGridLines; i++) {
      final double x = size.width * (i / verticalGridLines);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal grid lines
    final int horizontalGridLines = 14;
    for (int i = 0; i <= horizontalGridLines; i++) {
      final double y = size.height * (i / horizontalGridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
