import 'package:flutter/material.dart';
import '../../config/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Data Privacy Policy'),
                _divider(context),
                _sectionTitle(context, '1. Introduction'),
                _bodyText(context, 'Faminga is committed to safeguarding your privacy and the protection of your personal data. This Privacy Policy explains how we collect, use, disclose, and store your personal information and your rights under the Law N° 058/2021 of 13/10/2021 relating to the Protection of Personal Data and Privacy in Rwanda.'),
                _bodyText(context, 'By using our platform (www.faminga.app), you consent to the practices described in this Privacy Policy.'),
                _divider(context),
                _sectionTitle(context, '2. Definitions'),
                _bullets([
                  'Account: A unique profile created for you to access our services.',
                  'Company: Refers to Faminga, operated by Ihiga Ltd, located in Kigali, Rwanda.',
                  'Personal Data: Any information that identifies or can identify an individual.',
                  'Platform: The Faminga website or mobile application.',
                  'Service: Any functionality or service provided by Faminga.',
                  'Service Provider: A third party that processes personal data on behalf of the Company.',
                  'You / User: Any person accessing or using the Faminga platform.'
                ], context),
                _divider(context),
                _sectionTitle(context, '3. Data We Collect'),
                _bullets([
                  'Full name',
                  'Email address and phone number',
                  'Identification information (e.g., national ID, if required)',
                  'Contact details and address',
                  'Location-related information',
                  'Service usage data (e.g., activity logs)',
                  'We only collect the data necessary to deliver and improve our services, in accordance with your consent or legal requirements.'
                ], context),
                _divider(context),
                _sectionTitle(context, '4. How We Collect Your Data'),
                _bodyText(context, 'We collect data directly from you when you:'),
                _bullets([
                  'Create or manage your account',
                  'Submit requests or forms',
                  'Contact us for support or feedback',
                  'Use any part of our services',
                  'We may also collect data indirectly where permitted by law and with your prior consent.'
                ], context),
                _divider(context),
                _sectionTitle(context, '5. Purpose of Data Collection'),
                _bullets([
                  'To provide and manage our services',
                  'To authenticate your identity and manage your account',
                  'To respond to your inquiries and requests',
                  'To notify you about updates or changes to services',
                  'To fulfill legal and regulatory obligations',
                  'To improve user experience through analytics and feedback'
                ], context),
                _divider(context),
                _sectionTitle(context, '6. Sharing of Data'),
                _bodyText(context, 'We may share your personal data:'),
                _bullets([
                  'With authorized service providers who support our operations',
                  'With regulatory or legal authorities when required by law',
                  'With third parties, only with your consent or legal basis',
                  'In the event of a merger, sale, or reorganization of our company',
                  'We do not sell your data to third parties under any circumstance.'
                ], context),
                _divider(context),
                _sectionTitle(context, '7. International Data Transfers'),
                _bodyText(context, "Where data needs to be transferred to service providers located outside Rwanda, we ensure that appropriate safeguards are in place to protect your data and comply with the law. You will be notified before any such transfer takes place, in compliance with Rwanda's data protection laws."),
                _divider(context),
                _sectionTitle(context, '8. Data Retention'),
                _bullets([
                  'We retain your personal data only as long as necessary to:',
                  'Fulfill the purposes for which it was collected',
                  'Comply with legal, accounting, or regulatory requirements',
                  'Resolve disputes and enforce our agreements',
                  'When data is no longer needed, it will be securely deleted or anonymized in line with best practices.'
                ], context),
                _divider(context),
                _sectionTitle(context, '9. Your Rights'),
                _bullets([
                  'Right to access: You can request a copy of the data we hold about you.',
                  'Right to correct: You may ask us to update or correct any inaccurate data.',
                  'Right to delete: You can request deletion of your personal data, subject to legal requirements.',
                  'Right to object: You may object to the processing of your data under certain circumstances.',
                  'Right to withdraw consent: Where we process data based on your consent, you may withdraw it at any time.',
                  'Right to data portability: You can request a copy of your data in a commonly used format.',
                  'To exercise any of these rights, please contact us at: support@faminga.app'
                ], context),
                _divider(context),
                _sectionTitle(context, '10. Children\'s Privacy'),
                _bodyText(context, 'Our platform is not designed for use by individuals under the age of 18 without parental or guardian consent. We do not knowingly collect personal data from children. If we become aware that we have unknowingly collected data from a child, we will take steps to delete such data promptly.'),
                _divider(context),
                _sectionTitle(context, '11. Security of Personal Data'),
                _bullets([
                  'Faminga takes security seriously and employs robust security measures to protect your personal data from unauthorized access, alteration, disclosure, or destruction. These include:',
                  'Encryption of sensitive data',
                  'Secure access controls and authentication mechanisms',
                  'Regular security audits and vulnerability testing',
                  'However, please note that no method of data transmission over the internet or electronic storage is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.'
                ], context),
                _divider(context),
                _sectionTitle(context, '12. Use of Cookies'),
                _bullets([
                  'Faminga may use cookies and similar tracking technologies to:',
                  'Enhance platform performance and user experience',
                  'Provide personalized content and recommendations',
                  'Gather analytics and usage insights',
                  'You can manage or disable cookies in your browser settings. However, blocking certain cookies may impact your ability to use the full functionality of our platform.'
                ], context),
                _divider(context),
                _sectionTitle(context, '13. Changes to This Policy'),
                _bodyText(context, 'We may update this Privacy Policy from time to time to reflect changes to our practices or for legal, operational, or regulatory requirements. Significant changes will be communicated to you via email, in-app notifications, or by placing a prominent notice on our platform. Continued use of the platform constitutes acceptance of the updated Privacy Policy.'),
                _divider(context),
                _sectionTitle(context, '14. Contact Information'),
                _bodyText(context, 'If you have questions about this Privacy Policy or would like to exercise your data privacy rights, please contact us at:'),
                _bodyText(context, 'Faminga (Ihiga Ltd.)'),
                _bodyText(context, 'Address: KK 104 St, Nyarugunga, Kicukiro, Kigali, Rwanda'),
                _bodyText(context, 'Email: info@faminga.app | support@faminga.app'),
                _bodyText(context, 'Phone: +250 796 882 585'),
                _bodyText(context, 'Business Hours: Mon-Fri 8:00-17:00, Sat 9:00-13:00 (GMT+2)'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: FamingaBrandColors.primaryOrange,
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: Theme.of(context).dividerColor, thickness: 1),
    );
  }

  Widget _bodyText(BuildContext context, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        body,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface, height: 1.5),
      ),
    );
  }

  Widget _bullets(List<String> items, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface, height: 1.5),
                        ),
                      )
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
