import '../models/property.dart';

class AIEngine {
  static const double W_PRICE = -0.52;
  static const double W_ROOMS = 0.35;
  static const double W_SQFT = 0.13;

  double _norm(double val, double min, double max) {
    if (max <= min) return 0.5; // Prevent division by zero
    return ((val - min) / (max - min)).clamp(0.0, 1.0);
  }

  double calculateMatchScore(Property p, Map<String, dynamic>? pref) {
    if (pref == null || pref.isEmpty) return 0.0;

    // Use safe defaults if the user is new
    double targetP = (pref['avgPrice'] ?? 2000.0).toDouble();
    double targetR = (pref['avgRooms'] ?? 3.0).toDouble();
    double targetS = (pref['avgSqft'] ?? 1200.0).toDouble();

    double pDiff = _norm((p.monthlyPrice - targetP).abs(), 0, 5000);
    double rDiff = _norm((p.rooms - targetR).abs(), 0, 10);
    double sDiff = _norm((p.sqft - targetS).abs(), 0, 5000);

    return ((1.0 - pDiff) * W_PRICE.abs()) + ((1.0 - rDiff) * W_ROOMS) + ((1.0 - sDiff) * W_SQFT);
  }

  List<Property> rankFeed(List<Property> allProps, Map<String, dynamic>? userVector) {
    List<Property> sortedList = List.from(allProps);
    DateTime now = DateTime.now();

    try {
      sortedList.sort((a, b) {
        // 1. Freshness Boost (New posts in last 10 mins always on top)
        bool aIsNew = now.difference(a.createdAt).inMinutes < 10;
        bool bIsNew = now.difference(b.createdAt).inMinutes < 10;
        if (aIsNew && !bIsNew) return -1;
        if (!aIsNew && bIsNew) return 1;

        // 2. If no vector exists, sort by date
        if (userVector == null || userVector.isEmpty) {
          return b.createdAt.compareTo(a.createdAt);
        }

        // 3. AI Match Score
        double scoreA = calculateMatchScore(a, userVector);
        double scoreB = calculateMatchScore(b, userVector);
        return scoreB.compareTo(scoreA);
      });
    } catch (e) {
      print("AI Sort Error: $e"); // Log error but don't crash
    }
    return sortedList;
  }
}