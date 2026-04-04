// import 'package:dio/dio.dart';
// import '../../../core/config/endpoints.dart';
// import "dart:io";

// class MediaApi {
//   final Dio dio;
//   MediaApi(this.dio);

//   Future<Map<String, dynamic>> uploadFile(
//     String filePath, {
//     required String fieldName,
//   }) async {
//     final form = FormData.fromMap({
//       'file': await MultipartFile.fromFile(
//         filePath,
//         filename: filePath.split('/').last,
//       ),
//     });

//     final res = await dio.post(Endpoints.mediaUpload, data: form);
//     return (res.data['media'] as Map).cast<String, dynamic>();
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:image_picker/image_picker.dart';

class MediaApi {
  final Dio dio;
  MediaApi(this.dio);

  /// Works on Web + Mobile.
  /// Pass an XFile from image_picker.
  Future<Map<String, dynamic>> uploadXFile(XFile file) async {
    final fileName = file.name.isNotEmpty ? file.name : 'upload.bin';

    final multipart = kIsWeb
        ? MultipartFile.fromBytes(await file.readAsBytes(), filename: fileName)
        : await MultipartFile.fromFile(file.path, filename: fileName);

    final form = FormData.fromMap({'file': multipart});
    final res = await dio.post('/media/upload', data: form);

    return (res.data['media'] as Map).cast<String, dynamic>();
  }
}
