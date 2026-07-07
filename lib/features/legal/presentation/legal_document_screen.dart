import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/strings/app_strings.dart';

enum LegalDocument { terms, privacy }

extension LegalDocumentX on LegalDocument {
  String get assetPath => switch (this) {
        LegalDocument.terms => 'assets/legal/terms.txt',
        LegalDocument.privacy => 'assets/legal/privacy.txt',
      };

  String get title => switch (this) {
        LegalDocument.terms => AppStrings.termsOfService,
        LegalDocument.privacy => AppStrings.privacyPolicy,
      };
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(document.assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              snapshot.data ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          );
        },
      ),
    );
  }
}
