import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';




// Usage
// try {
// var result = await predictImage(myImageFile);
// print('Predicted class: ${result['class']}');
// print('Accuracy: ${result['accuracy']}%');
// } catch (e) {
// print('Error: $e');
// }


//
// class IMAGERECO extends StatefulWidget {
//   const IMAGERECO({Key? key}) : super(key: key);
//
//   @override
//   State<IMAGERECO> createState() => _IMAGERECOState();
// }
//
// class _IMAGERECOState extends State<IMAGERECO> {
//   XFile? _image;
//   String _className = '';
//   double _accuracy = 0.0;
//
//   Future<Map<String, dynamic>> predictImage(XFile imageFile) async {
//     var uri = Uri.parse('http://127.0.0.1:5000/predict');
//     var request = http.MultipartRequest('POST', uri);
//     request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
//
//     var response = await request.send();
//     if (response.statusCode == 200) {
//       String responseBody = await response.stream.bytesToString();
//       return json.decode(responseBody);
//     } else {
//       throw Exception('Failed to predict image');
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       setState(() {
//         _image = pickedFile;
//         _className = '';
//         _accuracy = 0.0;
//       });
//
//       try {
//         var result = await predictImage(pickedFile);
//         setState(() {
//           _className = result['class'];
//           _accuracy = result['accuracy'].toDouble();
//         });
//       } catch (e) {
//         print('Error: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error predicting image: $e')),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Image Recognition'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             GestureDetector(
//               onTap: _pickImage,
//               child: Icon(Icons.image, size: 100),
//             ),
//             SizedBox(height: 20),
//             if (_image != null)
//               Image.file(
//                 File(_image!.path),
//                 height: 200,
//                 width: 200,
//                 fit: BoxFit.cover,
//               ),
//             SizedBox(height: 20),
//             Text(
//               'Class: $_className',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               'Accuracy: ${_accuracy.toStringAsFixed(2)}%',
//               style: TextStyle(fontSize: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class IMAGERECO extends StatefulWidget {
  const IMAGERECO({Key? key}) : super(key: key);

  @override
  State<IMAGERECO> createState() => _IMAGERECOState();
}

class _IMAGERECOState extends State<IMAGERECO> {
  String? _imagePath;
  String _className = '';
  double _accuracy = 0.0;
  Future<Map<String, dynamic>> predictImage(String imagePath) async {
    var uri = Uri.parse('http://127.0.0.1:5000/predict');
    var request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      // For web, we need to handle file upload differently
      final bytes = await (await http.get(Uri.parse(imagePath))).bodyBytes;
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'image.png'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to predict image: ${response.body}');
      }
    } catch (e) {
      print('Error during prediction: $e');
      rethrow;
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final html.FileUploadInputElement input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      await input.onChange.first;
      final file = input.files!.first;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      await reader.onLoad.first;
      setState(() {
        _imagePath = reader.result as String;
      });
    } else {
      // For testing, we'll use the asset image
      setState(() {
        _imagePath = 'assets/apple.png';
      });
    }

    if (_imagePath != null) {
      try {
        var result = await predictImage(_imagePath!);
        setState(() {
          _className = result['class'];
          _accuracy = result['accuracy'].toDouble();
        });
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error predicting image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Recognition'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Icon(Icons.image, size: 100),
            ),
            SizedBox(height: 20),
            if (_imagePath != null)
              kIsWeb
                  ? Image.network(
                _imagePath!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              )
                  : Image.asset(
                _imagePath!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
            Text(
              'Class: $_className',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Accuracy: ${_accuracy.toStringAsFixed(2)}%',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}