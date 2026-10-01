import 'package:cloud_functions/cloud_functions.dart';

/// Calls a Cloud Function and returns its result as a plain map.
Future<Map<String, dynamic>> callFunction(
  FirebaseFunctions functions,
  String name,
  Map<String, dynamic> data,
) async {
  final result = await functions
      .httpsCallable(
        name,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      )
      .call<Object?>(data);
  final out = result.data;
  return out is Map ? Map<String, dynamic>.from(out) : <String, dynamic>{};
}
