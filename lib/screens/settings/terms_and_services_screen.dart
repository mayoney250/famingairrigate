import 'package:flutter/material.dart';
import '../../config/colors.dart';

class TermsAndServicesScreen extends StatelessWidget {
  const TermsAndServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Terms and Services')),
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
                _sectionTitle(context, 'Terms of Service Agreement'),
                _divider(context),
                _sectionTitle(context, 'Acceptance of Terms'),
                _bodyText(context, 'By accessing and using the Faminga platform, you confirm that you accept these Terms of Service and agree to comply with them. If you do not agree to these terms, you must not use our platform.'),
                _divider(context),
                _sectionTitle(context, 'User Account and Responsibilities'),
                _bodyText(context, 'To access certain features of our platform, you may be required to create an account. You are responsible for:'),
                _bullets([
                  'Providing accurate and up-to-date information during registration',
                  'Maintaining the confidentiality of your account credentials',
                  'All activities that occur under your account',
                  'Notifying us immediately of any unauthorized access or security breach',
                  'You agree not to share your account credentials with others. Faminga is not liable for any loss or damage arising from your failure to protect your account information.'
                ], context),
                _divider(context),
                _sectionTitle(context, 'Prohibited Conduct'),
                _bodyText(context, 'You agree not to:'),
                _bullets([
                  'Use the platform for any illegal or unauthorized purpose',
                  'Attempt to interfere with, disrupt, or harm the platform or its servers',
                  'Use automated scripts, bots, or other tools to access the platform without authorization',
                  'Upload or transmit viruses, malware, or any other harmful code',
                  'Violate the intellectual property rights of Faminga or third parties',
                  'Impersonate another person or entity',
                  'Violation of these terms may result in immediate suspension or termination of your account.'
                ], context),
                _divider(context),
                _sectionTitle(context, 'Intellectual Property Rights'),
                _bodyText(context, 'All content on the Faminga platform, including text, graphics, logos, images, software, and trademarks, is the property of Faminga (Ihiga Ltd.) or its licensors and is protected by copyright, trademark, and other intellectual property laws.'),
                _bodyText(context, 'You may not reproduce, distribute, modify, or create derivative works from any content on the platform without our prior written consent.'),
                _divider(context),
                _sectionTitle(context, 'Payment Terms'),
                _bodyText(context, 'Certain features or services on the Faminga platform may require payment. By subscribing to or purchasing such services, you agree to:'),
                _bullets([
                  'Provide accurate and complete payment information',
                  'Pay all applicable fees, including taxes, as specified at the time of purchase',
                  'Authorize us to charge your chosen payment method',
                  'Faminga does not guarantee the operation or availability of these external payment systems and expressly disclaims any liability related to technical failures, unauthorized access, or disruptions that may occur during payment processing.',
                  'You agree that the payment information you provide is accurate and that you are authorized to use the payment method. Faminga does not store sensitive payment credentials, such as PINs or passwords, unless explicitly authorized by the user.'
                ], context),
                _divider(context),
                _sectionTitle(context, 'Refund Policy'),
                _bodyText(context, 'If a user submits a valid refund request in accordance with applicable law and Faminga policies, the company will initiate a refund process without unnecessary delay.'),
                _bodyText(context, "To the extent permitted by law, Faminga's total liability—whether contractual or otherwise—shall not exceed the amount paid by the user for the relevant service, or, at Faminga's discretion, the re-provision of the service."),
                _divider(context),
                _sectionTitle(context, 'Third Parties and Affiliates'),
                _bodyText(context, 'Faminga may use third-party providers or affiliates to deliver specific features or services (e.g., service agents, agricultural extension partners, payment processors). These parties are governed by their own terms of service.'),
                _bodyText(context, 'Faminga is not liable for any damages, direct or indirect, resulting from the acts or omissions of these third parties. There are no hidden charges outside the fees published on the Platform, and users are not required to pay any additional amounts to agents or intermediaries.'),
                _divider(context),
                _sectionTitle(context, 'Virus Protection and Cybersecurity'),
                _bodyText(context, 'Faminga implements security protocols and conducts periodic reviews to protect users from malware, cyber threats, and data breaches.'),
                _bodyText(context, 'However, users are strongly encouraged to run antivirus programs and take standard security precautions when accessing the Platform. Faminga is not responsible for any loss, damage, or disruption to data or devices resulting from access to or downloads from the Platform or linked websites.'),
                _divider(context),
                _sectionTitle(context, 'Governing Law'),
                _bodyText(context, 'These Terms of Service and all related terms are governed by the laws of the Republic of Rwanda. Any disputes arising from or related to the use of this Platform shall be subject to the exclusive jurisdiction of competent courts in Rwanda.'),
                _divider(context),
                _sectionTitle(context, 'Changes to These Terms'),
                _bodyText(context, 'We may update these Terms of Service from time to time to reflect changes to our practices or for legal, operational, or regulatory requirements. Significant changes will be communicated to you via email, in-app notifications, or by placing a prominent notice on our platform. Continued use of the platform constitutes acceptance of the updated Terms.'),
                _divider(context),
                _sectionTitle(context, 'Contact Information'),
                _bodyText(context, 'If you have questions about these Terms of Service, please contact us at:'),
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
