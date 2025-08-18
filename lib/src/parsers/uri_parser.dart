import 'ipv4_parser.dart';
import 'ipv6_parser.dart';

/// URI parser following RFC 3986
class UriParser {
  final String str;
  int i = 0;
  final int l;
  bool pctEncodedFound = false;

  UriParser(this.str) : l = str.length;

  /// Parses the rule:
  /// URI = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
  bool uri() {
    final start = i;
    if (!(scheme() && take(':') && hierPart())) {
      i = start;
      return false;
    }
    if (take('?') && !query()) {
      return false;
    }
    if (take('#') && !fragment()) {
      return false;
    }
    if (i != l) {
      i = start;
      return false;
    }
    return true;
  }

  /// Parses the rule:
  /// hier-part = "//" authority path-abempty
  ///           / path-absolute
  ///           / path-rootless
  ///           / path-empty
  bool hierPart() {
    final start = i;
    if (take('/') && take('/') && authority() && pathAbempty()) {
      return true;
    }
    i = start;
    return pathAbsolute() || pathRootless() || pathEmpty();
  }

  /// Parses the rule:
  /// URI-reference = URI / relative-ref
  bool uriReference() {
    return uri() || relativeRef();
  }

  /// Parses the rule:
  /// relative-ref = relative-part [ "?" query ] [ "#" fragment ]
  bool relativeRef() {
    final start = i;
    if (!relativePart()) {
      return false;
    }
    if (take('?') && !query()) {
      i = start;
      return false;
    }
    if (take('#') && !fragment()) {
      i = start;
      return false;
    }
    if (i != l) {
      i = start;
      return false;
    }
    return true;
  }

  /// Parses the rule:
  /// relative-part = "//" authority path-abempty
  ///               / path-absolute
  ///               / path-noscheme
  ///               / path-empty
  bool relativePart() {
    final start = i;
    if (take('/') && take('/') && authority() && pathAbempty()) {
      return true;
    }
    i = start;
    return pathAbsolute() || pathNoscheme() || pathEmpty();
  }

  /// Parses the rule:
  /// scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
  /// Terminated by ":".
  bool scheme() {
    final start = i;
    if (alpha()) {
      while (alpha() || digit() || take('+') || take('-') || take('.')) {
        // continue
      }
      if (i < l && str[i] == ':') {
        return true;
      }
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// authority = [ userinfo "@" ] host [ ":" port ]
  /// Lead by double slash ("") and terminated by "/", "?", "#", or end of URI.
  bool authority() {
    final start = i;
    if (userinfo()) {
      if (!take('@')) {
        i = start;
        return false;
      }
    }
    if (!host()) {
      i = start;
      return false;
    }
    if (take(':')) {
      if (!port()) {
        i = start;
        return false;
      }
    }
    if (!isAuthorityEnd()) {
      i = start;
      return false;
    }
    return true;
  }

  /// The authority component [...] is terminated by the next slash ("/"),
  /// question mark ("?"), or number sign ("#") character, or by the
  /// end of the URI.
  bool isAuthorityEnd() {
    return i >= l || str[i] == '?' || str[i] == '#' || str[i] == '/';
  }

  /// Parses the rule:
  /// userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
  /// Terminated by "@" in authority.
  bool userinfo() {
    final start = i;
    while (true) {
      if (unreserved() || pctEncoded() || subDelims() || take(':')) {
        continue;
      }
      if (i < l && str[i] == '@') {
        return true;
      }
      i = start;
      return false;
    }
  }

  /// Parses the rule:
  /// host = IP-literal / IPv4address / reg-name
  bool host() {
    final start = i;
    pctEncodedFound = false;
    // Note: IPv4address is a subset of reg-name
    if ((i < l && str[i] == '[' && ipLiteral()) || regName()) {
      if (pctEncodedFound) {
        final rawHost = str.substring(start, i);
        // RFC 3986:
        // URI producing applications must not use percent-encoding in host
        // unless it is used to represent a UTF-8 character sequence.
        try {
          // Uri.decodeComponent throws an error if a pct-encoded escape
          // sequence does not encode a valid UTF-8 character.
          Uri.decodeComponent(rawHost);
        } catch (_) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /// Parses the rule:
  /// port = *DIGIT
  /// Terminated by end of authority.
  bool port() {
    final start = i;
    while (true) {
      if (digit()) {
        continue;
      }
      if (isAuthorityEnd()) {
        return true;
      }
      i = start;
      return false;
    }
  }

  /// Parses the rule from RFC 6874:
  /// IP-literal = "[" ( IPv6address / IPv6addrz / IPvFuture  ) "]"
  bool ipLiteral() {
    final start = i;
    if (take('[')) {
      final j = i;
      if (ipv6Address() && take(']')) {
        return true;
      }
      i = j;
      if (ipv6addrz() && take(']')) {
        return true;
      }
      i = j;
      if (ipvFuture() && take(']')) {
        return true;
      }
    }
    i = start;
    return false;
  }

  /// Parses the rule "IPv6address".
  /// Relies on the implementation of isIp().
  bool ipv6Address() {
    final start = i;
    while (hexdig() || take(':')) {
      // continue
    }
    final addr = str.substring(start, i);
    if (isIp(addr, 6)) {
      return true;
    }
    i = start;
    return false;
  }

  /// Parses the rule from RFC 6874:
  /// IPv6addrz = IPv6address "%25" ZoneID
  bool ipv6addrz() {
    final start = i;
    if (ipv6Address() && take('%') && take('2') && take('5') && zoneId()) {
      return true;
    }
    i = start;
    return false;
  }

  /// Parses the rule from RFC 6874:
  /// ZoneID = 1*( unreserved / pct-encoded )
  bool zoneId() {
    final start = i;
    while (unreserved() || pctEncoded()) {
      // continue
    }
    if (i - start > 0) {
      return true;
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// IPvFuture  = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
  bool ipvFuture() {
    final start = i;
    if (take('v') && hexdig()) {
      while (hexdig()) {
        // continue
      }
      if (take('.')) {
        int j = 0;
        while (unreserved() || subDelims() || take(':')) {
          j++;
        }
        if (j >= 1) {
          return true;
        }
      }
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// reg-name = *( unreserved / pct-encoded / sub-delims )
  /// Terminates on start of port (":") or end of authority.
  bool regName() {
    final start = i;
    while (true) {
      if (unreserved() || pctEncoded() || subDelims()) {
        continue;
      }
      if (i < l && str[i] == ':') {
        return true;
      }
      if (isAuthorityEnd()) {
        // End of authority
        return true;
      }
      i = start;
      return false;
    }
  }

  /// The path is terminated by the first question mark ("?") or
  /// number sign ("#") character, or by the end of the URI.
  bool isPathEnd() {
    return i >= l || str[i] == '?' || str[i] == '#';
  }

  /// Parses the rule:
  /// path-abempty = *( "/" segment )
  /// Terminated by end of path: "?", "#", or end of URI.
  bool pathAbempty() {
    final start = i;
    while (take('/') && segment()) {
      // continue
    }
    if (isPathEnd()) {
      return true;
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// path-absolute = "/" [ segment-nz *( "/" segment ) ]
  /// Terminated by end of path: "?", "#", or end of URI.
  bool pathAbsolute() {
    final start = i;
    if (take('/')) {
      if (segmentNz()) {
        while (take('/') && segment()) {
          // continue
        }
      }
      if (isPathEnd()) {
        return true;
      }
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// path-noscheme = segment-nz-nc *( "/" segment )
  /// Terminated by end of path: "?", "#", or end of URI.
  bool pathNoscheme() {
    final start = i;
    if (segmentNzNc()) {
      while (take('/') && segment()) {
        // continue
      }
      if (isPathEnd()) {
        return true;
      }
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// path-rootless = segment-nz *( "/" segment )
  /// Terminated by end of path: "?", "#", or end of URI.
  bool pathRootless() {
    final start = i;
    if (segmentNz()) {
      while (take('/') && segment()) {
        // continue
      }
      if (isPathEnd()) {
        return true;
      }
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// path-empty = 0<pchar>
  /// Terminated by end of path: "?", "#", or end of URI.
  bool pathEmpty() {
    return isPathEnd();
  }

  /// Parses the rule:
  /// segment = *pchar
  bool segment() {
    while (pchar()) {
      // continue
    }
    return true;
  }

  /// Parses the rule:
  /// segment-nz = 1*pchar
  bool segmentNz() {
    final start = i;
    if (pchar()) {
      while (pchar()) {
        // continue
      }
      return true;
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
  ///               ; non-zero-length segment without any colon ":"
  bool segmentNzNc() {
    final start = i;
    while (unreserved() || pctEncoded() || subDelims() || take('@')) {
      // continue
    }
    if (i - start > 0) {
      return true;
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// pchar = unreserved / pct-encoded / sub-delims / ":" / "@"
  bool pchar() {
    return unreserved() ||
        pctEncoded() ||
        subDelims() ||
        take(':') ||
        take('@');
  }

  /// Parses the rule:
  /// query = *( pchar / "/" / "?" )
  /// Terminated by "#" or end of URI.
  bool query() {
    final start = i;
    while (true) {
      if (pchar() || take('/') || take('?')) {
        continue;
      }
      if (i == l || str[i] == '#') {
        return true;
      }
      i = start;
      return false;
    }
  }

  /// Parses the rule:
  /// fragment = *( pchar / "/" / "?" )
  /// Terminated by end of URI.
  bool fragment() {
    final start = i;
    while (true) {
      if (pchar() || take('/') || take('?')) {
        continue;
      }
      if (i == l) {
        return true;
      }
      i = start;
      return false;
    }
  }

  /// Parses the rule:
  /// pct-encoded = "%" HEXDIG HEXDIG
  /// Sets `pctEncodedFound` to true if a valid triplet was found
  bool pctEncoded() {
    final start = i;
    if (take('%') && hexdig() && hexdig()) {
      pctEncodedFound = true;
      return true;
    }
    i = start;
    return false;
  }

  /// Parses the rule:
  /// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
  bool unreserved() {
    return alpha() ||
        digit() ||
        take('-') ||
        take('_') ||
        take('.') ||
        take('~');
  }

  /// Parses the rule:
  /// sub-delims  = "!" / "$" / "&" / "'" / "(" / ")"
  ///             / "*" / "+" / "," / ";" / "="
  bool subDelims() {
    return take('!') ||
        take('\$') ||
        take('&') ||
        take("'") ||
        take('(') ||
        take(')') ||
        take('*') ||
        take('+') ||
        take(',') ||
        take(';') ||
        take('=');
  }

  /// Parses the rule:
  /// ALPHA =  %x41-5A / %x61-7A ; A-Z / a-z
  bool alpha() {
    if (i >= l) return false;
    final c = str[i];
    if (('A'.compareTo(c) <= 0 && c.compareTo('Z') <= 0) ||
        ('a'.compareTo(c) <= 0 && c.compareTo('z') <= 0)) {
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

  bool take(String char) {
    if (i < l && str[i] == char) {
      i++;
      return true;
    }
    return false;
  }

  /// Helper to check if a string is a valid IP address
  bool isIp(String str, int version) {
    if (version == 6) {
      return Ipv6Parser(str).address();
    }
    if (version == 4) {
      return Ipv4Parser(str).address();
    }
    return Ipv4Parser(str).address() || Ipv6Parser(str).address();
  }
}
