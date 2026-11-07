import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('migrates a legacy plaintext saved password into secure storage',
      () async {
    SharedPreferences.setMockInitialValues({
      'saved_email': 'reader@example.com',
      'saved_pass': 'legacy-secret',
    });
    FlutterSecureStorage.setMockInitialValues({});

    final credentials = await AuthService.getSavedCredentials();
    final preferences = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    expect(credentials, {
      'email': 'reader@example.com',
      'pass': 'legacy-secret',
    });
    expect(preferences.getString('saved_pass'), isNull);
    expect(
      await secureStorage.read(key: 'saved_pass_secure'),
      'legacy-secret',
    );
  });

  test('new saved passwords are not written to SharedPreferences', () async {
    await AuthService.saveCredentials('reader@example.com', 'new-secret');
    final preferences = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    expect(preferences.getString('saved_pass'), isNull);
    expect(
      await secureStorage.read(key: 'saved_pass_secure'),
      'new-secret',
    );
  });

  test('stores and clears the account id with its session', () async {
    await AuthService.saveSession(
      name: 'Reader',
      email: '',
      token: 'session-token',
      userId: 42,
    );
    expect(await AuthService.getUserId(), 42);

    await AuthService.saveSession(
      name: 'Reader without id',
      email: '',
      token: 'new-session-token',
    );
    expect(await AuthService.getUserId(), isNull);
  });
}
