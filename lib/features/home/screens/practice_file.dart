
import 'package:dio/dio.dart';
//used for converting data, encodeing and decoding data, from dart object to json, and from json to dart object.
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
//cookie manager is like a middle ware or interceptor that connects cokkie jar to dio, so that dio can automatically add cookies to your api requests, and also save cookies from responses, so you don't have to manage cookies manually.
import 'package:cookie_jar/cookie_jar.dart';
//this package automatically adds cookies to your api requests, and also saves cookies from responses, so you don't have to manage cookies manually.
import 'package:flutter/foundation.dart';
//this package helps in checking if the app is running in mobile or web, so that we can use the appropriate cookie storage method.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//it is secure encryption storage for flutter, it is used to store sensitive data like tokens, passwords, etc. it uses the underlying platform's secure storage mechanism, like Keychain for iOS and Keystore for Android.

class practice{

  static const _storage = FlutterSecureStorage();
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5), 
      headers: {
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
    ),
  );
}