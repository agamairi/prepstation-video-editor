import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimelineTool { select, blade, tracker }

final timelineToolProvider = StateProvider<TimelineTool>(
  (ref) => TimelineTool.select,
);
