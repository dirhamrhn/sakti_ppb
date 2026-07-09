class AppValidator {
  AppValidator._();

  /// Email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }

    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!regex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }

    return null;
  }

  /// Password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }

    return null;
  }

  /// Required
  static String? required(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field tidak boleh kosong';
    }

    return null;
  }

  /// NIM
  static String? nim(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIM tidak boleh kosong';
    }

    if (value.length < 10) {
      return 'NIM tidak valid';
    }

    return null;
  }
}
