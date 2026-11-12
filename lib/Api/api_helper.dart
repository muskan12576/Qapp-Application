import 'package:qapp/Api/api_exceptions.dart';

typedef ErrorHandler = void Function(String);

class ApiHelper {
  static Future<T?> safeApiCall<T>({
    required Future<T> Function() apiCall,
    required ErrorHandler onError,
  }) async {
    try {
      return await apiCall();
    } on ApiException catch (err) {
      onError(err.message);
      return null;
    } catch (_) {
      onError('Something went wrong. Please try again.');
      return null;
    }
  }
}
