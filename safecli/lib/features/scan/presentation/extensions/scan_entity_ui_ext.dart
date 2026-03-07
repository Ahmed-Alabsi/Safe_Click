// lib/features/scan/presentation/extensions/scan_entity_ui_ext.dart
//
// Moves safetyColor from the domain entity to the presentation layer.
// The original ScanResult.safetyColor property retrieved a plain Color;
// here it receives a BuildContext so it can use the active theme.
// NOTE: existing views do NOT call .safetyColor — they compute colors
// inline — so no view file is changed. This file is provided for Clean
// Architecture completeness and future use.

import 'package:flutter/material.dart';
import '../../domain/entities/scan_entity.dart';

extension ScanEntityUiExtension on ScanEntity {
  /// Returns the theme-appropriate safety color for this entity.
  Color safetyColor(BuildContext context) {
    if (safe == true) return Theme.of(context).colorScheme.tertiary;
    if (safe == false) return Theme.of(context).colorScheme.error;
    return Colors.orange;
  }
}
