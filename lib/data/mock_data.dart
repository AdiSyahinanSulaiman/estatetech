import '../models/property.dart';

List<Property> globalProperties = [
  Property(
    id: '1',
    title: 'Modern Luxury Villa',
    location: 'Beverly Hills, CA',
    price: 2500.00,
    imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000&auto=format&fit=crop',
    // STABLE MODERN INTERIOR
    virtualTourUrl: 'https://www.istockphoto.com/photo/3d-render-360-degrees-modern-living-room-gm1208789228-349527240',
    isSaved: false,
  ),
  Property(
    id: '2',
    title: 'Minimalist Apartment',
    location: 'New York, NY',
    price: 1800.00,
    imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=1000&auto=format&fit=crop',
    virtualTourUrl: 'https://images.pexels.com/photos/35493917/pexels-photo-35493917.jpeg',
    isSaved: false,
  ),
];