import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:dtc6464/routes/app_routes.dart';
import 'package:get/get.dart' hide Response, MultipartFile;
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart';

import '../models/response_data.dart';
import '../services/storage_service.dart';
import '../utils/constants/api_constants.dart';

class NetworkCaller {
  final int timeoutDuration = 120;
  static bool _isRefreshing = false;
  static Completer<String?>? _refreshCompleter;
  static int _retryCount = 0;
  static const int _maxRetries = 3;

  /// GET method
  Future<ResponseData> getRequest(String url, {String? token}) async {
    log('GET Request: $url');
    log('GET Token: $token');
    try {
      final Response response = await get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${token.toString()}',
          'Content-type': 'application/json',
        },
      ).timeout(
        Duration(seconds: timeoutDuration),
      );

      // Handle 401 - Unauthorized
      if (response.statusCode == 401) {
        return await _handleUnauthorized(
              (newToken) => getRequest(url, token: newToken),
        );
      }

      // Reset retry count on successful request
      _retryCount = 0;
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST method
  Future<ResponseData> postRequest(String url,
      {Map<String, dynamic>? body, String? token}) async {
    log('POST Request: $url');
    log('Request Body: ${jsonEncode(body)}');

    try {
      final Response response = await post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${token.toString()}',
          'Content-type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(Duration(seconds: timeoutDuration));

      // Handle 401 - Unauthorized
      if (response.statusCode == 401) {
        return await _handleUnauthorized(
              (newToken) => postRequest(url, body: body, token: newToken),
        );
      }

      // Reset retry count on successful request
      _retryCount = 0;
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PATCH method (fixed typo from pathcRequest to patchRequest)
  Future<ResponseData> patchRequest(String url,
      {Map<String, dynamic>? body, String? token}) async {
    log('PATCH Request: $url');
    log('Request Body: ${jsonEncode(body)}');

    try {
      final Response response = await patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${token.toString()}',
          'Content-type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(Duration(seconds: timeoutDuration));

      // Handle 401 - Unauthorized
      if (response.statusCode == 401) {
        return await _handleUnauthorized(
              (newToken) => patchRequest(url, body: body, token: newToken),
        );
      }

      // Reset retry count on successful request
      _retryCount = 0;
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE method
  Future<ResponseData> deleteRequest(String url, {Map<String, dynamic>? body, String? token}) async {
    log('DELETE Request: $url');
    log('DELETE Token: $token');
    try {
      final Response response = await delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${token.toString()}',
          'Content-type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: timeoutDuration),
      );

      // Handle 401 - Unauthorized
      if (response.statusCode == 401) {
        return await _handleUnauthorized(
              (newToken) => deleteRequest(url, token: newToken),
        );
      }

      // Reset retry count on successful request
      _retryCount = 0;
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST Multipart Request (for file uploads)
  Future<ResponseData> postMultipartRequest(
      String url, {
        required Map<String, String> fields,
        required List<String> filePaths,
        String? token,
        String fileFieldName = 'resume',
      }) async {
    log('POST Multipart Request: $url');
    log('Fields: $fields');
    log('File Paths: $filePaths');

    try {
      var request = MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll({
        'Authorization': 'Bearer ${token ?? ''}',
        'Content-type': 'multipart/form-data',
      });

      request.fields.addAll(fields);

      for (String path in filePaths) {
        request.files.add(await MultipartFile.fromPath(fileFieldName, path));
      }

      StreamedResponse streamedResponse = await request.send().timeout(Duration(seconds: 120));
      final response = await Response.fromStream(streamedResponse);

      // Handle 401 - Unauthorized
      if (response.statusCode == 401) {
        return await _handleUnauthorized(
              (newToken) => postMultipartRequest(
            url,
            fields: fields,
            filePaths: filePaths,
            token: newToken,
            fileFieldName: fileFieldName,
          ),
        );
      }

      // Reset retry count on successful request
      _retryCount = 0;
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Handle 401 Unauthorized - Refresh token and retry
  Future<ResponseData> _handleUnauthorized(
      Future<ResponseData> Function(String newToken) retryRequest,
      ) async {
    // If already refreshing, wait for the ongoing refresh to complete
    if (_isRefreshing && _refreshCompleter != null) {
      log('Token refresh already in progress. Waiting for completion...');

      try {
        final newToken = await _refreshCompleter!.future
            .timeout(Duration(seconds: timeoutDuration));

        if (newToken != null && newToken.isNotEmpty) {
          log('✅ Got refreshed token from queue. Retrying request...');
          return await retryRequest(newToken);
        } else {
          log('❌ Token refresh failed in queue');
          return _sessionExpiredResponse();
        }
      } catch (e) {
        log('❌ Error waiting for token refresh: $e');
        return _sessionExpiredResponse();
      }
    }

    // Start a new refresh process
    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final String? currentRefreshToken = StorageService.refreshToken;

      // If no refresh token exists, redirect to login immediately
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        log('❌ Refresh token missing. Redirecting to login.');
        _refreshCompleter!.complete(null);
        await _navigateToLogin();
        return _sessionExpiredResponse();
      }

      // Combine baseUrl and token path
      final String refreshUrl = ApiConstant.baseUrl + ApiConstant.token;
      log('🔄 Starting token refresh at: $refreshUrl');

      final response = await post(
        Uri.parse(refreshUrl),
        headers: {'Content-type': 'application/json'},
        body: jsonEncode({'refreshToken': currentRefreshToken}),
      ).timeout(Duration(seconds: timeoutDuration));

      log('Refresh Response Status: ${response.statusCode}');
      log('Refresh Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final decodedBody = jsonDecode(response.body);
          log('Decoded refresh response: $decodedBody');

          final data = decodedBody['data'];
          if (data == null) {
            log('❌ No data field in refresh response');
            _refreshCompleter!.complete(null);
            await _navigateToLogin();
            return _sessionExpiredResponse();
          }

          final String? newAccess = data['accessToken']?.toString();
          final String? newRefresh = data['refreshToken']?.toString();

          log('New access token length: ${newAccess?.length ?? 0}');
          log('New refresh token length: ${newRefresh?.length ?? 0}');

          if (newAccess != null && newAccess.isNotEmpty) {
            // Save new tokens
            await StorageService.saveTokens(
              accessToken: newAccess,
              refreshToken: newRefresh ?? currentRefreshToken,
              userId: StorageService.userId ?? '',
            );

            log('✅ Token refreshed successfully. Retrying original request...');

            // Complete the future with the new token for other waiting requests
            _refreshCompleter!.complete(newAccess);

            // Retry with the new token
            return await retryRequest(newAccess);
          } else {
            log('❌ New access token is null or empty');
            _refreshCompleter!.complete(null);
            await _navigateToLogin();
            return _sessionExpiredResponse();
          }
        } catch (parseError) {
          log('❌ Error parsing refresh response: $parseError');
          _refreshCompleter!.complete(null);
          await _navigateToLogin();
          return _sessionExpiredResponse();
        }
      }

      // If response is not 200/201, the refresh token is invalid
      log('❌ Refresh token invalid or expired (Status: ${response.statusCode})');
      _refreshCompleter!.complete(null);
      await _navigateToLogin();
      return _sessionExpiredResponse();
    } on TimeoutException {
      log('❌ Token refresh timeout');
      _refreshCompleter!.complete(null);
      await _navigateToLogin();
      return ResponseData(
        isSuccess: false,
        statusCode: 408,
        responseData: '',
        errorMessage: 'Token refresh timeout. Please login again.',
      );
    } catch (e) {
      log('❌ Error during token refresh: $e');
      _refreshCompleter!.complete(null);
      await _navigateToLogin();
      return _sessionExpiredResponse();
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  /// Navigate to login screen and clear data
  Future<void> _navigateToLogin() async {
    try {
      await StorageService.logoutUser();
      Get.offAllNamed(AppRoute.getOnboardingScreen2());
    } catch (e) {
      log('Error during navigation to login: $e');
    }
  }

  /// Session expired response
  ResponseData _sessionExpiredResponse() {
    return ResponseData(
      isSuccess: false,
      statusCode: 401,
      responseData: '',
      errorMessage: 'Session expired. Please login again.',
    );
  }

  /// Handle response
  ResponseData _handleResponse(Response response) {
    log('Response Status: ${response.statusCode}');
    log('Response Body: ${response.body}');

    try {
      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decodedResponse['success'] == true) {
          return ResponseData(
            isSuccess: true,
            statusCode: response.statusCode,
            responseData: decodedResponse,
            errorMessage: '',
          );
        } else {
          return ResponseData(
            isSuccess: false,
            statusCode: response.statusCode,
            responseData: decodedResponse,
            errorMessage: decodedResponse['message'] ?? 'Unknown error occurred',
          );
        }
      } else if (response.statusCode == 400) {
        return ResponseData(
          isSuccess: false,
          statusCode: response.statusCode,
          responseData: decodedResponse,
          errorMessage: _extractErrorMessages(decodedResponse['errorSources']),
        );
      } else if (response.statusCode == 500) {
        return ResponseData(
          isSuccess: false,
          statusCode: response.statusCode,
          responseData: '',
          errorMessage:
          decodedResponse['message'] ?? 'An unexpected error occurred!',
        );
      } else {
        return ResponseData(
          isSuccess: false,
          statusCode: response.statusCode,
          responseData: decodedResponse,
          errorMessage:
          decodedResponse['message'] ?? 'An unknown error occurred',
        );
      }
    } catch (e) {
      log('Error parsing response: $e');
      return ResponseData(
        isSuccess: false,
        statusCode: response.statusCode,
        responseData: '',
        errorMessage: 'Error parsing server response',
      );
    }
  }

  /// Extract error messages for status 400
  String _extractErrorMessages(dynamic errorSources) {
    if (errorSources is List) {
      return errorSources
          .map((error) => error['message'] ?? 'Unknown error')
          .join(', ');
    }
    return 'Validation error';
  }

  /// Handle errors
  ResponseData _handleError(dynamic error) {
    log('Request Error: $error');

    if (error is ClientException) {
      return ResponseData(
        isSuccess: false,
        statusCode: 500,
        responseData: '',
        errorMessage: 'Network error occurred. Please check your connection.',
      );
    } else if (error is TimeoutException) {
      return ResponseData(
        isSuccess: false,
        statusCode: 408,
        responseData: '',
        errorMessage: 'Request timeout. Please try again later.',
      );
    } else {
      return ResponseData(
        isSuccess: false,
        statusCode: 500,
        responseData: '',
        errorMessage: 'Unexpected error: ${error.toString()}',
      );
    }
  }
}