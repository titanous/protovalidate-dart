import 'package:test/test.dart';
import '../lib/src/parsers/ipv4_parser.dart';
import '../lib/src/parsers/ipv6_parser.dart';
import '../lib/src/parsers/uri_parser.dart';
import '../lib/src/shared/string_validators.dart';

void main() {
  group('IPv4 Parser', () {
    test('valid addresses', () {
      expect(Ipv4Parser('192.168.1.1').address(), isTrue);
      expect(Ipv4Parser('10.0.0.1').address(), isTrue);
      expect(Ipv4Parser('255.255.255.255').address(), isTrue);
      expect(Ipv4Parser('0.0.0.0').address(), isTrue);
    });

    test('invalid addresses', () {
      expect(Ipv4Parser('256.1.1.1').address(), isFalse);
      expect(Ipv4Parser('1.1.1').address(), isFalse);
      expect(Ipv4Parser('1.1.1.1.1').address(), isFalse);
      expect(Ipv4Parser('01.1.1.1').address(), isFalse); // no leading zeros
    });

    test('with prefix', () {
      expect(Ipv4Parser('192.168.1.0/24').addressPrefix(), isTrue);
      expect(Ipv4Parser('10.0.0.0/8').addressPrefix(), isTrue);
      expect(Ipv4Parser('192.168.1.0/33').addressPrefix(), isFalse); // invalid prefix
    });

    test('strict prefix (host bits must be zero)', () {
      final parser1 = Ipv4Parser('192.168.1.0/24');
      expect(parser1.addressPrefix(), isTrue);
      expect(parser1.isPrefixOnly(), isTrue);

      final parser2 = Ipv4Parser('192.168.1.1/24');
      expect(parser2.addressPrefix(), isTrue);
      expect(parser2.isPrefixOnly(), isFalse); // host bits are not zero
    });
  });

  group('IPv6 Parser', () {
    test('valid addresses', () {
      expect(Ipv6Parser('::1').address(), isTrue);
      expect(Ipv6Parser('::').address(), isTrue);
      expect(Ipv6Parser('2001:db8::1').address(), isTrue);
      expect(Ipv6Parser('fe80::1%eth0').address(), isTrue); // with zone id
      expect(Ipv6Parser('2001:db8:85a3::8a2e:370:7334').address(), isTrue);
    });

    test('invalid addresses', () {
      expect(Ipv6Parser(':::').address(), isFalse);
      expect(Ipv6Parser('2001:db8:::1').address(), isFalse); // double :: twice
      expect(Ipv6Parser('gggg::1').address(), isFalse); // invalid hex
    });

    test('with embedded IPv4', () {
      expect(Ipv6Parser('::ffff:192.168.1.1').address(), isTrue);
      expect(Ipv6Parser('64:ff9b::192.0.2.1').address(), isTrue);
    });

    test('with prefix', () {
      expect(Ipv6Parser('2001:db8::/32').addressPrefix(), isTrue);
      expect(Ipv6Parser('fe80::/10').addressPrefix(), isTrue);
      expect(Ipv6Parser('2001:db8::/129').addressPrefix(), isFalse); // invalid prefix
    });
  });

  group('URI Parser', () {
    test('valid URIs', () {
      expect(UriParser('https://example.com').uri(), isTrue);
      expect(UriParser('http://example.com:8080/path').uri(), isTrue);
      expect(UriParser('ftp://user@host.com').uri(), isTrue);
      expect(UriParser('mailto:test@example.com').uri(), isTrue);
    });

    test('invalid URIs', () {
      expect(UriParser('://example.com').uri(), isFalse); // no scheme
      expect(UriParser('http://').uri(), isFalse); // no host
      expect(UriParser('../relative').uri(), isFalse); // relative path
    });

    test('URI references', () {
      expect(UriParser('./relative').uriReference(), isTrue);
      expect(UriParser('../parent').uriReference(), isTrue);
      expect(UriParser('//example.com/path').uriReference(), isTrue);
      expect(UriParser('#fragment').uriReference(), isTrue);
    });
  });

  group('String Validators Integration', () {
    test('email validation', () {
      expect(StringValidators.isEmail('test@example.com'), isTrue);
      expect(StringValidators.isEmail('user+tag@domain.org'), isTrue);
      expect(StringValidators.isEmail('invalid@'), isFalse);
      expect(StringValidators.isEmail('@invalid.com'), isFalse);
    });

    test('hostname validation', () {
      expect(StringValidators.isHostname('example.com'), isTrue);
      expect(StringValidators.isHostname('sub.domain.example.com'), isTrue);
      expect(StringValidators.isHostname('localhost'), isTrue);
      expect(StringValidators.isHostname('-invalid.com'), isFalse);
      expect(StringValidators.isHostname('invalid-.com'), isFalse);
    });

    test('IP validation with version', () {
      expect(StringValidators.isIp('192.168.1.1', 4), isTrue);
      expect(StringValidators.isIp('192.168.1.1', 6), isFalse);
      expect(StringValidators.isIp('::1', 6), isTrue);
      expect(StringValidators.isIp('::1', 4), isFalse);
      expect(StringValidators.isIp('192.168.1.1'), isTrue); // any version
      expect(StringValidators.isIp('::1'), isTrue); // any version
    });

    test('IP prefix validation', () {
      expect(StringValidators.isIpPrefix('192.168.1.0/24'), isTrue);
      expect(StringValidators.isIpPrefix('2001:db8::/32'), isTrue);
      expect(StringValidators.isIpPrefix('192.168.1.1/24', null, true), isFalse); // strict mode
      expect(StringValidators.isIpPrefix('192.168.1.0/24', null, true), isTrue); // strict mode
    });
  });
}