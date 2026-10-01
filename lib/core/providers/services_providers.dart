import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/storage_service.dart';
import 'firebase_providers.dart';

part 'services_providers.g.dart';

@Riverpod(keepAlive: true)
StorageService storageService(Ref ref) =>
    StorageService(ref.watch(firebaseStorageProvider));
