import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/core/database/database.dart';

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Override in ProviderScope'),
);
