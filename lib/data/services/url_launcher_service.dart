import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  static const String _instagramUrl =
      'https://www.instagram.com/editions_akhira';
  static const String _facebookUrl = 'https://www.facebook.com/EditionsAkhira/';
  static const String _contactUrl = 'https://editionsakhira.com/contact/';

  /// Opens Instagram profile
  static Future<void> openInstagram() async {
    await _launchUrl(_instagramUrl);
  }

  /// Opens Facebook page
  static Future<void> openFacebook() async {
    await _launchUrl(_facebookUrl);
  }

  /// Opens contact page
  static Future<void> openContactPage() async {
    await _launchUrl(_contactUrl);
  }

  /// Generic method to launch any URL
  static Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      throw Exception('Failed to open URL: $e');
    }
  }

  /// Opens email with pre-filled subject and body
  static Future<void> openEmail({String? subject, String? body}) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not launch email');
      }
    } catch (e) {
      throw Exception('Failed to open email: $e');
    }
  }

  /// Opens phone dialer with number
  static Future<void> openPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw Exception('Could not launch phone');
      }
    } catch (e) {
      throw Exception('Failed to open phone: $e');
    }
  }
}
