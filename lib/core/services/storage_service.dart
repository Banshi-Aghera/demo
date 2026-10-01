import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads user photos (returns, reviews). Uses bytes so it also works on web.
class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;
  final _picker = ImagePicker();

  /// Returns null if the user cancelled the picker.
  Future<XFile?> pickImage({bool camera = false}) => _picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 75,
      );

  /// Uploads under [folder]/{timestamp}.jpg and returns the download URL.
  Future<String> upload(String folder, XFile file) async {
    final bytes = await file.readAsBytes();
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('$folder/$name');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
