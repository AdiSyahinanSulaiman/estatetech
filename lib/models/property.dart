class Property {
  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final String virtualTourUrl;
  final String sellerId;
  final String sellerName;
  final String sellerPhoto;
  final String houseType;
  bool isSaved; // This must not be final so we can change it

  Property({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.virtualTourUrl,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhoto,
    required this.houseType,
    this.isSaved = false,
  });

  factory Property.fromMap(Map<String, dynamic> data, String documentId) {
    return Property(
      id: documentId,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      virtualTourUrl: data['virtualTourUrl'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Landlord',
      sellerPhoto: data['sellerPhoto'] ?? '',
      houseType: data['houseType'] ?? 'Other',
      isSaved: false,
    );
  }
}