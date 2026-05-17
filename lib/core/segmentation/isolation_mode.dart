enum IsolationMode {
  transparent,
  blur,
  solidColor;

  String get displayName => switch (this) {
        IsolationMode.transparent => 'Transparent',
        IsolationMode.blur => 'Blur Background',
        IsolationMode.solidColor => 'Solid Color',
      };

  static IsolationMode fromName(String name) => IsolationMode.values
      .firstWhere((e) => e.name == name, orElse: () => IsolationMode.transparent);
}
