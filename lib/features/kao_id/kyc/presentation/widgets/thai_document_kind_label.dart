import 'package:kaosure/l10n/app_localizations.dart';

import '../../domain/entities/thai_document_kind.dart';

String thaiDocumentKindLabel(AppLocalizations l, ThaiDocumentKind kind) => switch (kind) {
      ThaiDocumentKind.workPermit => l.thaiDocWorkPermit,
      ThaiDocumentKind.residenceCertificate => l.thaiDocResidenceCertificate,
      ThaiDocumentKind.pinkCard => l.thaiDocPinkCard,
      ThaiDocumentKind.houseRegistrationTr13 => l.thaiDocTr13,
    };
