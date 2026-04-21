class Property {
  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final String virtualTourUrl; // The 360 link
  bool isSaved;

  Property({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.virtualTourUrl,
    this.isSaved = false,
  });
}