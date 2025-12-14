// Stub implementation for non-web platforms
String? getItem(String key) {
  return null;
}

void setItem(String key, String value) {
  // No-op on non-web platforms
}

void removeItem(String key) {
  // No-op on non-web platforms
}

bool get isWeb => false;
