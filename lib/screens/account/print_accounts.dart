import 'package:BusinessHub/utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../providers/info_provider.dart';
import '../../../utils/date_formatters.dart';
import '../../../utils/transaction_helper.dart';

/// Friendly PDF report printer for filtered accounts with balances.
class PrintAccounts {
  static final _formatter = NumberFormat('#,###.##');

  static final Future<pw.ThemeData> _pdfTheme = _loadPdfTheme();
  static Future<pw.ThemeData> _loadPdfTheme() async {
    final regular = await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
    return pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  }

  /// Prints a PDF report: account info and a subtable of balances.
  static Future<void> printAccounts(
    BuildContext context,
    List<Map<String, dynamic>> accounts,
  ) async {
    final info = Provider.of<InfoProvider>(context, listen: false).info;
    final loc = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode != 'en';
    final theme = await _pdfTheme;
    final pdf = pw.Document(theme: theme);
    final timestamp =
        formatLocalizedDateTime(context, DateTime.now().toString());

    // Styles
    final titleStyle =
        pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final headerStyle =
        pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);
    final captionStyle =
        pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
    final tableHeader =
        pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final tableCell = pw.TextStyle(fontSize: 9);
    final borderSide = pw.BorderSide(color: PdfColors.grey300, width: 0.5);
    final pageMargin = pw.EdgeInsets.all(24);

    pdf.addPage(
      pw.MultiPage(
        margin: pageMargin,
        pageFormat: PdfPageFormat.a4,
        textDirection: isRTL ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(info.name ?? '', style: headerStyle),
                pw.Text(loc.printed(timestamp), style: tableCell),
              ],
            ),
            pw.Text(info.address ?? '', style: tableCell),
            pw.Text(info.whatsApp ?? '', style: tableCell),
            pw.Divider(thickness: borderSide.width, color: PdfColors.grey300),
            pw.Center(child: pw.Text(loc.accountsPrint, style: titleStyle)),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(loc.pageOf(ctx.pageNumber, ctx.pagesCount),
              style: tableCell),
        ),
        build: (ctx) => accounts.map((acct) {
          final balances = aggregateTransactions(acct['account_details']);

          // Define base headers and data order
          final ltrHeaders = [loc.currency, loc.credit, loc.debit, loc.balance];
          final rtlHeaders = List.from(ltrHeaders.reversed);
          final subTableHeaders = isRTL ? rtlHeaders : ltrHeaders;

          // Prepare base data rows
          final ltrData = balances.entries.map((e) {
            final detail = e.value;
            final summary = detail['summary'] as Map<String, dynamic>? ?? {};
            final currency = detail['currency']?.toString() ?? e.key;
            final credit = _formatter.format(summary['credit'] ?? 0);
            final debit = _formatter.format(summary['debit'] ?? 0);
            final balanceVal = _formatter.format(summary['balance'] ?? 0);
            return [currency, credit, debit, balanceVal];
          }).toList();
          final subTableData = isRTL
              ? ltrData.map((row) => row.reversed.toList()).toList()
              : ltrData;

          return pw.Container(
            margin: pw.EdgeInsets.symmetric(vertical: 8),
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Account row
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                              getLocalizedSystemAccountName(
                                  context, acct['name']),
                              style: captionStyle)),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                              getLocalizedAccountType(
                                  context, acct['account_type']),
                              style: tableCell)),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text(acct['phone']?.toString() ?? '',
                              style: tableCell)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
                // Balances sub table
                pw.TableHelper.fromTextArray(
                  headers: subTableHeaders,
                  data: subTableData,
                  headerStyle: tableHeader,
                  cellStyle: tableCell,
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
                  border: pw.TableBorder.all(
                      color: borderSide.color, width: borderSide.width),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.centerRight,
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
