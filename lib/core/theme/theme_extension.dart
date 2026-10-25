import 'package:flutter/material.dart';
import 'app_theme.dart';

extension AppThemeExtension on BuildContext {
  Color get primaryColor => AppTheme.primaryColor(this);
  Color get accentColor => AppTheme.accentColor(this);
  Color get backgroundColor => AppTheme.backgroundColor(this);
  Color get surfaceColor => AppTheme.surfaceColor(this);
  Color get cardColor => AppTheme.cardColor(this);
  Color get softBgColor => AppTheme.softBgColor(this);
  Color get textColor => AppTheme.textColor(this);
  Color get subTextColor => AppTheme.subTextColor(this);
  Color get textSecondaryColor => AppTheme.textSecondaryColor(this);
  Color get borderColor => AppTheme.borderColor(this);
  Color get errorRed => AppTheme.errorRed;
  Color get successGreen => AppTheme.successGreen;
  bool get isDark => AppTheme.isDark(this);
  LinearGradient get primaryGradient => AppTheme.primaryGradient(this);
  LinearGradient get accentGradient => AppTheme.accentGradient(this);
}
