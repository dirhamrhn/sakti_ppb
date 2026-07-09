class CourseFormatter {
  static String getAbbreviation(String name, String code) {
    if (name.isEmpty) return code;
    final nameLower = name.toLowerCase();

    // Specific mappings requested by the user
    if (nameLower.contains('rekayasa perangkat lunak')) {
      return 'RPL';
    }
    if (nameLower.contains('pemrograman perangkat bergerak')) {
      return 'PPB';
    }
    if (nameLower.contains('pemrograman web 2') ||
        nameLower.contains('pemrograman web2') ||
        nameLower.contains('pemrograman web ii')) {
      return 'WEB2';
    }
    if (nameLower.contains('pemrograman web')) {
      return 'WEB';
    }

    // Try to auto-abbreviate words if it contains spaces (e.g. "Struktur Data" -> "SD")
    // Keep numbers intact
    final cleanName = name.replaceAll(RegExp(r'[^\w\s]'), ''); // remove punctuation
    final words = cleanName.trim().split(RegExp(r'\s+'));
    if (words.length > 1) {
      final abbreviation = words.map((w) {
        if (w.isEmpty) return '';
        // If it's a number, keep it as is
        if (RegExp(r'^\d+$').hasMatch(w)) return w;
        return w[0].toUpperCase();
      }).join('');
      if (abbreviation.length >= 2) return abbreviation;
    }

    // Fallback: If code is not a generic "TIN00x" code, use code.
    if (code.isNotEmpty && !code.toUpperCase().startsWith('TIN')) {
      return code;
    }

    if (name.length <= 8) {
      return name.toUpperCase();
    }

    return code;
  }
}
