class Property {
  final String id;
  final String houseType; // This is now the main name (Detached, Apartment, etc.)
  final String location;
  final double monthlyPrice;
  final double totalPrice;
  final String imageUrl;
  final String virtualTourUrl;
  final String sellerId;
  final String sellerName;
  final String sellerPhoto;
  final String description;
  final int rooms;
  final int baths;
  final int wetKitchen;
  final int dryKitchen;
  final int livingRoom;
  bool isSaved;

  Property({
    required this.id, required this.houseType, required this.location,
    required this.monthlyPrice, required this.totalPrice, required this.imageUrl,
    required this.virtualTourUrl, required this.sellerId, required this.sellerName,
    required this.sellerPhoto, required this.description, required this.rooms,
    required this.baths, required this.wetKitchen, required this.dryKitchen,
    required this.livingRoom, this.isSaved = false,
  });

  factory Property.fromMap(Map<String, dynamic> data, String documentId) {
    return Property(
      id: documentId,
      houseType: data['houseType'] ?? 'Property',
      location: data['location'] ?? '',
      monthlyPrice: (data['monthlyPrice'] ?? 0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      virtualTourUrl: data['virtualTourUrl'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Landlord',
      sellerPhoto: data['sellerPhoto'] ?? '',
      description: data['description'] ?? '',
      rooms: data['rooms'] ?? 0,
      baths: data['baths'] ?? 0,
      wetKitchen: data['wetKitchen'] ?? 0,
      dryKitchen: data['dryKitchen'] ?? 0,
      livingRoom: data['livingRoom'] ?? 0,
    );
  }
}