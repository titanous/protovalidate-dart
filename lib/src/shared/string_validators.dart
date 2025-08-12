import '../parsers/ipv4_parser.dart';
import '../parsers/ipv6_parser.dart';
import '../parsers/uri_parser.dart';

/// Refactored string validation functions using parser classes
/// Following the pattern from protovalidate-es for cleaner, more maintainable code
class StringValidators {
  
  /// Returns true if the value is infinite, optionally limit to positive or
  /// negative infinity.
  static bool isInf(double val, [int? sign]) {
    sign ??= 0;
    return (sign >= 0 && val == double.infinity) ||
           (sign <= 0 && val == double.negativeInfinity);
  }

  /// Returns true if the string is an IPv4 or IPv6 address, optionally limited to
  /// a specific version.
  /// 
  /// Version 0 means either 4 or 6. Passing a version other than 0, 4, or 6 always
  /// returns false.
  static bool isIp(String str, [int? version]) {
    if (version == 6) {
      return Ipv6Parser(str).address();
    }
    if (version == 4) {
      return Ipv4Parser(str).address();
    }
    if (version == null || version == 0) {
      return Ipv4Parser(str).address() || Ipv6Parser(str).address();
    }
    return false;
  }

  /// Returns true if the string is a valid IP with prefix length, optionally
  /// limited to a specific version (v4 or v6), and optionally requiring the host
  /// portion to be all zeros.
  static bool isIpPrefix(String str, [int? version, bool strict = false]) {
    if (version == 6) {
      final ip = Ipv6Parser(str);
      return ip.addressPrefix() && (!strict || ip.isPrefixOnly());
    }
    if (version == 4) {
      final ip = Ipv4Parser(str);
      return ip.addressPrefix() && (!strict || ip.isPrefixOnly());
    }
    if (version == null || version == 0) {
      return isIpPrefix(str, 6, strict) || isIpPrefix(str, 4, strict);
    }
    return false;
  }

  /// Returns true if the string is a valid hostname
  static bool isHostname(String str) {
    if (str.length > 253) {
      return false;
    }
    final s = str.endsWith('.') ? str.substring(0, str.length - 1) : str;
    bool allDigits = false;
    // split hostname on '.' and validate each part
    final parts = s.split('.');
    for (final part in parts) {
      allDigits = true;
      // if part is empty, longer than 63 chars, or starts/ends with '-', it is invalid
      final l = part.length;
      if (l == 0 || l > 63 || part.startsWith('-') || part.endsWith('-')) {
        return false;
      }
      // for each character in part
      for (int i = 0; i < part.length; i++) {
        final ch = part[i];
        // if the character is not a-z, A-Z, 0-9, or '-', it is invalid
        if ((ch.compareTo('a') < 0 || ch.compareTo('z') > 0) &&
            (ch.compareTo('A') < 0 || ch.compareTo('Z') > 0) &&
            (ch.compareTo('0') < 0 || ch.compareTo('9') > 0) &&
            ch != '-') {
          return false;
        }
        allDigits = allDigits && ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0;
      }
    }
    // the last part cannot be all numbers
    return !allDigits;
  }

  /// Returns true if the string is a valid host/port pair
  static bool isHostAndPort(String str, bool portRequired) {
    if (str.isEmpty) {
      return false;
    }
    final splitIdx = str.lastIndexOf(':');
    if (str[0] == '[') {
      final end = str.lastIndexOf(']');
      switch (end + 1) {
        case -1:
          return false; // No closing bracket
        default:
          if (end + 1 == str.length) {
            // no port
            return !portRequired && isIp(str.substring(1, end), 6);
          } else if (end + 1 == splitIdx) {
            // port
            return isIp(str.substring(1, end), 6) && isPort(str.substring(splitIdx + 1));
          } else {
            // malformed
            return false;
          }
      }
    }
    if (splitIdx < 0) {
      return !portRequired && (isHostname(str) || isIp(str, 4));
    }
    final host = str.substring(0, splitIdx);
    final port = str.substring(splitIdx + 1);
    return (isHostname(host) || isIp(host, 4)) && isPort(port);
  }

  static bool isPort(String str) {
    if (str.isEmpty) {
      return false;
    }
    for (int i = 0; i < str.length; i++) {
      final c = str[i];
      if (c.compareTo('0') < 0 || c.compareTo('9') > 0) {
        return false;
      }
    }
    if (str.length > 1 && str[0] == '0') {
      return false;
    }
    final port = int.tryParse(str);
    return port != null && port <= 65535;
  }

  /// Returns true if the string is an email address
  /// Conforms to the definition for a valid email address from the HTML standard.
  static bool isEmail(String str) {
    // See https://html.spec.whatwg.org/multipage/input.html#valid-e-mail-address
    return RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    ).hasMatch(str);
  }

  /// Returns true if the string is a URI
  static bool isUri(String str) {
    return UriParser(str).uri();
  }

  /// Returns true if the string is a URI Reference
  static bool isUriRef(String str) {
    return UriParser(str).uriReference();
  }

  /// Returns true if the array only contains values that are distinct
  static bool unique(List<dynamic> list) {
    // For simple types, use Set
    final seen = <dynamic>{};
    for (final item in list) {
      if (item is List<int>) {
        // For bytes, we need custom comparison
        bool found = false;
        for (final existing in seen) {
          if (existing is List<int> && _bytesEqual(existing, item)) {
            found = true;
            break;
          }
        }
        if (found) return false;
        seen.add(item);
      } else {
        if (!seen.add(item)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Returns true if argument bytes contains argument sub.
  static bool bytesContains(List<int> bytes, List<int> sub) {
    if (sub.isEmpty) {
      return true;
    }
    if (sub.length > bytes.length) {
      return false;
    }
    for (int i = 0; i < bytes.length - sub.length + 1; i++) {
      bool found = true;
      for (int j = 0; j < sub.length; j++) {
        if (bytes[i + j] != sub[j]) {
          found = false;
          break;
        }
      }
      if (found) {
        return true;
      }
    }
    return false;
  }

  /// Returns true if argument bytes starts with argument sub.
  static bool bytesStartsWith(List<int> bytes, List<int> sub) {
    if (sub.length > bytes.length) {
      return false;
    }
    for (int i = 0; i < sub.length; i++) {
      if (sub[i] != bytes[i]) {
        return false;
      }
    }
    return true;
  }

  /// Returns true if argument bytes ends with argument sub.
  static bool bytesEndsWith(List<int> bytes, List<int> sub) {
    if (sub.length > bytes.length) {
      return false;
    }
    for (int i = 0; i < sub.length; i++) {
      if (sub[sub.length - i - 1] != bytes[bytes.length - i - 1]) {
        return false;
      }
    }
    return true;
  }

  // Helper methods
  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Additional validators that were in original but simplified

  /// UUID validation
  static bool isUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      caseSensitive: false
    );
    return uuidRegex.hasMatch(value);
  }

  /// TUUID validation (trimmed UUID - no dashes)
  static bool isTuuid(String value) {
    final tuuidRegex = RegExp(r'^[0-9a-fA-F]{32}$');
    return tuuidRegex.hasMatch(value);
  }

  /// Address validation (IP or hostname)
  static bool isAddress(String value) {
    return isIp(value) || isHostname(value);
  }

  /// HTTP header name validation (RFC 7230)
  static bool isHttpHeaderName(String value, bool strict) {
    if (value.isEmpty) {
      return false;
    }
    
    if (strict) {
      // RFC 7230 compliant: field-name = token
      // Token chars are: !#$%&'*+-.0-9A-Z^_`a-z|~
      // Explicitly exclude: ()<>@,;:\\"/[]?={} SPACE TAB and CTLs
      for (int i = 0; i < value.length; i++) {
        final char = value.codeUnitAt(i);
        // Check if char is a valid token character
        if (!((char >= 0x30 && char <= 0x39) || // 0-9
              (char >= 0x41 && char <= 0x5A) || // A-Z
              (char >= 0x61 && char <= 0x7A) || // a-z
              char == 0x21 || // !
              char == 0x23 || // #
              char == 0x24 || // $
              char == 0x25 || // %
              char == 0x26 || // &
              char == 0x27 || // '
              char == 0x2A || // *
              char == 0x2B || // +
              char == 0x2D || // -
              char == 0x2E || // .
              char == 0x5E || // ^
              char == 0x5F || // _
              char == 0x60 || // `
              char == 0x7C || // |
              char == 0x7E)) { // ~
          return false;
        }
      }
      return true;
    } else {
      // Loose validation: allow DEL (\x07) and other control characters
      // Just disallow \r\n\0
      return !value.contains('\r') && 
             !value.contains('\n') && 
             !value.contains('\x00');
    }
  }

  /// HTTP header value validation (RFC 7230)
  static bool isHttpHeaderValue(String value, bool strict) {
    if (strict) {
      // Check for invalid characters
      for (int i = 0; i < value.length; i++) {
        final char = value.codeUnitAt(i);
        // Allow VCHAR (0x21-0x7E), SP (0x20), HTAB (0x09), and obs-text (0x80-0xFF)
        if (!((char >= 0x20 && char <= 0x7E) || 
              char == 0x09 || 
              (char >= 0x80 && char <= 0xFF))) {
          return false;
        }
      }
      return true;
    } else {
      // Loose validation: just disallow \r\n\0
      return !value.contains('\r') && 
             !value.contains('\n') && 
             !value.contains('\x00');
    }
  }

}