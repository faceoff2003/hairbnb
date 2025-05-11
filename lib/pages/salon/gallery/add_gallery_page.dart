import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../services/providers/current_user_provider.dart';
import '../../home_page.dart';

class GalleryImage {
  final Uint8List? bytes;
  final File? file;
  GalleryImage({this.bytes, this.file});
}

class AddGalleryPage extends StatefulWidget {
  const AddGalleryPage({super.key});

  @override
  State<AddGalleryPage> createState() => _AddGalleryPageState();
}

class _AddGalleryPageState extends State<AddGalleryPage> {
  List<GalleryImage> _images = [];
  bool _isLoading = false;
  int? salonId;

  @override
  void initState() {
    super.initState();
    _fetchSalonId();
  }

  Future<void> _fetchSalonId() async {
    final currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://www.hairbnb.site/api/get_salon_by_coiffeuse/${currentUser.idTblUser}/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          salonId = data['salon']['idTblSalon'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de la récupération du salon.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur réseau lors de la récupération du salon.")),
      );
    }
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      final validFiles = result.files.where((f) => f.size <= 6 * 1024 * 1024);
      final List<GalleryImage> selectedImages = validFiles.map((f) {
        return kIsWeb
            ? GalleryImage(bytes: f.bytes)
            : GalleryImage(file: File(f.path!));
      }).toList();

      if (selectedImages.length != result.files.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Certaines images dépassent 6MB et ont été ignorées.")),
        );
      }

      setState(() {
        _images.addAll(selectedImages);
        if (_images.length > 12) {
          _images = _images.sublist(0, 12);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Maximum 12 images autorisées.")),
          );
        }
      });
    }
  }

  Future<void> _submitImages() async {
    if (_images.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez ajouter au moins 3 images.")),
      );
      return;
    }

    print("📦 Salon ID pour upload: $salonId");

    if (salonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Salon non trouvé.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://www.hairbnb.site/api/add_images_to_salon/'),
    );
    request.fields['salon'] = salonId.toString();

    for (var image in _images) {
      if (kIsWeb && image.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          image.bytes!,
          filename: 'image.png',
        ));
      } else if (!kIsWeb && image.file != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.file!.path,
          filename: path.basename(image.file!.path),
        ));
      }
    }

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Images téléchargées avec succès.")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur réseau.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text("Galerie du salon"),
        backgroundColor: const Color(0xFF7B61FF),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ajoutez vos meilleures photos ✨",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text("Ajouter des images"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: _images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final image = _images[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb && image.bytes != null
                            ? Image.memory(image.bytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                            : Image.file(image.file!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(0, 0, 0, 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 18, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Envoyer les images", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}







// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as path;
// import 'package:provider/provider.dart';
// import '../../../services/providers/current_user_provider.dart';
//
// class AddGalleryPage extends StatefulWidget {
//   const AddGalleryPage({super.key});
//
//   @override
//   State<AddGalleryPage> createState() => _AddGalleryPageState();
// }
//
// class _AddGalleryPageState extends State<AddGalleryPage> {
//   List<File> _images = [];
//   bool _isLoading = false;
//   int? salonId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchSalonId();
//   }
//
//   Future<void> _fetchSalonId() async {
//     final currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//     if (currentUser == null) return;
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_salon_by_coiffeuse/${currentUser.idTblUser}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(utf8.decode(response.bodyBytes));
//         setState(() {
//           salonId = data['salon_id'];
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erreur lors de la récupération du salon.")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur réseau lors de la récupération du salon.")),
//       );
//     }
//   }
//
//   Future<void> _pickImages() async {
//     final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);
//     if (result != null && result.files.isNotEmpty) {
//       final valid = result.files
//           .where((f) => f.size <= 6 * 1024 * 1024)
//           .map((f) => File(f.path!))
//           .toList();
//
//       if (valid.length != result.files.length) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Certaines images dépassent 6MB et ont été ignorées.")),
//         );
//       }
//
//       setState(() {
//         _images.addAll(valid);
//         if (_images.length > 12) {
//           _images = _images.sublist(0, 12);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Maximum 12 images autorisées.")),
//           );
//         }
//       });
//     }
//   }
//
//   Future<void> _submitImages() async {
//     if (_images.length < 3) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Veuillez ajouter au moins 3 images.")),
//       );
//       return;
//     }
//
//     if (salonId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Salon non trouvé.")),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     final request = http.MultipartRequest(
//       'POST',
//       Uri.parse('https://www.hairbnb.site/api/add_images_to_salon/'),
//     );
//     request.fields['salon'] = salonId.toString();
//
//     for (var file in _images) {
//       request.files.add(await http.MultipartFile.fromPath(
//         'image',
//         file.path,
//         filename: path.basename(file.path),
//       ));
//     }
//
//     try {
//       final streamed = await request.send();
//       final response = await http.Response.fromStream(streamed);
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Images téléchargées avec succès.")),
//         );
//         Navigator.pop(context);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur : ${response.body}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur réseau.")),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         title: const Text("Galerie du salon"),
//         backgroundColor: const Color(0xFF7B61FF),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         automaticallyImplyLeading: false,
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 600),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("Ajoutez entre 3 et 12 photos de votre salon",
//                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
//                     const SizedBox(height: 20),
//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 10,
//                       children: [
//                         ..._images.map((file) => Stack(
//                           children: [
//                             ClipRRect(
//                               borderRadius: BorderRadius.circular(14),
//                               child: Image.file(
//                                 file,
//                                 width: 100,
//                                 height: 100,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                             Positioned(
//                               top: 4,
//                               right: 4,
//                               child: GestureDetector(
//                                 onTap: () => setState(() => _images.remove(file)),
//                                 child: Container(
//                                   decoration: const BoxDecoration(
//                                     color: Color.fromRGBO(0, 0, 0, 0.6),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Icon(Icons.close, size: 18, color: Colors.white),
//                                 ),
//                               ),
//                             )
//                           ],
//                         )),
//                         if (_images.length < 12)
//                           GestureDetector(
//                             onTap: _pickImages,
//                             child: Container(
//                               width: 100,
//                               height: 100,
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFE0E0E0),
//                                 borderRadius: BorderRadius.circular(14),
//                                 border: Border.all(color: Colors.grey.shade400),
//                               ),
//                               child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
//                             ),
//                           )
//                       ],
//                     ),
//                     const SizedBox(height: 30),
//                     MouseRegion(
//                       cursor: SystemMouseCursors.click,
//                       child: SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: _isLoading ? null : _submitImages,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF7B61FF),
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                           ).copyWith(
//                             overlayColor: MaterialStateProperty.all(const Color(0xFF674ED1)),
//                           ),
//                           child: _isLoading
//                               ? const CircularProgressIndicator(color: Colors.white)
//                               : const Text("Envoyer les images", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }






// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as path;
// import 'dart:convert';
// import 'package:provider/provider.dart';
// import '../../../services/providers/current_user_provider.dart';
//
// class AddGalleryPage extends StatefulWidget {
//   const AddGalleryPage({super.key});
//
//   @override
//   State<AddGalleryPage> createState() => _AddGalleryPageState();
// }
//
// class _AddGalleryPageState extends State<AddGalleryPage> {
//   List<File> _images = [];
//   bool _isLoading = false;
//   int? salonId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchSalonId();
//   }
//
//   Future<void> _fetchSalonId() async {
//     final currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;
//     if (currentUser == null) return;
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://www.hairbnb.site/api/get_salon_by_coiffeuse/${currentUser.idTblUser}/'),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(utf8.decode(response.bodyBytes));
//         setState(() {
//           salonId = data['salon_id'];
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erreur lors de la récupération du salon.")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur réseau lors de la récupération du salon.")),
//       );
//     }
//   }
//
//   Future<void> _pickImages() async {
//     final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);
//     if (result != null && result.files.isNotEmpty) {
//       final valid = result.files
//           .where((f) => f.size <= 6 * 1024 * 1024)
//           .map((f) => File(f.path!))
//           .toList();
//
//       if (valid.length != result.files.length) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Certaines images dépassent 6MB et ont été ignorées.")),
//         );
//       }
//
//       setState(() {
//         _images.addAll(valid);
//         if (_images.length > 12) {
//           _images = _images.sublist(0, 12);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Maximum 12 images autorisées.")),
//           );
//         }
//       });
//     }
//   }
//
//   Future<void> _submitImages() async {
//     if (_images.length < 3) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Veuillez ajouter au moins 3 images.")),
//       );
//       return;
//     }
//
//     if (salonId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Salon non trouvé.")),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     final request = http.MultipartRequest(
//       'POST',
//       Uri.parse('https://www.hairbnb.site/api/add_images_to_salon/'),
//     );
//     request.fields['salon'] = salonId.toString();
//
//     for (var file in _images) {
//       request.files.add(await http.MultipartFile.fromPath(
//         'image',
//         file.path,
//         filename: path.basename(file.path),
//       ));
//     }
//
//     try {
//       final streamed = await request.send();
//       final response = await http.Response.fromStream(streamed);
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Images téléchargées avec succès.")),
//         );
//         Navigator.pop(context);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur : ${response.body}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur réseau.")),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         title: const Text("Galerie du salon"),
//         backgroundColor: const Color(0xFF7B61FF),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         automaticallyImplyLeading: false,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Ajoutez entre 3 et 12 photos de votre salon",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
//             const SizedBox(height: 20),
//             Expanded(
//               child: GridView.builder(
//                 itemCount: _images.length + 1,
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   crossAxisSpacing: 10,
//                   mainAxisSpacing: 10,
//                 ),
//                 itemBuilder: (context, index) {
//                   if (index == _images.length) {
//                     return GestureDetector(
//                       onTap: _pickImages,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.grey[200],
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.grey),
//                         ),
//                         child: const Center(
//                           child: Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
//                         ),
//                       ),
//                     );
//                   } else {
//                     return Stack(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: Image.file(
//                             _images[index],
//                             width: double.infinity,
//                             height: double.infinity,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         Positioned(
//                           top: 4,
//                           right: 4,
//                           child: GestureDetector(
//                             onTap: () => setState(() => _images.removeAt(index)),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color.fromRGBO(0, 0, 0, 0.6),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Icon(Icons.close, size: 18, color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   }
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _submitImages,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF7B61FF),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//               ),
//               child: _isLoading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text("Envoyer les images", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }