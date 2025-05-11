// lib/public_salon_details/widgets/gallery_modal.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../models/public_salon_details.dart';
import '../api/gallery_api.dart';

class GalleryModal extends StatefulWidget {
  final int salonId;
  final int currentImagesCount;
  final Function(List<SalonImage>) onImagesAdded;

  const GalleryModal({
    super.key,
    required this.salonId,
    required this.currentImagesCount,
    required this.onImagesAdded,
  });

  @override
  State<GalleryModal> createState() => _GalleryModalState();
}

class _GalleryModalState extends State<GalleryModal> {
  final List<File> _selectedFiles = [];
  final List<PlatformFile> _selectedFileData = []; // Pour le web
  bool _isUploading = false;
  String? _errorMessage;
  final int _maxImageSize = 6 * 1024 * 1024; // 6MB en octets selon l'API
  final int _minImagesRequired = 3; // Minimum requis par l'API
  final int _maxImagesAllowed = 12; // Maximum permis par l'API

  int get _selectedImagesCount => _selectedFiles.length + _selectedFileData.length;
  bool get _minimumImagesReached => _selectedImagesCount >= _minImagesRequired;
  bool get _maximumImagesExceeded => _selectedImagesCount > _maxImagesAllowed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_errorMessage != null) _buildErrorMessage(),
          Expanded(
            child: _buildImagePreview(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajouter des images',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Sélectionnez entre 3 et 12 images',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Taille maximale: 6MB par image',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: Colors.red[700]),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red[700], size: 18),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    // Compter le nombre total d'images sélectionnées (web + mobile)
    final totalSelectedImages = _selectedImagesCount;

    if (totalSelectedImages == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune image sélectionnée',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez entre 3 et 12 images',
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Row(
            children: [
              Text(
                'Images sélectionnées ($totalSelectedImages)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_maximumImagesExceeded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Maximum 12 images',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: totalSelectedImages,
            itemBuilder: (context, index) {
              // Afficher les images en fonction de la plateforme
              if (kIsWeb && index < _selectedFileData.length) {
                // Affichage pour le web
                final fileData = _selectedFileData[index];
                return _buildImagePreviewItem(
                  bytes: fileData.bytes,
                  onRemove: () {
                    setState(() {
                      _selectedFileData.removeAt(index);
                    });
                  },
                );
              } else if (!kIsWeb && index < _selectedFiles.length) {
                // Affichage pour mobile
                final file = _selectedFiles[index];
                return _buildImagePreviewItem(
                  file: file,
                  onRemove: () {
                    setState(() {
                      _selectedFiles.removeAt(index);
                    });
                  },
                );
              } else {
                // Dans le cas où on a des images web et des images mobiles
                if (kIsWeb) {
                  final fileIndex = index - _selectedFileData.length;
                  if (fileIndex >= 0 && fileIndex < _selectedFiles.length) {
                    final file = _selectedFiles[fileIndex];
                    return _buildImagePreviewItem(
                      file: file,
                      onRemove: () {
                        setState(() {
                          _selectedFiles.removeAt(fileIndex);
                        });
                      },
                    );
                  }
                } else {
                  final dataIndex = index - _selectedFiles.length;
                  if (dataIndex >= 0 && dataIndex < _selectedFileData.length) {
                    final fileData = _selectedFileData[dataIndex];
                    return _buildImagePreviewItem(
                      bytes: fileData.bytes,
                      onRemove: () {
                        setState(() {
                          _selectedFileData.removeAt(dataIndex);
                        });
                      },
                    );
                  }
                }
                return const SizedBox(); // Fallback si nécessaire
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewItem({File? file, Uint8List? bytes, required Function onRemove}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: bytes != null
              ? Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
              : file != null
              ? Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
              : Container(color: Colors.grey[200]),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: () => onRemove(),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final canAddMore = _selectedImagesCount < _maxImagesAllowed && !_isUploading;
    final canUpload = _minimumImagesReached && !_maximumImagesExceeded && !_isUploading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: canAddMore ? _pickImages : null,
            icon: const Icon(Icons.photo_library),
            label: Text('Sélectionner des images', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: canUpload ? _uploadImages : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isUploading
                  ? Colors.grey
                  : canUpload
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isUploading
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Téléchargement en cours...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            )
                : Text(
              'Ajouter à la galerie',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          if (!_minimumImagesReached && _selectedImagesCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Sélectionnez au moins 3 images',
                style: GoogleFonts.poppins(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // Important: récupérer les données en bytes pour la compatibilité web
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> validFiles = [];
        List<PlatformFile> validFileData = [];
        List<String> errorMessages = [];

        for (var file in result.files) {
          // Vérifier la taille
          if (file.size > _maxImageSize) {
            errorMessages.add('${file.name} dépasse la taille limite de 6MB');
            continue;
          }

          if (kIsWeb) {
            // Sur le web, stocker les informations de PlatformFile
            validFileData.add(file);
          } else {
            // Sur mobile, utiliser le path
            if (file.path == null) continue;
            final fileObj = File(file.path!);
            validFiles.add(fileObj);
          }

          // Vérifier si nous avons atteint le nombre maximal d'images
          if (_selectedFiles.length + validFiles.length + _selectedFileData.length + validFileData.length > _maxImagesAllowed) {
            errorMessages.add('Vous ne pouvez pas sélectionner plus de $_maxImagesAllowed images');
            break;
          }
        }

        setState(() {
          _selectedFiles.addAll(validFiles);
          _selectedFileData.addAll(validFileData);
          if (errorMessages.isNotEmpty) {
            _errorMessage = errorMessages.join('. ');
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sélection des images: $e';
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedFiles.isEmpty && _selectedFileData.isEmpty) return;

    // Vérifier les conditions de l'API
    if (_selectedImagesCount < _minImagesRequired) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner au moins $_minImagesRequired images.';
      });
      return;
    }

    if (_selectedImagesCount > _maxImagesAllowed) {
      setState(() {
        _errorMessage = 'Vous ne pouvez pas télécharger plus de $_maxImagesAllowed images.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      List<SalonImage> newImages = [];

      if (kIsWeb && _selectedFileData.isNotEmpty) {
        // Pour le web, convertir les PlatformFile en MultipartFile
        final List<http.MultipartFile> webFiles = [];

        for (var fileData in _selectedFileData) {
          if (fileData.bytes != null) {
            webFiles.add(
                http.MultipartFile.fromBytes(
                  'image',
                  fileData.bytes!,
                  filename: fileData.name,
                )
            );
          }
        }

        // Appel API pour le web
        if (webFiles.isNotEmpty) {
          final webImages = await GalleryApi.uploadImagesForWeb(
            widget.salonId,
            webFiles,
          );
          newImages.addAll(webImages);
        }
      }

      // Pour les plateformes natives
      if (_selectedFiles.isNotEmpty) {
        final nativeImages = await GalleryApi.uploadImages(
          widget.salonId,
          _selectedFiles,
        );
        newImages.addAll(nativeImages);
      }

      widget.onImagesAdded(newImages);
      Navigator.pop(context);

    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}






// // lib/public_salon_details/widgets/gallery_modal.dart
//
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
// import 'package:google_fonts/google_fonts.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import '../../../models/public_salon_details.dart';
// import '../api/gallery_api.dart';
//
// class GalleryModal extends StatefulWidget {
//   final int salonId;
//   final int currentImagesCount;
//   final Function(List<SalonImage>) onImagesAdded;
//
//   const GalleryModal({
//     super.key,
//     required this.salonId,
//     required this.currentImagesCount,
//     required this.onImagesAdded,
//   });
//
//   @override
//   State<GalleryModal> createState() => _GalleryModalState();
// }
//
// class _GalleryModalState extends State<GalleryModal> {
//   final List<File> _selectedFiles = [];
//   final List<PlatformFile> _selectedFileData = []; // Pour le web
//   bool _isUploading = false;
//   String? _errorMessage;
//   final int _maxImageSize = 8 * 1024 * 1024; // 8MB en octets
//   final int _maxTotalImages = 25;
//
//   int get _remainingSlots => _maxTotalImages - widget.currentImagesCount;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.8,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         children: [
//           _buildHeader(),
//           if (_errorMessage != null) _buildErrorMessage(),
//           Expanded(
//             child: _buildImagePreview(),
//           ),
//           _buildFooter(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 1,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Ajouter des images',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 'Vous pouvez ajouter jusqu\'à $_remainingSlots image(s)',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               Text(
//                 'Taille maximale: 8MB par image',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorMessage() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.red.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.red.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.error_outline, color: Colors.red[700]),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               _errorMessage!,
//               style: GoogleFonts.poppins(color: Colors.red[700]),
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.close, color: Colors.red[700], size: 18),
//             onPressed: () {
//               setState(() {
//                 _errorMessage = null;
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildImagePreview() {
//     // Compter le nombre total d'images sélectionnées (web + mobile)
//     final totalSelectedImages = _selectedFiles.length + _selectedFileData.length;
//
//     if (totalSelectedImages == 0) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'Aucune image sélectionnée',
//               style: GoogleFonts.poppins(color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Sélectionnez jusqu\'à $_remainingSlots images',
//               style: GoogleFonts.poppins(color: Colors.grey[500]),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
//           child: Text(
//             'Images sélectionnées ($totalSelectedImages)',
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               fontSize: 16,
//             ),
//           ),
//         ),
//         Expanded(
//           child: GridView.builder(
//             padding: const EdgeInsets.all(16),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               childAspectRatio: 1,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: totalSelectedImages,
//             itemBuilder: (context, index) {
//               // Afficher les images en fonction de la plateforme
//               if (kIsWeb && index < _selectedFileData.length) {
//                 // Affichage pour le web
//                 final fileData = _selectedFileData[index];
//                 return _buildImagePreviewItem(
//                   bytes: fileData.bytes,
//                   onRemove: () {
//                     setState(() {
//                       _selectedFileData.removeAt(index);
//                     });
//                   },
//                 );
//               } else if (!kIsWeb && index < _selectedFiles.length) {
//                 // Affichage pour mobile
//                 final file = _selectedFiles[index];
//                 return _buildImagePreviewItem(
//                   file: file,
//                   onRemove: () {
//                     setState(() {
//                       _selectedFiles.removeAt(index);
//                     });
//                   },
//                 );
//               } else {
//                 // Dans le cas où on a des images web et des images mobiles
//                 if (kIsWeb) {
//                   final fileIndex = index - _selectedFileData.length;
//                   if (fileIndex >= 0 && fileIndex < _selectedFiles.length) {
//                     final file = _selectedFiles[fileIndex];
//                     return _buildImagePreviewItem(
//                       file: file,
//                       onRemove: () {
//                         setState(() {
//                           _selectedFiles.removeAt(fileIndex);
//                         });
//                       },
//                     );
//                   }
//                 } else {
//                   final dataIndex = index - _selectedFiles.length;
//                   if (dataIndex >= 0 && dataIndex < _selectedFileData.length) {
//                     final fileData = _selectedFileData[dataIndex];
//                     return _buildImagePreviewItem(
//                       bytes: fileData.bytes,
//                       onRemove: () {
//                         setState(() {
//                           _selectedFileData.removeAt(dataIndex);
//                         });
//                       },
//                     );
//                   }
//                 }
//                 return const SizedBox(); // Fallback si nécessaire
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildImagePreviewItem({File? file, Uint8List? bytes, required Function onRemove}) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: bytes != null
//               ? Image.memory(
//             bytes,
//             fit: BoxFit.cover,
//             width: double.infinity,
//             height: double.infinity,
//           )
//               : file != null
//               ? Image.file(
//             file,
//             fit: BoxFit.cover,
//             width: double.infinity,
//             height: double.infinity,
//           )
//               : Container(color: Colors.grey[200]),
//         ),
//         Positioned(
//           top: -8,
//           right: -8,
//           child: GestureDetector(
//             onTap: () => onRemove(),
//             child: Container(
//               padding: const EdgeInsets.all(2),
//               decoration: const BoxDecoration(
//                 color: Colors.red,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.close,
//                 color: Colors.white,
//                 size: 16,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildFooter() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 1,
//             offset: const Offset(0, -1),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           ElevatedButton.icon(
//             onPressed: _remainingSlots > 0 && !_isUploading ? _pickImages : null,
//             icon: const Icon(Icons.photo_library),
//             label: Text('Sélectionner des images', style: GoogleFonts.poppins()),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//               minimumSize: const Size(double.infinity, 48),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: (_selectedFiles.isNotEmpty || _selectedFileData.isNotEmpty) && !_isUploading
//                 ? _uploadImages
//                 : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _isUploading
//                   ? Colors.grey
//                   : Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//               minimumSize: const Size(double.infinity, 48),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: _isUploading
//                 ? Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   'Téléchargement en cours...',
//                   style: GoogleFonts.poppins(),
//                 ),
//               ],
//             )
//                 : Text(
//               'Ajouter à la galerie',
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _pickImages() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//         allowMultiple: true,
//         withData: true, // Important: récupérer les données en bytes pour la compatibilité web
//       );
//
//       if (result != null && result.files.isNotEmpty) {
//         List<File> validFiles = [];
//         List<PlatformFile> validFileData = [];
//         List<String> errorMessages = [];
//
//         for (var file in result.files) {
//           // Vérifier la taille
//           if (file.size > _maxImageSize) {
//             errorMessages.add('${file.name} dépasse la taille limite de 8MB');
//             continue;
//           }
//
//           if (kIsWeb) {
//             // Sur le web, stocker les informations de PlatformFile
//             validFileData.add(file);
//           } else {
//             // Sur mobile, utiliser le path
//             if (file.path == null) continue;
//             final fileObj = File(file.path!);
//             validFiles.add(fileObj);
//           }
//
//           // Vérifier si nous avons atteint le nombre maximal d'images
//           if (_selectedFiles.length + validFiles.length + _selectedFileData.length + validFileData.length >= _remainingSlots) {
//             errorMessages.add('Nombre maximal d\'images atteint (25 au total)');
//             break;
//           }
//         }
//
//         setState(() {
//           _selectedFiles.addAll(validFiles);
//           _selectedFileData.addAll(validFileData);
//           if (errorMessages.isNotEmpty) {
//             _errorMessage = errorMessages.join('. ');
//           }
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Erreur lors de la sélection des images: $e';
//       });
//     }
//   }
//
//   Future<void> _uploadImages() async {
//     if (_selectedFiles.isEmpty && _selectedFileData.isEmpty) return;
//
//     setState(() {
//       _isUploading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       List<SalonImage> newImages = [];
//
//       if (kIsWeb && _selectedFileData.isNotEmpty) {
//         // Pour le web, convertir les PlatformFile en MultipartFile
//         final List<http.MultipartFile> webFiles = [];
//
//         for (var fileData in _selectedFileData) {
//           if (fileData.bytes != null) {
//             webFiles.add(
//                 http.MultipartFile.fromBytes(
//                   'image',
//                   fileData.bytes!,
//                   filename: fileData.name,
//                 )
//             );
//           }
//         }
//
//         // Appel API pour le web
//         if (webFiles.isNotEmpty) {
//           final webImages = await GalleryApi.uploadImagesForWeb(
//             widget.salonId,
//             webFiles,
//           );
//           newImages.addAll(webImages);
//         }
//       }
//
//       // Pour les plateformes natives
//       if (_selectedFiles.isNotEmpty) {
//         final nativeImages = await GalleryApi.uploadImages(
//           widget.salonId,
//           _selectedFiles,
//         );
//         newImages.addAll(nativeImages);
//       }
//
//       widget.onImagesAdded(newImages);
//       Navigator.pop(context);
//
//     } catch (e) {
//       setState(() {
//         _isUploading = false;
//         _errorMessage = 'Erreur lors du téléchargement des images: $e';
//       });
//     }
//   }
// }




// // lib/public_salon_details/widgets/gallery_modal.dart
//
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:google_fonts/google_fonts.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import '../../../models/public_salon_details.dart';
// import '../api/gallery_api.dart';
//
// class GalleryModal extends StatefulWidget {
//   final int salonId;
//   final int currentImagesCount;
//   final Function(List<SalonImage>) onImagesAdded;
//
//   const GalleryModal({
//     super.key,
//     required this.salonId,
//     required this.currentImagesCount,
//     required this.onImagesAdded,
//   });
//
//   @override
//   State<GalleryModal> createState() => _GalleryModalState();
// }
//
// class _GalleryModalState extends State<GalleryModal> {
//   final List<File> _selectedFiles = [];
//   bool _isUploading = false;
//   String? _errorMessage;
//   final int _maxImageSize = 8 * 1024 * 1024; // 8MB en octets
//   final int _maxTotalImages = 25;
//
//   int get _remainingSlots => _maxTotalImages - widget.currentImagesCount;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.8,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         children: [
//           _buildHeader(),
//           if (_errorMessage != null) _buildErrorMessage(),
//           Expanded(
//             child: _buildImagePreview(),
//           ),
//           _buildFooter(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 1,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Ajouter des images',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 'Vous pouvez ajouter jusqu\'à $_remainingSlots image(s)',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               Text(
//                 'Taille maximale: 8MB par image',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorMessage() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.red.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.red.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.error_outline, color: Colors.red[700]),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               _errorMessage!,
//               style: GoogleFonts.poppins(color: Colors.red[700]),
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.close, color: Colors.red[700], size: 18),
//             onPressed: () {
//               setState(() {
//                 _errorMessage = null;
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildImagePreview() {
//     if (_selectedFiles.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'Aucune image sélectionnée',
//               style: GoogleFonts.poppins(color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Sélectionnez jusqu\'à $_remainingSlots images',
//               style: GoogleFonts.poppins(color: Colors.grey[500]),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
//           child: Text(
//             'Images sélectionnées (${_selectedFiles.length})',
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               fontSize: 16,
//             ),
//           ),
//         ),
//         Expanded(
//           child: GridView.builder(
//             padding: const EdgeInsets.all(16),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               childAspectRatio: 1,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: _selectedFiles.length,
//             itemBuilder: (context, index) {
//               return Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.file(
//                       _selectedFiles[index],
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       height: double.infinity,
//                     ),
//                   ),
//                   Positioned(
//                     top: -8,
//                     right: -8,
//                     child: GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           _selectedFiles.removeAt(index);
//                         });
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: const BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Icons.close,
//                           color: Colors.white,
//                           size: 16,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildFooter() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 1,
//             offset: const Offset(0, -1),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           ElevatedButton.icon(
//             onPressed: _remainingSlots > 0 && !_isUploading ? _pickImages : null,
//             icon: const Icon(Icons.photo_library),
//             label: Text('Sélectionner des images', style: GoogleFonts.poppins()),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//               minimumSize: const Size(double.infinity, 48),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _selectedFiles.isNotEmpty && !_isUploading
//                 ? _uploadImages
//                 : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _isUploading
//                   ? Colors.grey
//                   : Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//               minimumSize: const Size(double.infinity, 48),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: _isUploading
//                 ? Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   'Téléchargement en cours...',
//                   style: GoogleFonts.poppins(),
//                 ),
//               ],
//             )
//                 : Text(
//               'Ajouter à la galerie',
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _pickImages() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//         allowMultiple: true,
//         withData: true, // Important: récupérer les données en bytes pour la compatibilité web
//       );
//
//       if (result != null && result.files.isNotEmpty) {
//         List<File> validFiles = [];
//         List<String> errorMessages = [];
//
//         for (var file in result.files) {
//           // Sur le web, nous utilisons les bytes plutôt que le path
//           if (kIsWeb) {
//             if (file.bytes == null) continue;
//
//             // Vérifier la taille
//             if (file.size > _maxImageSize) {
//               errorMessages.add('${file.name} dépasse la taille limite de 8MB');
//               continue;
//             }
//
//             // Pour le web, nous n'avons pas besoin de créer un fichier physique
//             // car nous enverrons directement les bytes
//             // Cependant, pour la prévisualisation, nous simulons un File
//             final tempDir = await getTemporaryDirectory();
//             final tempFile = File('${tempDir.path}/${file.name}');
//             await tempFile.writeAsBytes(file.bytes!);
//             validFiles.add(tempFile);
//           } else {
//             // Sur mobile, nous utilisons le path
//             if (file.path == null) continue;
//
//             final fileObj = File(file.path!);
//             final fileSize = await fileObj.length();
//
//             if (fileSize > _maxImageSize) {
//               errorMessages.add('${file.name} dépasse la taille limite de 8MB');
//               continue;
//             }
//
//             validFiles.add(fileObj);
//           }
//
//           // Vérifier si nous avons atteint le nombre maximal d'images
//           if (_selectedFiles.length + validFiles.length >= _remainingSlots) {
//             errorMessages.add('Nombre maximal d\'images atteint (25 au total)');
//             break;
//           }
//         }
//
//         setState(() {
//           _selectedFiles.addAll(validFiles);
//           if (errorMessages.isNotEmpty) {
//             _errorMessage = errorMessages.join('. ');
//           }
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Erreur lors de la sélection des images: $e';
//       });
//     }
//   }
//
//   Future<void> _uploadImages() async {
//     if (_selectedFiles.isEmpty) return;
//
//     setState(() {
//       _isUploading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       List<SalonImage> newImages = [];
//
//       if (kIsWeb) {
//         // Pour le web, nous ne pouvons pas utiliser File normalement
//         // Nous devons convertir les fichiers en une liste de fichiers adaptée au web
//         final List<http.MultipartFile> webFiles = [];
//
//         for (var file in _selectedFiles) {
//           final bytes = await file.readAsBytes();
//           final fileName = file.path.split('/').last;
//
//           webFiles.add(
//               http.MultipartFile.fromBytes(
//                 'image',
//                 bytes,
//                 filename: fileName,
//               )
//           );
//         }
//
//         // Appel API avec les fichiers convertis pour le web
//         newImages = await GalleryApi.uploadImagesForWeb(
//           widget.salonId,
//           webFiles,
//         );
//       } else {
//         // Pour les plateformes natives
//         newImages = await GalleryApi.uploadImages(
//           widget.salonId,
//           _selectedFiles,
//         );
//       }
//
//       widget.onImagesAdded(newImages);
//       Navigator.pop(context);
//
//     } catch (e) {
//       setState(() {
//         _isUploading = false;
//         _errorMessage = 'Erreur lors du téléchargement des images: $e';
//       });
//     }
//   }
// }