
class Food {
  String name;
  DateTime expirationDate;
  DateTime dateAdded = DateTime.now();
  
  Food({
    required this.name, 
    required this.expirationDate,
    required this.dateAdded,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['name'],
      expirationDate: DateTime.parse(json['expirationDate']),
      dateAdded: DateTime.parse(json['dateAdded']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'expirationDate': expirationDate.toIso8601String(),
      'dateAdded': dateAdded.toIso8601String(),
    };
  }
  
}

