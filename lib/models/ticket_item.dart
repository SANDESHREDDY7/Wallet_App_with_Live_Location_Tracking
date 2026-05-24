import 'dart:convert';

class TicketItem {
  final String id;
  final String type; // 'flight' | 'train' | 'bus'
  final String title; // Airline name, Train name/number, Bus operator
  final String passengerName;
  final String pnr; // PNR / Booking Ref
  final String boardingPoint;
  final String destinationPoint;
  final DateTime date;
  final String seatNumber; // Seat / Berth / Class details
  final String? pdfPath;
  final String? imagePath;
  final bool isCompleted;

  String get boardingPointName => getPlaceFullName(boardingPoint);
  String get destinationPointName => getPlaceFullName(destinationPoint);

  static String getPlaceFullName(String codeOrName) {
    final clean = codeOrName.trim().toUpperCase();
    switch (clean) {
      case 'DEL':
      case 'NDLS':
        return 'New Delhi';
      case 'BOM':
      case 'CSMT':
        return 'Mumbai';
      case 'BLR':
      case 'SBC':
        return 'Bengaluru';
      case 'MAA':
      case 'MAS':
        return 'Chennai';
      case 'CCU':
      case 'HWH':
        return 'Kolkata';
      case 'HYD':
      case 'HYB':
      case 'SC':
      case 'KCG':
        return 'Hyderabad';
      case 'PNQ':
      case 'PUNE':
        return 'Pune';
      case 'VTZ':
      case 'VSKP':
        return 'Visakhapatnam';
      case 'VGA':
      case 'BZA':
        return 'Vijayawada';
      case 'TPTY':
      case 'RU':
        return 'Tirupati';
      case 'GNT':
        return 'Guntur';
      case 'LKO':
        return 'Lucknow';
      case 'GOI':
        return 'Goa';
      case 'AMD':
        return 'Ahmedabad';
      case 'COK':
        return 'Kochi';
      case 'JAI':
        return 'Jaipur';
      default:
        // Return titlecased if length > 4
        if (codeOrName.length > 4) {
          return codeOrName.split(' ').map((str) {
            if (str.isEmpty) return str;
            return str[0].toUpperCase() + str.substring(1).toLowerCase();
          }).join(' ');
        }
        return codeOrName;
    }
  }

  TicketItem({
    required this.id,
    required this.type,
    required this.title,
    required this.passengerName,
    required this.pnr,
    required this.boardingPoint,
    required this.destinationPoint,
    required this.date,
    required this.seatNumber,
    this.pdfPath,
    this.imagePath,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'passengerName': passengerName,
      'pnr': pnr,
      'boardingPoint': boardingPoint,
      'destinationPoint': destinationPoint,
      'date': date.toIso8601String(),
      'seatNumber': seatNumber,
      'pdfPath': pdfPath,
      'imagePath': imagePath,
      'isCompleted': isCompleted,
    };
  }

  factory TicketItem.fromMap(Map<String, dynamic> map) {
    return TicketItem(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      passengerName: map['passengerName'] as String,
      pnr: map['pnr'] as String,
      boardingPoint: map['boardingPoint'] as String,
      destinationPoint: map['destinationPoint'] as String,
      date: DateTime.parse(map['date'] as String),
      seatNumber: map['seatNumber'] as String,
      pdfPath: map['pdfPath'] as String?,
      imagePath: map['imagePath'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory TicketItem.fromJson(String source) => TicketItem.fromMap(json.decode(source) as Map<String, dynamic>);

  TicketItem copyWith({
    String? id,
    String? type,
    String? title,
    String? passengerName,
    String? pnr,
    String? boardingPoint,
    String? destinationPoint,
    DateTime? date,
    String? seatNumber,
    String? pdfPath,
    String? imagePath,
    bool? isCompleted,
    bool clearPdf = false,
    bool clearImage = false,
  }) {
    return TicketItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      passengerName: passengerName ?? this.passengerName,
      pnr: pnr ?? this.pnr,
      boardingPoint: boardingPoint ?? this.boardingPoint,
      destinationPoint: destinationPoint ?? this.destinationPoint,
      date: date ?? this.date,
      seatNumber: seatNumber ?? this.seatNumber,
      pdfPath: clearPdf ? null : (pdfPath ?? this.pdfPath),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
