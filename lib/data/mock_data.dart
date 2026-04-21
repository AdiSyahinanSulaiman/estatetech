import '../models/property.dart';

List<Property> globalProperties = [
  Property(
    id: '1',
    title: 'Modern Luxury Villa',
    location: 'Beverly Hills, CA',
    price: 2500.00,
    imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000',
    virtualTourUrl: 'https://images.pexels.com/photos/12148587/pexels-photo-12148587.jpeg',
    sellerId: 'admin_1', // Added this to fix red line
    isSaved: false,
  ),
  Property(
    id: '2',
    title: 'Minimalist Apartment',
    location: 'New York, NY',
    price: 1800.00,
    imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=1000',
    virtualTourUrl: 'https://images.pexels.com/photos/3457273/pexels-photo-3457273.jpeg',
    sellerId: 'admin_2', // Added this to fix red line
    isSaved: false,
  ),
];