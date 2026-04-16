class Property {
  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  bool isSaved; //  field to track the saved button

  Property({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.isSaved = false, // Defaults is not saved
  });
}