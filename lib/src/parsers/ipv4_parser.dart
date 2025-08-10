/// IPv4 address parser following RFC 3986
class Ipv4Parser {
  final String str;
  int i = 0;
  final int l;
  final List<int> octets = [];
  int prefixLen = 0;

  Ipv4Parser(this.str) : l = str.length;

  /// Return the 32-bit value of an address parsed through address() or addressPrefix().
  /// Return 0 if no address was parsed successfully.
  int getBits() {
    if (octets.length != 4) {
      return 0;
    }
    return ((octets[0] << 24) |
            (octets[1] << 16) |
            (octets[2] << 8) |
            octets[3]) &
        0xFFFFFFFF;
  }

  /// Return true if all bits to the right of the prefix-length are all zeros.
  /// Behavior is undefined if addressPrefix() has not been called before, or has
  /// returned false.
  bool isPrefixOnly() {
    final bits = getBits();
    final mask = prefixLen == 32
        ? 0xFFFFFFFF
        : ~(0xFFFFFFFF >> prefixLen) & 0xFFFFFFFF;
    final masked = bits & mask;
    return bits == masked;
  }

  /// Parse IPv4 Address in dotted decimal notation.
  bool address() {
    return addressPart() && i == l;
  }

  /// Parse IPv4 Address prefix.
  bool addressPrefix() {
    return addressPart() && 
           take('/') && 
           prefixLength() && 
           i == l;
  }

  /// Stores value in `prefixLen`
  bool prefixLength() {
    final start = i;
    while (digit()) {
      if (i - start > 2) {
        // max prefix-length is 32 bits, so anything more than 2 digits is invalid
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
    if (value == null || value > 32) {
      // max 32 bits
      return false;
    }
    prefixLen = value;
    return true;
  }

  bool addressPart() {
    final start = i;
    if (decOctet() &&
        take('.') &&
        decOctet() &&
        take('.') &&
        decOctet() &&
        take('.') &&
        decOctet()) {
      return true;
    }
    i = start;
    octets.clear();
    return false;
  }

  bool decOctet() {
    final start = i;
    while (digit()) {
      if (i - start > 3) {
        // decimal octet can be three characters at most
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
    if (value == null || value > 255) {
      return false;
    }
    octets.add(value);
    return true;
  }

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