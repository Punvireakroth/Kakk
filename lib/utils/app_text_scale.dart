import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Global text size multiplier for the whole app (theme styles + hardcoded [TextStyle.fontSize]).

/// Adjust this single value to make UI text larger or smaller. Combines with the platform
/// accessibility text scale (Settings → Display size / Text size).
const double kAppTextScaleFactor = 1.08;

/// Wraps the platform [TextScaler]
@immutable
final class AppCompoundedTextScaler extends TextScaler {
  const AppCompoundedTextScaler(this._platform, this._appFactor)
    : assert(_appFactor > 0);

  final TextScaler _platform;
  final double _appFactor;

  @override
  double scale(double fontSize) => _platform.scale(fontSize * _appFactor);

  @override
  @Deprecated(
    'Use scale() instead. Included for TextScaler subclasses.',
  )
  double get textScaleFactor => _platform.textScaleFactor * _appFactor;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppCompoundedTextScaler &&
            other._appFactor == _appFactor &&
            other._platform == _platform;
  }

  @override
  int get hashCode => Object.hash(_platform, _appFactor);
}
