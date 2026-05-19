import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:prepstation/core/effects/effect_type.dart';

@immutable
class EffectInstance {
  const EffectInstance({
    required this.id,
    required this.clipId,
    required this.type,
    required this.stackIndex,
    this.isEnabled = true,
    this.parameters = const {},
  });

  final String id;
  final String clipId;
  final EffectType type;
  final int stackIndex;
  final bool isEnabled;
  final Map<String, double> parameters;

  String get displayName => type.displayName;

  EffectInstance copyWith({
    String? id,
    String? clipId,
    EffectType? type,
    int? stackIndex,
    bool? isEnabled,
    Map<String, double>? parameters,
  }) {
    return EffectInstance(
      id: id ?? this.id,
      clipId: clipId ?? this.clipId,
      type: type ?? this.type,
      stackIndex: stackIndex ?? this.stackIndex,
      isEnabled: isEnabled ?? this.isEnabled,
      parameters: parameters ?? this.parameters,
    );
  }

  String parametersToJson() =>
      jsonEncode(parameters.map((k, v) => MapEntry(k, v)));

  static Map<String, double> parametersFromJson(String json) {
    if (json.isEmpty || json == '{}') return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EffectInstance &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EffectInstance(id: $id, type: $type, clipId: $clipId)';
}
