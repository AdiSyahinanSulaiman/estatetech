import '../models/property.dart';

// This is our central "database" for now
List<Property> globalProperties = [
  Property(
    id: '1',
    title: 'Modern Luxury Villa',
    location: 'Beverly Hills, CA',
    price: 2500.00,
    imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000&auto=format&fit=crop',
    // High-quality 360 room photo
    virtualTourUrl: 'https://pannellum.org/images/alma.jpg',
    isSaved: false,
  ),
  Property(
    id: '2',
    title: 'Minimalist Apartment',
    location: 'New York, NY',
    price: 1800.00,
    imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=1000&auto=format&fit=crop',
    virtualTourUrl: 'https://pannellum.org/images/jfk.jpg',
    isSaved: false,
  ),
];