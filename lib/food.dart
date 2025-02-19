
class Food {
  String name;
  DateTime expirationDate;
  DateTime dateAdded = DateTime.now();
  
  Food({
    required this.name, 
    required this.expirationDate,
    required this.dateAdded,
  });
  
}