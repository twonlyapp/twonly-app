class SecureStorageKeys {
  @Deprecated('Use the secure storage in rust')
  static const String signalIdentity = 'signal_identity';
  @Deprecated('Use the secure storage in rust')
  static const String signalSignedPreKey = 'signed_pre_key_store';
  @Deprecated('Use the login token')
  static const String apiAuthToken = 'api_auth_token';

  @Deprecated('Use user.json file')
  static const String userData = 'userData';

  // Not required for backup...
  static const String receivingPushKeys = 'push_keys_receiving';
  static const String sendingPushKeys = 'push_keys_sending';
}
