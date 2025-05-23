import 'dart:async';
import 'package:akashic_records/models/model.dart';

Future<Novel?> loadNovelWithTimeout(
  Future<Novel?> Function() loadFunction, {
  Duration timeoutDuration = const Duration(seconds: 50),
}) async {
  try {
    return await loadFunction().timeout(timeoutDuration);
  } on TimeoutException catch (_) {
    print('Timeout ao carregar novel.');
    return null;
  } catch (e) {
    print('Erro ao carregar a novel: $e');
    return null;
  }
}
