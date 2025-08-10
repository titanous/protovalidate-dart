import 'ipv4_parser.dart';

/// IPv6 address parser following RFC 4291, with optional zone id following RFC 4007
class Ipv6Parser {
  final String str;
  int i = 0;
  final int l;
  final List<int> pieces = []; // 16-bit pieces found
  int doubleColonAt = -1; // number of 16-bit pieces found when double colon was found
  bool doubleColonSeen = false;
  String dottedRaw = ''; // dotted notation for right-most 32 bits
  Ipv4Parser? dottedAddr; // dotted notation successfully parsed as IPv4
  bool zoneIdFound = false;
  int prefixLen = 0; // 0 - 128

  Ipv6Parser(this.str) : l = str.length;

  /// Return the 128-bit value of an address parsed through address() or addressPrefix(),
  /// as a 4-tuple of 32-bit values.
  /// Return [0,0,0,0] if no address was parsed successfully.
  List<int> getBits() {
    final p16 = List<int>.from(pieces);
    // handle dotted decimal, add to p16
    if (dottedAddr != null) {
      final dotted32 = dottedAddr!.getBits(); // right-most 32 bits
      p16.add(dotted32 >> 16); // high 16 bits
      p16.add(dotted32 & 0xFFFF); // low 16 bits
    }
    // handle double colon, fill pieces with 0
    if (doubleColonSeen) {
      while (p16.length < 8) {
        // insert a 0 at the double colon position
        p16.insert(doubleColonAt, 0x00000000);
      }
    }
    if (p16.length != 8) {
      return [0, 0, 0, 0];
    }
    return [
      ((p16[0] << 16) | p16[1]) & 0xFFFFFFFF,
      ((p16[2] << 16) | p16[3]) & 0xFFFFFFFF,
      ((p16[4] << 16) | p16[5]) & 0xFFFFFFFF,
      ((p16[6] << 16) | p16[7]) & 0xFFFFFFFF,
    ];
  }

  /// Return true if all bits to the right of the prefix-length are all zeros.
  /// Behavior is undefined if addressPrefix() has not been called before, or has
  /// returned false.
  bool isPrefixOnly() {
    // For each 32-bit piece of the address, require that values to the right of the prefix are zero
    final bits = getBits();
    for (int idx = 0; idx < bits.length; idx++) {
      final p32 = bits[idx];
      final len = prefixLen - 32 * idx;
      final mask = len >= 32
          ? 0xFFFFFFFF
          : len < 0
              ? 0x00000000
              : ~(0xFFFFFFFF >> len) & 0xFFFFFFFF;
      final masked = p32 & mask;
      if (p32 != masked) {
        return false;
      }
    }
    return true;
  }

  /// Parse IPv6 Address following RFC 4291, with optional zone id following RFC 4007.
  bool address() {
    return addressPart() && i == l;
  }

  /// Parse IPv6 Address Prefix following RFC 4291. Zone id is not permitted.
  bool addressPrefix() {
    return addressPart() &&
           !zoneIdFound &&
           take('/') &&
           prefixLength() &&
           i == l;
  }

  /// Stores value in `prefixLen`
  bool prefixLength() {
    final start = i;
    while (digit()) {
      if (i - start > 3) {
        return false;
      }
    }
    final strVal = str.substring(start, i);
    if (strVal.isEmpty) {
      // too short
      return false;
    }
    if (strVal.length > 1 && strVal[0] == '0') {
      // bad leading 0
      return false;
    }
    final value = int.tryParse(strVal);
    if (value == null || value > 128) {
      // max 128 bits
      return false;
    }
    prefixLen = value;
    return true;
  }

  /// Stores dotted notation for right-most 32 bits in `dottedRaw` / `dottedAddr` if found.
  bool addressPart() {
    while (i < l) {
      // dotted notation for right-most 32 bits, e.g. 0:0:0:0:0:ffff:192.1.56.10
      if ((doubleColonSeen || pieces.length == 6) && dotted()) {
        final dotted = Ipv4Parser(dottedRaw);
        if (dotted.address()) {
          dottedAddr = dotted;
          return true;
        }
        return false;
      }

      final result = h16();
      if (result == H16Result.error) {
        return false;
      }
      if (result == H16Result.success) {
        continue;
      }
      if (take(':')) {
        if (take(':')) {
          if (doubleColonSeen) {
            return false;
          }
          doubleColonSeen = true;
          doubleColonAt = pieces.length;
          if (take(':')) {
            return false;
          }
        } else {
          if (i == 1 || i == str.length) {
            // invalid - string cannot start or end on single colon
            return false;
          }
        }
        continue;
      }
      if (i < l && str[i] == '%' && !zoneId()) {
        return false;
      }
      break;
    }
    if (doubleColonSeen) {
      return pieces.length < 8;
    }
    return pieces.length == 8;
  }

  /// Parses the rule from RFC 6874:
  /// RFC 6874: ZoneID = 1*( unreserved / pct-encoded )
  /// There is no definition for the character set allowed in the zone
  /// identifier. RFC 4007 permits basically any non-null string.
  bool zoneId() {
    final start = i;
    if (take('%')) {
      if (l - i > 0) {
        // permit any non-null string
        i = l;
        zoneIdFound = true;
        return true;
      }
    }
    i = start;
    zoneIdFound = false;
    return false;
  }

  /// Parses the rule:
  /// 1*3DIGIT "." 1*3DIGIT "." 1*3DIGIT "." 1*3DIGIT
  /// Stores match in `dottedRaw`.
  bool dotted() {
    final start = i;
    dottedRaw = '';
    while (i < l) {
      if (digit() || take('.')) {
        continue;
      }
      break;
    }
    if (i - start >= 7) {
      dottedRaw = str.substring(start, i);
      return true;
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// h16 = 1*4HEXDIG
  /// If 1-4 hex digits are found, the parsed 16-bit unsigned integer is stored in `pieces` and success is returned.
  /// If 0 hex digits are found, returns noMatch.
  /// If more than 4 hex digits are found, error is returned.
  H16Result h16() {
    final start = i;
    while (hexdig()) {
      // continue
    }
    final strVal = str.substring(start, i);
    if (strVal.isEmpty) {
      // too short - not an error, just no match
      return H16Result.noMatch;
    }
    if (strVal.length > 4) {
      // too long - this is an error
      return H16Result.error;
    }
    pieces.add(int.parse(strVal, radix: 16));
    return H16Result.success;
  }

  /// Parses the rule:
  /// HEXDIG =  DIGIT / "A" / "B" / "C" / "D" / "E" / "F"
  bool hexdig() {
    if (i >= l) return false;
    final c = str[i];
    if (('0'.compareTo(c) <= 0 && c.compareTo('9') <= 0) ||
        ('a'.compareTo(c) <= 0 && c.compareTo('f') <= 0) ||
        ('A'.compareTo(c) <= 0 && c.compareTo('F') <= 0)) {
      i++;
      return true;
    }
    return false;
  }

  /// Parses the rule:
  /// DIGIT = %x30-39  ; 0-9
  bool digit() {
    if (i >= l) return false;
    final c = str[i];
    if ('0'.compareTo(c) <= 0 && c.compareTo('9') <= 0) {
      i++;
      return true;
    }
    return false;
  }

  bool take(String char) {
    if (i < l && str[i] == char) {
      i++;
      return true;
    }
    return false;
  }
}

enum H16Result {
  success,
  noMatch,
  error,
}