class AppUser {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String? profileImage;
  final bool isAdmin;

  AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.profileImage,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'profileImage': profileImage,
        'isAdmin': isAdmin ? 1 : 0,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as int?,
        name: m['name'] as String,
        email: m['email'] as String,
        phone: m['phone'] as String,
        password: m['password'] as String,
        profileImage: m['profileImage'] as String?,
        isAdmin: (m['isAdmin'] as int? ?? 0) == 1,
      );

  AppUser copyWith({String? name, String? phone, String? profileImage}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        password: password,
        profileImage: profileImage ?? this.profileImage,
        isAdmin: isAdmin,
      );
}

class BusRoute {
  final int? id;
  final String source;
  final String destination;
  final String stops; // comma separated
  final double distanceKm;

  BusRoute({
    this.id,
    required this.source,
    required this.destination,
    required this.stops,
    required this.distanceKm,
  });

  List<String> get stopList => stops.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Map<String, dynamic> toMap() => {
        'id': id,
        'source': source,
        'destination': destination,
        'stops': stops,
        'distanceKm': distanceKm,
      };

  factory BusRoute.fromMap(Map<String, dynamic> m) => BusRoute(
        id: m['id'] as int?,
        source: m['source'] as String,
        destination: m['destination'] as String,
        stops: m['stops'] as String,
        distanceKm: (m['distanceKm'] as num).toDouble(),
      );
}

class Bus {
  final int? id;
  final String busNumber;
  final String busName;
  final String driverName;
  final String? busImage;
  final int? routeId;
  final double lastLat;
  final double lastLng;

  Bus({
    this.id,
    required this.busNumber,
    required this.busName,
    required this.driverName,
    this.busImage,
    this.routeId,
    this.lastLat = 13.0827,
    this.lastLng = 80.2707,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'busNumber': busNumber,
        'busName': busName,
        'driverName': driverName,
        'busImage': busImage,
        'routeId': routeId,
        'lastLat': lastLat,
        'lastLng': lastLng,
      };

  factory Bus.fromMap(Map<String, dynamic> m) => Bus(
        id: m['id'] as int?,
        busNumber: m['busNumber'] as String,
        busName: m['busName'] as String,
        driverName: m['driverName'] as String,
        busImage: m['busImage'] as String?,
        routeId: m['routeId'] as int?,
        lastLat: (m['lastLat'] as num?)?.toDouble() ?? 13.0827,
        lastLng: (m['lastLng'] as num?)?.toDouble() ?? 80.2707,
      );

  Bus copyWithLocation(double lat, double lng) => Bus(
        id: id,
        busNumber: busNumber,
        busName: busName,
        driverName: driverName,
        busImage: busImage,
        routeId: routeId,
        lastLat: lat,
        lastLng: lng,
      );
}

class BusStop {
  final String name;
  final double lat;
  final double lng;
  BusStop({required this.name, required this.lat, required this.lng});
}

class Report {
  final int? id;
  final int userId;
  final String? photoPath;
  final String? audioPath;
  final String description;
  final String issueType;
  final double lat;
  final double lng;
  final String reportTime;

  Report({
    this.id,
    required this.userId,
    this.photoPath,
    this.audioPath,
    required this.description,
    required this.issueType,
    required this.lat,
    required this.lng,
    required this.reportTime,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'photoPath': photoPath,
        'audioPath': audioPath,
        'description': description,
        'issueType': issueType,
        'lat': lat,
        'lng': lng,
        'reportTime': reportTime,
      };

  factory Report.fromMap(Map<String, dynamic> m) => Report(
        id: m['id'] as int?,
        userId: m['userId'] as int,
        photoPath: m['photoPath'] as String?,
        audioPath: m['audioPath'] as String?,
        description: m['description'] as String,
        issueType: m['issueType'] as String,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        reportTime: m['reportTime'] as String,
      );
}

class TripHistory {
  final int? id;
  final int userId;
  final String busNumber;
  final String route;
  final String date;
  final String time;

  TripHistory({
    this.id,
    required this.userId,
    required this.busNumber,
    required this.route,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'busNumber': busNumber,
        'route': route,
        'date': date,
        'time': time,
      };

  factory TripHistory.fromMap(Map<String, dynamic> m) => TripHistory(
        id: m['id'] as int?,
        userId: m['userId'] as int,
        busNumber: m['busNumber'] as String,
        route: m['route'] as String,
        date: m['date'] as String,
        time: m['time'] as String,
      );
}
