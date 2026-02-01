import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barber/core/state/base_notifier.dart';

class ImagePickerNotifier extends BaseNotifier<String, String> {
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    await execute(() async {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      return image != null ? right(image.path) : left('No image selected');
    }, (failure) => failure);
  }

  void removeImage() {
    setData('');
  }
}
