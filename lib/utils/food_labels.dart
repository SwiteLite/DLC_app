import 'package:intl/intl.dart';

import '../food.dart';

String expirationLabel(Food food) {
  final locationPrefix = food.location == FoodLocation.unspecified
      ? ''
      : '${food.location.label} · ';

  if (food.status != FoodStatus.active) {
    return '$locationPrefix${food.status.label} — DLC ${DateFormat('dd/MM/yyyy').format(food.expirationDate)}';
  }

  final days = food.daysUntilExpiration();
  final dateText = DateFormat('dd/MM/yyyy').format(food.expirationDate);

  if (days < 0) {
    return '$locationPrefix'
        'Expiré depuis ${-days} jour${-days > 1 ? 's' : ''}, le : $dateText';
  }
  if (days == 0) return '$locationPrefix' 'Expire aujourd\'hui ($dateText)';
  if (days == 1) return '$locationPrefix' 'Expire demain ($dateText)';
  return '$locationPrefix' 'Expire dans $days jours, le : $dateText';
}
