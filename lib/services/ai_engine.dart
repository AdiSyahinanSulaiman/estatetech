import '../models/property.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIEngine {
  // Weights derived from your Google Colab Kaggle session
  static const double KAGGLE_ROOM_WEIGHT = -12773.27;
  static const double KAGGLE_SQFT_WEIGHT = 66819.82;

  double _norm(double val, double min, double max) {
    if (max <= min) return 0.5;
    return ((val - min) / (max - min)).clamp(0.0, 1.0);
  }

  double calculateMatchScore(Property p, Map<String, dynamic>? pref) {
    if (pref == null || pref.isEmpty) return 0.0;

    bool budgetModeActive = pref['budgetModeActive'] ?? false;

    // Logic: Use the budget from calculator if active, else use historical average
    double targetP = budgetModeActive
        ? (pref['calculatedBudget'] ?? 2000.0).toDouble()
        : (pref['avgPrice'] ?? 2000.0).toDouble();

    double targetR = (pref['avgRooms'] ?? 3.0).toDouble();
    double targetS = (pref['avgSqft'] ?? 1200.0).toDouble();

    double pDiff = _norm((p.monthlyPrice - targetP).abs(), 0, 10000);
    double rDiff = _norm((p.rooms - targetR).abs(), 0, 10);
    double sDiff = _norm((p.sqft - targetS).abs(), 0, 5000);

    // If Budget Mode is ON, price is 90% of the score.
    double priceWeight = budgetModeActive ? 0.90 : 0.50;
    double featureWeight = 1.0 - priceWeight;

    double roomInfluence = (1.0 - rDiff) * (KAGGLE_ROOM_WEIGHT.abs() / 100000) * featureWeight;
    double sqftInfluence = (1.0 - sDiff) * (KAGGLE_SQFT_WEIGHT / 100000) * featureWeight;
    double priceInfluence = (1.0 - pDiff) * priceWeight;

    return priceInfluence + roomInfluence + sqftInfluence;
  }

  List<Property> rankFeed(List<Property> allProps, Map<String, dynamic>? userVector, DateTime lastRefreshTime) {
    if (allProps.isEmpty) return [];
    List<Property> sortedList = List.from(allProps);

    sortedList.sort((a, b) {
      // FRESHNESS OVERRIDE: Newest posts stay at the top until a manual refresh
      bool aIsNew = a.createdAt.isAfter(lastRefreshTime);
      bool bIsNew = b.createdAt.isAfter(lastRefreshTime);

      if (aIsNew && !bIsNew) return -1;
      if (!aIsNew && bIsNew) return 1;

      double scoreA = calculateMatchScore(a, userVector);
      double scoreB = calculateMatchScore(b, userVector);

      if ((scoreA - scoreB).abs() < 0.0001) {
        return b.createdAt.compareTo(a.createdAt);
      }
      return scoreB.compareTo(scoreA);
    });
    return sortedList;
  }
}