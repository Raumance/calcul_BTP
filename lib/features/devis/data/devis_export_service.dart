import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:calcul_projet/features/devis/domain/models/devis.dart';
import 'package:calcul_projet/features/projet/presentation/providers/app_session_provider.dart';

enum ExportFormat { pdf, excel, csv }

class DevisExportService {
  Future<File> exporter({
    required DevisModel devis,
    required ProjetModel? projet,
    required ExportFormat format,
  }) async {
    return switch (format) {
      ExportFormat.pdf => _pdf(devis, projet),
      ExportFormat.excel => _excel(devis, projet),
      ExportFormat.csv => _csv(devis, projet),
    };
  }

  Future<void> exporterEtPartager({
    required DevisModel devis,
    required ProjetModel? projet,
    required ExportFormat format,
  }) async {
    final file = await exporter(devis: devis, projet: projet, format: format);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: devis.intitule,
      text: 'Devis ${devis.intitule} — Calculs BTP',
    );
  }

  Future<Directory> _dir() async => getTemporaryDirectory();

  Future<File> _pdf(DevisModel devis, ProjetModel? projet) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text(
            devis.intitule,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (projet != null)
            pw.Text('Chantier : ${projet.nom} — ${projet.client}'),
          pw.Text(
            'Date : ${devis.dateDevis.toIso8601String().substring(0, 10)}'
            ' · Devise : ${devis.deviseCode}',
          ),
          pw.SizedBox(height: 16),
          for (final phase in phasesOrdre)
            if (devis.lignesParPhase.containsKey(phase)) ...[
              pw.Text(
                libellePhase(phase),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headers: const ['Désignation', 'Qté', 'Unité', 'P.U.', 'Total'],
                data: [
                  for (final l in devis.lignesParPhase[phase]!)
                    [
                      l.designation,
                      l.quantite.toStringAsFixed(2),
                      l.unite,
                      l.prixUnitaire.toStringAsFixed(0),
                      l.total.toStringAsFixed(0),
                    ],
                ],
              ),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Sous-total : '
                  '${devis.sousTotauxParPhase[phase]!.toStringAsFixed(0)} '
                  '${devis.deviseCode}',
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          pw.Divider(),
          pw.Text(
            'Total : ${devis.totalGeneral.toStringAsFixed(0)} ${devis.deviseCode}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Résultats indicatifs — ne constituent pas un dimensionnement '
            'structurel. Vérification par un professionnel compétent requise.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
    final file = File(
      p.join((await _dir()).path, 'devis_${devis.id}.pdf'),
    );
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<File> _excel(DevisModel devis, ProjetModel? projet) async {
    final book = Excel.createExcel();
    final sheet = book['Devis'];
    sheet.appendRow([
      TextCellValue(devis.intitule),
      TextCellValue(projet?.nom ?? ''),
      TextCellValue(devis.deviseCode),
    ]);
    sheet.appendRow([
      TextCellValue('Phase'),
      TextCellValue('Désignation'),
      TextCellValue('Quantité'),
      TextCellValue('Unité'),
      TextCellValue('P.U.'),
      TextCellValue('Total'),
    ]);
    for (final l in devis.lignes) {
      sheet.appendRow([
        TextCellValue(libellePhase(l.phase)),
        TextCellValue(l.designation),
        DoubleCellValue(l.quantite),
        TextCellValue(l.unite),
        DoubleCellValue(l.prixUnitaire),
        DoubleCellValue(l.total),
      ]);
    }
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(devis.totalGeneral),
    ]);
    final bytes = book.encode();
    if (bytes == null) {
      throw StateError('Échec génération Excel.');
    }
    final file = File(
      p.join((await _dir()).path, 'devis_${devis.id}.xlsx'),
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> _csv(DevisModel devis, ProjetModel? projet) async {
    final buf = StringBuffer();
    buf.writeln('phase;designation;quantite;unite;prix_unitaire;total;devise');
    for (final l in devis.lignes) {
      buf.writeln(
        '${libellePhase(l.phase)};${l.designation};${l.quantite};'
        '${l.unite};${l.prixUnitaire};${l.total};${devis.deviseCode}',
      );
    }
    buf.writeln('TOTAL;;;;;${devis.totalGeneral};${devis.deviseCode}');
    final file = File(
      p.join((await _dir()).path, 'devis_${devis.id}.csv'),
    );
    await file.writeAsString(buf.toString());
    return file;
  }
}
