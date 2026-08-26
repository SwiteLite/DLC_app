import 'package:flutter/material.dart';

enum FoodStatus {
  active,
  eaten,
  discarded;

  String get label {
    switch (this) {
      case FoodStatus.active:
        return 'Actif';
      case FoodStatus.eaten:
        return 'Consommé';
      case FoodStatus.discarded:
        return 'Jeté';
    }
  }

  static FoodStatus fromName(String? value) {
    return FoodStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => FoodStatus.active,
    );
  }
}

enum FoodLocation {
  fridge,
  freezer,
  pantry,
  unspecified;

  String get label {
    switch (this) {
      case FoodLocation.fridge:
        return 'Frigo';
      case FoodLocation.freezer:
        return 'Congélateur';
      case FoodLocation.pantry:
        return 'Placard';
      case FoodLocation.unspecified:
        return 'Non précisé';
    }
  }

  IconData get icon {
    switch (this) {
      case FoodLocation.fridge:
        return Icons.kitchen;
      case FoodLocation.freezer:
        return Icons.ac_unit;
      case FoodLocation.pantry:
        return Icons.inventory_2;
      case FoodLocation.unspecified:
        return Icons.help_outline;
    }
  }

  static FoodLocation fromName(String? value) {
    return FoodLocation.values.firstWhere(
      (location) => location.name == value,
      orElse: () => FoodLocation.unspecified,
    );
  }
}

enum FoodUrgencyFilter {
  all,
  urgent,
  ok,
  expired;

  String get label {
    switch (this) {
      case FoodUrgencyFilter.all:
        return 'Tous';
      case FoodUrgencyFilter.urgent:
        return 'Urgents';
      case FoodUrgencyFilter.ok:
        return 'OK';
      case FoodUrgencyFilter.expired:
        return 'Expirés';
    }
  }
}

class Food {
  final String id;
  String name;
  DateTime expirationDate;
  DateTime dateAdded;
  FoodStatus status;
  FoodLocation location;
  String? imageUrl;
  String? barcode;

  Food({
    required this.id,
    required this.name,
    required this.expirationDate,
    required this.dateAdded,
    this.status = FoodStatus.active,
    this.location = FoodLocation.unspecified,
    this.imageUrl,
    this.barcode,
  });

  int daysUntilExpiration([DateTime? now]) {
    final reference = now ?? DateTime.now();
    final todayOnly = DateTime(reference.year, reference.month, reference.day);
    final expiryOnly = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    return expiryOnly.difference(todayOnly).inDays;
  }

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String,
      expirationDate: DateTime.parse(json['expirationDate'] as String),
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      status: FoodStatus.fromName(json['status'] as String?),
      location: FoodLocation.fromName(json['location'] as String?),
      imageUrl: json['imageUrl'] as String?,
      barcode: json['barcode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expirationDate': expirationDate.toIso8601String(),
      'dateAdded': dateAdded.toIso8601String(),
      'status': status.name,
      'location': location.name,
      'imageUrl': imageUrl,
      'barcode': barcode,
    };
  }

  Food copyWith({
    String? name,
    DateTime? expirationDate,
    FoodStatus? status,
    FoodLocation? location,
    String? imageUrl,
    String? barcode,
  }) {
    return Food(
      id: id,
      name: name ?? this.name,
      expirationDate: expirationDate ?? this.expirationDate,
      dateAdded: dateAdded,
      status: status ?? this.status,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
    );
  }
}
