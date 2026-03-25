import 'dart:io';
import 'dart:convert';

/// Quick script to fix the API URL in Flutter secure storage
/// Run with: dart fix_api_url.dart
void main() async {
  print('Fixing API URL in secure storage...');

  // For web, flutter_secure_storage stores data in localStorage
  // We need to clear it or update it manually

  print('');
  print('The API URL is stored in secure storage.');
  print('To fix this, run the following in your browser console:');
  print('');
  print('  localStorage.removeItem("flutter.app_secure_config_v1");');
  print('  location.reload();');
  print('');
  print('This will clear the incorrect API URL and let the app use the default.');
  print('');
  print('Alternatively, update it with the correct URL:');
  print('');
  print('  const config = {"api_base_url":"http://localhost:8000","configured_at":"${DateTime.now().toIso8601String()}"};');
  print('  localStorage.setItem("flutter.app_secure_config_v1", JSON.stringify(config));');
  print('  location.reload();');
  print('');
}
