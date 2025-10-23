// import 'package:http/http.dart' as http;
// import 'dart:convert';

// Future<http.StreamedResponse> patchImage(String url, String filepath) async {
//   url = formater(url);
//   String token = await storage.read(key: "token");
//   var request = http.MultipartRequest('PATCH', Uri.parse(url));
//   request.files.add(await http.MultipartFile.fromPath("img", filepath));
//   request.headers.addAll({
//     "Content-type": "multipart/form-data",
//     "Authorization": "Bearer $token",
//   });
//   var response = request.send();
//   return response;
// }

// String formater(String url) {
//   return baseurl + url;
// }
