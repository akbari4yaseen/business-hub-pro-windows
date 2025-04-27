import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../database/account_db.dart';
import '../../../utils/date_formatters.dart';
import '../../../providers/info_provider.dart';

/// Utility to generate and print transactions PDF for an account.
class PrintTransactions {
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');

  /// Generates a PDF of all transactions for the given [account] and
  /// invokes the print/layout dialog.
  static Future<void> printTransactions(
    BuildContext context,
    Map<String, dynamic> account,
  ) async {
    final info = Provider.of<InfoProvider>(context, listen: false).info;
    final accountId = account['id'];
    final accountName = account['name'] ?? '';
    final balances = (account['balances'] as Map<String, dynamic>?) ?? {};
    final txs = await AccountDBHelper().getTransactionsForPrint(accountId);

    final String companyName = info.name ?? '';
    final String companyAddress = info.address ?? '';
    final String companyPhone = info.whatsApp ?? '';

    final now = DateTime.now();
    final printTimestamp = formatLocalizedDateTime(context, now.toString());

    final fontDataRegular =
        await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
    final fontDataBold =
        await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
    final vazirFontRegular = pw.Font.ttf(fontDataRegular);
    final vazirFontBold = pw.Font.ttf(fontDataBold);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: vazirFontRegular,
        bold: vazirFontBold,
      ),
    );

    final loc = AppLocalizations.of(context)!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        header: (pdfContext) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '${loc.printed(printTimestamp)}',
                  style: pw.TextStyle(fontSize: 9),
                ),
                // Add 'printed' key to your ARB: "printed": "Printed: {date}"
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(companyAddress, style: pw.TextStyle(fontSize: 9)),
                pw.Text(companyPhone, style: pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.Divider(thickness: 1, height: 12),
            pw.Center(
              child: pw.Text(
                accountName,
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (pdfContext) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            loc.pageOf(pdfContext.pageNumber, pdfContext.pagesCount),
            style: pw.TextStyle(fontSize: 10),
          ),
          // Add 'pageOf' key to your ARB: "pageOf": "Page {page} of {total}"
        ),
        build: (pdfContext) {
          final List<pw.Widget> content = [];

          if (balances.isNotEmpty) {
            final balanceHeaders = [
              loc.currency,
              loc.credit,
              loc.debit,
              loc.balance,
            ];
            // Add keys: currency, credit, debit, balance
            final balanceRows = balances.entries.map((e) {
              final data = e.value as Map<String, dynamic>;
              final summary = (data['summary'] as Map<String, dynamic>?) ?? {};
              return [
                data['currency'] ?? e.key,
                _amountFormatter.format(summary['credit'] ?? 0),
                _amountFormatter.format(summary['debit'] ?? 0),
                _amountFormatter.format(summary['balance'] ?? 0),
              ];
            }).toList();

            final rtlHeaders = balanceHeaders.reversed.toList();
            final rtlData =
                balanceRows.map((r) => r.reversed.toList()).toList();

            content.add(pw.Text(
              loc.balance,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ));
            // Add key: accountBalances
            content.add(pw.SizedBox(height: 4));
            content.add(
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.TableHelper.fromTextArray(
                  headers: rtlHeaders,
                  data: rtlData,
                  headerStyle: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(fontSize: 10),
                  headerDecoration:
                      pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0E0E0)),
                  border:
                      pw.TableBorder.all(color: PdfColor.fromInt(0xFFBDBDBD)),
                ),
              ),
            );
            content.add(pw.SizedBox(height: 12));
          }

          final txHeaders = [
            loc.no,
            loc.date,
            loc.description,
            loc.debit,
            loc.credit,
            loc.balance,
          ];
          // Add keys: no, date, description, debit, credit, balance
          final txRows = List.generate(txs.length, (i) {
            final tx = txs[i];
            final isCredit = tx['transaction_type'] == 'credit';
            return [
              '${i + 1}',
              formatLocalizedDate(context, tx['date']),
              tx['description'] ?? '',
              isCredit ? '' : _amountFormatter.format(tx['amount']),
              isCredit ? _amountFormatter.format(tx['amount']) : '',
              _amountFormatter.format(tx['balance']),
            ];
          });

          final rtlTxHeaders = txHeaders.reversed.toList();
          final rtlTxRows = txRows.map((r) => r.reversed.toList()).toList();

          final descIndex = rtlTxHeaders.indexOf(loc.description);

          content.add(pw.Text(
            loc.transactions,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ));
          // Add key: transactions
          content.add(pw.SizedBox(height: 4));
          content.add(
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.TableHelper.fromTextArray(
                headers: rtlTxHeaders,
                data: rtlTxRows,
                columnWidths: {
                  descIndex: pw.FlexColumnWidth(2),
                  for (var i = 0; i < rtlTxHeaders.length; i++)
                    if (i != descIndex) i: pw.IntrinsicColumnWidth(),
                },
                headerStyle:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(fontSize: 10),
                cellAlignments: {
                  rtlTxHeaders.indexOf(loc.no): pw.Alignment.center,
                  rtlTxHeaders.indexOf(loc.description):
                      pw.Alignment.centerRight,
                },
                headerDecoration:
                    pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0E0E0)),
                border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFBDBDBD)),
              ),
            ),
          );

          return content;
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
