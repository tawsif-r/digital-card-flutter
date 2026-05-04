import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../features/cards/domain/card_data.dart';

String buildVCard(CardData d) {
  final lines = [
    'BEGIN:VCARD',
    'VERSION:3.0',
    if (d.name.isNotEmpty) 'FN:${d.name}',
    if (d.title != null) 'TITLE:${d.title}',
    if (d.company != null) 'ORG:${d.company}',
    if (d.phone != null) 'TEL:${d.phone}',
    if (d.email != null) 'EMAIL:${d.email}',
    if (d.website != null) 'URL:${d.website}',
    'END:VCARD',
  ];
  return lines.join('\r\n');
}

Future<File> writeVcfTemp(CardData data) async {
  final dir = await getTemporaryDirectory();
  final safeName = data.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  final file = File('${dir.path}/$safeName.vcf');
  await file.writeAsString(buildVCard(data));
  return file;
}
