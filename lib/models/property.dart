class Property {
  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  bool isLiked; // New field to track the heart button

  Property({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.isLiked = false, // Defaults to not liked
  });
}