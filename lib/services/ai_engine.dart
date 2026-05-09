import '../models/property.dart';

class AIEngine {
  // ---------------------------------------------------------
  // REAL TRAINED DATA: From your Google Colab session
  // ---------------------------------------------------------
  static const double KAGGLE_ROOM_WEIGHT = -12773.27;
  static const double KAGGLE_SQFT_WEIGHT = 66819.82;

  // Normalizes values for the similarity math (0.0 to 1.0)
  double _norm(double val, double min, double max) {
    if (max <= min) return 0.5;
    return ((val - min) / (max - min)).clamp(0.0, 1.0);
  }

  // THE ML ALGORITHM: Calculates similarity to user preferences
  double calculateMatchScore(Property p, Map<String, dynamic>? pref) {
    if (pref == null || pref.isEmpty) return 0.0;

    // Get user's learned "Dream House" averages from Firestore
    double targetP = (pref['avgPrice'] ?? 2000.0).toDouble();
    double targetR = (pref['avgRooms'] ?? 3.0).toDouble();
    double targetS = (pref['avgSqft'] ?? 1200.0).toDouble();

    // 1. Calculate how different this house is from the user's dream house
    double pDiff = _norm((p.monthlyPrice - targetP).abs(), 0, 5000);
    double rDiff = _norm((p.rooms - targetR).abs(), 0, 10);
    double sDiff = _norm((p.sqft - targetS).abs(), 0, 5000);

    // 2. Apply your TRAINED weights
    // We take the Absolute value of the weights and divide by 100,000 to keep math clean
    double roomInfluence = (1.0 - rDiff) * (KAGGLE_ROOM_WEIGHT.abs() / 100000);
    double sqftInfluence = (1.0 - sDiff) * (KAGGLE_SQFT_WEIGHT / 100000);
    double priceInfluence = (1.0 - pDiff) * 0.50; // Price is 50% priority

    return priceInfluence + roomInfluence + sqftInfluence;
  }

  // RANK FEED: The Personalized Suggestion Engine
  List<Property> rankFeed(List<Property> allProps, Map<String, dynamic>? userVector) {
    List<Property> sortedList = List.from(allProps);
    DateTime now = DateTime.now();

    sortedList.sort((a, b) {
      // Logic: Boost brand new posts (last 10 mins) to the top for the demo
      bool aIsNew = now.difference(a.createdAt).inMinutes < 10;
      bool bIsNew = now.difference(b.createdAt).inMinutes < 10;
      if (aIsNew && !bIsNew) return -1;
      if (!aIsNew && bIsNew) return 1;

      // Otherwise, use the AI Match Score based on your Kaggle results
      double scoreA = calculateMatchScore(a, userVector);
      double scoreB = calculateMatchScore(b, userVector);
      return scoreB.compareTo(scoreA);
    });
    return sortedList;
  }
}