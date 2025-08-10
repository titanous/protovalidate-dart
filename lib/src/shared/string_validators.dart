/// Shared string validation functions used by both CEL library and core validators.
/// This ensures consistency between different validation paths.
class StringValidators {
  
  // Email validation following HTML5 spec
  static bool isValidEmail(String value) {
    if (value.isEmpty || value.length > 254) return false;
    
    // Basic email validation - more comprehensive than simple regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9._-]*[a-zA-Z0-9])?@[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$'
    );
    
    if (!emailRegex.hasMatch(value)) return false;
    
    // Check for valid local and domain parts
    final parts = value.split('@');
    if (parts.length != 2) return false;
    
    final local = parts[0];
    final domain = parts[1];
    
    // Local part validation
    if (local.isEmpty || local.length > 64) return false;
    if (local.startsWith('.') || local.endsWith('.')) return false;
    if (local.contains('..')) return false;
    
    // Domain part validation
    if (domain.isEmpty || domain.length > 253) return false;
    
    return isValidHostname(domain);
  }

  // Hostname validation
  static bool isValidHostname(String value) {
    if (value.isEmpty || value.length > 253) return false;
    
    String hostname = value;
    if (hostname.endsWith('.')) {
      hostname = hostname.substring(0, hostname.length - 1);
    }
    
    // Split into labels
    final labels = hostname.split('.');
    if (labels.isEmpty) return false;
    
    for (final label in labels) {
      if (label.isEmpty || label.length > 63) return false;
      if (label.startsWith('-') || label.endsWith('-')) return false;
      
      // Check that label contains only valid characters
      final labelRegex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$');
      if (!labelRegex.hasMatch(label)) return false;
    }
    
    return true;
  }

  // IP validation (v4 or v6)
  static bool isValidIP(String value) {
    return isValidIPv4(value) || isValidIPv6(value);
  }

  // IPv4 validation
  static bool isValidIPv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      if (part.isEmpty) return false;
      
      // No leading zeros unless it's just "0"
      if (part.length > 1 && part.startsWith('0')) return false;
      
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  // IPv6 validation
  static bool isValidIPv6(String value) {
    if (value.isEmpty) return false;
    
    // Handle IPv6 with embedded IPv4
    String ipv6Part = value;
    if (value.contains('.')) {
      final lastColon = value.lastIndexOf(':');
      if (lastColon == -1) return false;
      
      final ipv4Part = value.substring(lastColon + 1);
      if (!isValidIPv4(ipv4Part)) return false;
      
      ipv6Part = value.substring(0, lastColon + 1) + '0:0';
    }
    
    // Handle :: notation
    final doubleColonCount = '::'.allMatches(ipv6Part).length;
    if (doubleColonCount > 1) return false;
    
    List<String> parts;
    if (doubleColonCount == 1) {
      final splitParts = ipv6Part.split('::');
      if (splitParts.length != 2) return false;
      
      final leftParts = splitParts[0].isEmpty ? <String>[] : splitParts[0].split(':');
      final rightParts = splitParts[1].isEmpty ? <String>[] : splitParts[1].split(':');
      
      final totalParts = leftParts.length + rightParts.length;
      if (totalParts > 8) return false;
      
      parts = List<String>.from(leftParts);
      for (int i = 0; i < 8 - totalParts; i++) {
        parts.add('0');
      }
      parts.addAll(rightParts);
    } else {
      parts = ipv6Part.split(':');
      if (parts.length != 8) return false;
    }
    
    // Validate each part
    for (final part in parts) {
      if (part.isEmpty && doubleColonCount == 0) return false;
      if (part.length > 4) return false;
      
      if (part.isNotEmpty) {
        final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
        if (!hexRegex.hasMatch(part)) return false;
      }
    }
    
    return true;
  }

  // URI validation
  static bool isValidURI(String value) {
    if (!_isValidURIChars(value)) return false;
    
    try {
      final uri = Uri.parse(value);
      return uri.hasScheme && uri.scheme.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // URI reference validation
  static bool isValidURIRef(String value) {
    if (!_isValidURIChars(value)) return false;
    
    try {
      Uri.parse(value);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Check for invalid URI characters
  static bool _isValidURIChars(String value) {
    // Check for invalid control characters (0x00-0x1F, 0x7F)
    for (int i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code <= 0x1F || code == 0x7F) {
        return false;
      }
      
      // Check for invalid characters that should be percent-encoded
      // These characters are not allowed unencoded in URIs: < > " { } | \ ^ `
      final char = value[i];
      if ('<>"{}|\\^`'.contains(char)) {
        return false;
      }
    }
    
    // Check for invalid percent encoding (must be %HH where H is hex digit)
    int i = 0;
    while (i < value.length) {
      if (value[i] == '%') {
        // Must be followed by exactly 2 hex digits
        if (i + 2 >= value.length) {
          return false;
        }
        final hex1 = value[i + 1];
        final hex2 = value[i + 2];
        if (!_isHexDigit(hex1) || !_isHexDigit(hex2)) {
          return false;
        }
        i += 3;
      } else {
        i++;
      }
    }
    
    return true;
  }
  
  static bool _isHexDigit(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 48 && code <= 57) ||  // 0-9
           (code >= 65 && code <= 70) ||  // A-F
           (code >= 97 && code <= 102);   // a-f
  }

  // UUID validation
  static bool isValidUUID(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      caseSensitive: false
    );
    return uuidRegex.hasMatch(value);
  }

  // TUUID validation (trimmed UUID - no dashes)
  static bool isValidTUUID(String value) {
    final tuuidRegex = RegExp(r'^[0-9a-fA-F]{32}$');
    return tuuidRegex.hasMatch(value);
  }

  // Address validation (IP or hostname)
  static bool isValidAddress(String value) {
    return isValidIP(value) || isValidHostname(value);
  }

  // IP with prefix length validation
  static bool isValidIPWithPrefixLen(String value) {
    return isValidIPv4WithPrefixLen(value) || isValidIPv6WithPrefixLen(value);
  }

  // IPv4 with prefix length validation
  static bool isValidIPv4WithPrefixLen(String value) {
    final parts = value.split('/');
    if (parts.length != 2) return false;
    
    if (!isValidIPv4(parts[0])) return false;
    
    final prefixLen = int.tryParse(parts[1]);
    if (prefixLen == null || prefixLen < 0 || prefixLen > 32) return false;
    
    return true;
  }

  // IPv6 with prefix length validation
  static bool isValidIPv6WithPrefixLen(String value) {
    final parts = value.split('/');
    if (parts.length != 2) return false;
    
    if (!isValidIPv6(parts[0])) return false;
    
    final prefixLen = int.tryParse(parts[1]);
    if (prefixLen == null || prefixLen < 0 || prefixLen > 128) return false;
    
    return true;
  }

  // IPv4 prefix validation
  static bool isValidIPv4Prefix(String value) {
    // IPv4 prefix format: x.x.x.x/y where y is 0-32
    final parts = value.split('/');
    if (parts.length != 2) return false;
    
    final ip = parts[0];
    final prefixLength = int.tryParse(parts[1]);
    
    if (prefixLength == null || prefixLength < 0 || prefixLength > 32) {
      return false;
    }
    
    // Parse and validate IPv4 address
    final ipParts = ip.split('.');
    if (ipParts.length != 4) return false;
    
    for (final part in ipParts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    
    return true;
  }

  // IPv6 prefix validation
  static bool isValidIPv6Prefix(String value) {
    // IPv6 prefix format: xxxx:xxxx::/y where y is 0-128
    final parts = value.split('/');
    if (parts.length != 2) return false;
    
    final ip = parts[0];
    final prefixLength = int.tryParse(parts[1]);
    
    if (prefixLength == null || prefixLength < 0 || prefixLength > 128) {
      return false;
    }
    
    // Validate IPv6 part
    if (!isValidIPv6(ip)) return false;
    
    return true;
  }

  // IP prefix validation (v4 or v6)
  static bool isValidIPPrefix(String value, {int? version, bool strict = false}) {
    if (value.isEmpty) return false;
    
    // Split into IP and prefix length
    final parts = value.split('/');
    if (parts.length != 2) return false;
    
    final ip = parts[0];
    final prefixLengthStr = parts[1];
    
    // Validate prefix length
    final prefixLength = int.tryParse(prefixLengthStr);
    if (prefixLength == null) return false;
    
    // Determine IP version and validate
    bool isV4 = false;
    bool isV6 = false;
    
    if (isValidIPv4(ip)) {
      isV4 = true;
      if (prefixLength < 0 || prefixLength > 32) return false;
    } else if (isValidIPv6(ip)) {
      isV6 = true;
      if (prefixLength < 0 || prefixLength > 128) return false;
    } else {
      return false;
    }
    
    // Check version requirement
    if (version != null) {
      if (version == 4 && !isV4) return false;
      if (version == 6 && !isV6) return false;
      if (version != 0 && version != 4 && version != 6) return false;
    }
    
    // In strict mode, verify that host bits are zero
    if (strict) {
      if (isV4) {
        return isValidStrictIPv4Prefix(ip, prefixLength);
      } else if (isV6) {
        return isValidStrictIPv6Prefix(ip, prefixLength);
      }
    }
    
    return true;
  }

  // Strict IPv4 prefix validation (host bits must be zero)
  static bool isValidStrictIPv4Prefix(String ip, int prefixLength) {
    // Parse IPv4 address
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    final bytes = <int>[];
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
      bytes.add(num);
    }
    
    // Check that host bits are zero
    int bitsChecked = 0;
    for (int i = 0; i < 4; i++) {
      for (int bit = 7; bit >= 0; bit--) {
        if (bitsChecked >= prefixLength) {
          // This is a host bit, should be zero
          if ((bytes[i] & (1 << bit)) != 0) {
            return false;
          }
        }
        bitsChecked++;
      }
    }
    
    return true;
  }

  // Strict IPv6 prefix validation
  static bool isValidStrictIPv6Prefix(String ip, int prefixLength) {
    // Parse and expand IPv6 address to full form
    final expanded = _expandIPv6(ip);
    if (expanded == null) return false;
    
    // Convert to binary representation
    final parts = expanded.split(':');
    if (parts.length != 8) return false;
    
    final bytes = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part, radix: 16);
      if (value == null) return false;
      bytes.add((value >> 8) & 0xFF);
      bytes.add(value & 0xFF);
    }
    
    // Check that host bits are zero
    int bitsChecked = 0;
    for (int i = 0; i < 16; i++) {
      for (int bit = 7; bit >= 0; bit--) {
        if (bitsChecked >= prefixLength) {
          // This is a host bit, should be zero
          if ((bytes[i] & (1 << bit)) != 0) {
            return false;
          }
        }
        bitsChecked++;
      }
    }
    
    return true;
  }
  
  // Helper to expand IPv6 address to full form
  static String? _expandIPv6(String ip) {
    // Remove any zone identifier
    final zoneIndex = ip.indexOf('%');
    if (zoneIndex >= 0) {
      ip = ip.substring(0, zoneIndex);
    }
    
    // Handle :: expansion
    if (ip.contains('::')) {
      final parts = ip.split('::');
      if (parts.length > 2) return null; // Invalid - multiple ::
      
      final left = parts[0].isEmpty ? [] : parts[0].split(':');
      final right = parts.length > 1 && parts[1].isNotEmpty ? parts[1].split(':') : [];
      
      final totalParts = left.length + right.length;
      if (totalParts > 7) return null; // Too many parts
      
      final middle = List.filled(8 - totalParts, '0');
      final allParts = [...left, ...middle, ...right];
      
      // Pad each part to 4 hex digits
      return allParts.map((part) => part.padLeft(4, '0')).join(':');
    } else {
      // No :: compression
      final parts = ip.split(':');
      if (parts.length != 8) return null;
      
      // Pad each part to 4 hex digits
      return parts.map((part) => part.padLeft(4, '0')).join(':');
    }
  }

  // Host and port validation
  static bool isValidHostAndPort(String value, {bool portRequired = false}) {
    if (value.isEmpty) return false;
    
    // Handle IPv6 addresses in brackets
    String host;
    String? port;
    
    if (value.startsWith('[')) {
      // IPv6 address in brackets
      final closeBracket = value.indexOf(']');
      if (closeBracket == -1) return false;
      
      host = value.substring(1, closeBracket);
      if (!isValidIPv6(host)) return false;
      
      if (closeBracket + 1 < value.length) {
        if (value[closeBracket + 1] != ':') return false;
        port = value.substring(closeBracket + 2);
      }
    } else {
      // Regular hostname or IPv4
      final lastColon = value.lastIndexOf(':');
      if (lastColon == -1) {
        host = value;
      } else {
        // Check if this could be an IPv6 address without brackets (has multiple colons)
        final colonCount = ':'.allMatches(value).length;
        if (colonCount > 1) {
          // This is an IPv6 address without port
          host = value;
        } else {
          host = value.substring(0, lastColon);
          port = value.substring(lastColon + 1);
        }
      }
    }
    
    // Validate the host part
    if (!isValidHostname(host) && !isValidIP(host)) {
      return false;
    }
    
    // Check port requirements
    if (portRequired && (port == null || port.isEmpty)) {
      return false;
    }
    
    // If port is present, validate it
    if (port != null && port.isNotEmpty) {
      if (!isValidPort(port)) {
        return false;
      }
    }
    
    return true;
  }

  static bool isValidPort(String port) {
    if (port.isEmpty) return false;
    
    // Port cannot have leading zeros unless it's just "0"
    if (port.length > 1 && port.startsWith('0')) return false;
    
    final portNum = int.tryParse(port);
    if (portNum == null) return false;
    
    // Port must be in range 0-65535
    return portNum >= 0 && portNum <= 65535;
  }

  // HTTP header name validation (RFC 7230)
  static bool isValidHTTPHeaderName(String value, bool strict) {
    if (strict) {
      // RFC 7230 compliant: field-name = token
      // token = 1*tchar
      // tchar = "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "." /
      //         "^" / "_" / "`" / "|" / "~" / DIGIT / ALPHA
      final headerNameRegex = RegExp(r"^[!#$%&'*+\-.0-9A-Z^_`a-z|~]+$");
      return headerNameRegex.hasMatch(value);
    } else {
      // Loose validation: just disallow \r\n\0
      return !value.contains('\r') && !value.contains('\n') && !value.contains('\x00');
    }
  }

  // HTTP header value validation (RFC 7230)
  static bool isValidHTTPHeaderValue(String value, bool strict) {
    if (strict) {
      // RFC 7230 compliant: field-value = *( field-content / obs-fold )
      // field-content = field-vchar [ 1*( SP / HTAB ) field-vchar ]
      // field-vchar = VCHAR / obs-text
      // VCHAR = %x21-7E (visible characters)
      // obs-text = %x80-FF
      // SP = %x20, HTAB = %x09
      
      // Check for invalid characters
      for (int i = 0; i < value.length; i++) {
        final char = value.codeUnitAt(i);
        // Allow VCHAR (0x21-0x7E), SP (0x20), HTAB (0x09), and obs-text (0x80-0xFF)
        if (!(char >= 0x20 && char <= 0x7E) && char != 0x09 && !(char >= 0x80 && char <= 0xFF)) {
          return false;
        }
      }
      
      return true;
    } else {
      // Loose validation: just disallow \r\n\0
      return !value.contains('\r') && !value.contains('\n') && !value.contains('\x00');
    }
  }
}