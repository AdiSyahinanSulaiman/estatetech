import '../models/property.dart';

class AIEngine {
  // --- KAGGLE TRAINED WEIGHTS ---
  static const double KAGGLE_ROOM_WEIGHT = -12773.27;
  static const double KAGGLE_SQFT_WEIGHT = 66819.82;

  double _norm(double val, double min, double max) {
    if (max <= min) return 0.5;
    return ((val - min) / (max - min)).clamp(0.0, 1.0);
  }

  double calculateMatchScore(Property p, Map<String, dynamic>? pref) {
    if (pref == null || pref.isEmpty) return 0.0;

    // 1. Determine Target Price
    // Logic: If 'Budget Mode' is enabled from calculator, use that. Otherwise use browsing average.
    bool budgetModeActive = pref['budgetModeActive'] ?? false;
    double targetP = budgetModeActive
        ? (pref['calculatedBudget'] ?? 2000.0).toDouble()
        : (pref['avgPrice'] ?? 2000.0).toDouble();

    double targetR = (pref['avgRooms'] ?? 3.0).toDouble();
    double targetS = (pref['avgSqft'] ?? 1200.0).toDouble();

    // 2. Calculate differences
    double pDiff = _norm((p.monthlyPrice - targetP).abs(), 0, 5000);
    double rDiff = _norm((p.rooms - targetR).abs(), 0, 10);
    double sDiff = _norm((p.sqft - targetS).abs(), 0, 5000);

    // 3. Apply Weighted Logic
    // If Budget Mode is active, we make Price 80% of the decision.
    double priceWeight = budgetModeActive ? 0.80 : 0.50;
    double featureWeight = 1.0 - priceWeight;

    double roomInfluence = (1.0 - rDiff) * (KAGGLE_ROOM_WEIGHT.abs() / 100000) * featureWeight;
    double sqftInfluence = (1.0 - sDiff) * (KAGGLE_SQFT_WEIGHT / 100000) * featureWeight;
    double priceInfluence = (1.0 - pDiff) * priceWeight;

    return priceInfluence + roomInfluence + sqftInfluence;
  }

  List<Property> rankFeed(List<Property> allProps, Map<String, dynamic>? userVector) {
    List<Property> sortedList = List.from(allProps);
    DateTime now = DateTime.now();

    sortedList.sort((a, b) {
      // Demo boost for brand new posts
      bool aIsNew = now.difference(a.createdAt).inMinutes < 10;
      bool bIsNew = now.difference(b.createdAt).inMinutes < 10;
      if (aIsNew && !bIsNew) return -1;
      if (!aIsNew && bIsNew) return 1;

      double scoreA = calculateMatchScore(a, userVector);
      double scoreB = calculateMatchScore(b, userVector);
      return scoreB.compareTo(scoreA);
    });
    return sortedList;
  }
}