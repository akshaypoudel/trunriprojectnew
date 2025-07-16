import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';

class BadgeHelper {
  static int _badgeCount = 0;

  static void incrementBadge() {
    _badgeCount++;
    FlutterAppBadgeControl.updateBadgeCount(_badgeCount);
  }

  static void clearBadge() {
    _badgeCount = 0;
    FlutterAppBadgeControl.removeBadge();
  }
}
