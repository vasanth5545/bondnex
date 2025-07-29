// // File: lib/settings/crop_photo_screen.dart
// // Ithu gallery-la irundhu select panna image-ah crop seivatharkana puthiya screen.

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_cropper/image_cropper.dart';
// import '../providers/app_colors.dart'; // Unga project-oda color file

// class CropPhotoScreen extends StatefulWidget {
//   final File imageFile;

//   const CropPhotoScreen({
//     super.key,
//     required this.imageFile,
//   });

//   @override
//   State<CropPhotoScreen> createState() => _CropPhotoScreenState();
// }

// class _CropPhotoScreenState extends State<CropPhotoScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Screen open aana odane crop UI-ah kaatum
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _cropImage();
//     });
//   }

//   Future<void> _cropImage() async {
//     final croppedFile = await ImageCropper().cropImage(
//       sourcePath: widget.imageFile.path,
//       compressQuality: 80, // Nalla quality kaga
//       aspectRatioPresets: [
//         CropAspectRatioPreset.square,
//         CropAspectRatioPreset.ratio3x2,
//         CropAspectRatioPreset.original,
//         CropAspectRatioPreset.ratio4x3,
//         CropAspectRatioPreset.ratio16x9
//       ],
//       uiSettings: [
//         AndroidUiSettings(
//             toolbarTitle: 'Crop Photo',
//             toolbarColor: AppColors.primaryBlack,
//             toolbarWidgetColor: Colors.white,
//             initAspectRatio: CropAspectRatioPreset.square,
//             lockAspectRatio: false),
//         IOSUiSettings(
//           title: 'Crop Photo',
//           aspectRatioPickerButtonHidden: false,
//           resetButtonHidden: false,
//           rotateButtonsHidden: false,
//         ),
//       ],
//     );

//     // User crop pannirundha, antha puthu file-oda munthaya screen-ku pogum.
//     // Illana (cancel pannitaanga na), null value-oda pogum.
//     if (mounted) {
//       Navigator.pop(context, croppedFile != null ? File(croppedFile.path) : null);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Crop UI varaikkum user-ku oru loading indicator kaatuvom.
//     return const Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }
