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
import '../../../providers/account_provider.dart';

/// Utility to generate and print transactions PDF for an account.
class PrintTransactions {
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');

  static Future<void> printTransactions(
    BuildContext context,
    Map<String, dynamic> account, {
    List<Map<String, dynamic>>? transactions,
  }) async {
    // Fetch app info and account data - MAKE SURE it's loaded before proceeding
    final infoProvider = Provider.of<InfoProvider>(context, listen: false);
    await infoProvider.loadInfo(); // Explicitly wait for info to load
    final info = infoProvider.info;

    final accountProvider =
        Provider.of<AccountProvider>(context, listen: false);
    final accountId = account['id'];

    // Get latest account data from provider if available
    final latestAccount = accountProvider.getAccount(accountId) ?? account;
    final accountName = latestAccount['name'] ?? '';
    final balances = (latestAccount['balances'] as Map<String, dynamic>?) ?? {};

    // Use passed-in transactions, or fetch all if null
    final txs = transactions ??
        await AccountDBHelper().getTransactionsForPrint(accountId);

    final String companyName = info.name ?? '';
    final String companyAddress = info.address ?? '';
    final String companyPhone = info.whatsApp ?? '';

    final now = DateTime.now();
    final printTimestamp = formatLocalizedDateTime(context, now.toString());

    // Determine text direction based on locale
    final localeCode = Localizations.localeOf(context).languageCode;
    final isRTL = localeCode != 'en';
    final pdfDir = isRTL ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    // Load custom fonts
    final fontDataRegular =
        await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
    final fontDataBold =
        await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
    final vazirFontRegular = pw.Font.ttf(fontDataRegular);
    final vazirFontBold = pw.Font.ttf(fontDataBold);

    // Create PDF document with theme
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
        textDirection: pdfDir,
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
        ),
        build: (pdfContext) {
          final List<pw.Widget> content = [];

          // --- BALANCES TABLE ---
          if (balances.isNotEmpty) {
            final balanceHeaders = [
              loc.currency,
              loc.credit,
              loc.debit,
              loc.balance,
            ];
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

            final headersToUse =
                isRTL ? balanceHeaders.reversed.toList() : balanceHeaders;
            final dataToUse = isRTL
                ? balanceRows.map((r) => r.reversed.toList()).toList()
                : balanceRows;

            content.add(
              pw.Text(
                loc.balance,
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            );
            content.add(pw.SizedBox(height: 4));
            content.add(
              pw.Directionality(
                textDirection: pdfDir,
                child: pw.TableHelper.fromTextArray(
                  headers: headersToUse,
                  data: dataToUse,
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

          // --- TRANSACTIONS TABLE ---
          final txHeaders = [
            loc.number,
            loc.date,
            loc.description,
            loc.debit,
            loc.credit,
            loc.balance,
          ];
          final txRows = List.generate(txs.length, (i) {
            final tx = txs[i];
            final isCredit = tx['transaction_type'] == 'credit';
            return [
              '${i + 1}',
              formatLocalizedDate(context, tx['date']),
              tx['description'] ?? '',
              isCredit ? '' : _amountFormatter.format(tx['amount']),
              isCredit ? _amountFormatter.format(tx['amount']) : '',
              '${_amountFormatter.format(tx['balance'])} ${tx['currency']}',
            ];
          });

          final headersToUseTx =
              isRTL ? txHeaders.reversed.toList() : txHeaders;
          final dataToUseTx =
              isRTL ? txRows.map((r) => r.reversed.toList()).toList() : txRows;

          final descIndex = headersToUseTx.indexOf(loc.description);

          content.add(
            pw.Text(
              loc.transactions,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          );
          content.add(pw.SizedBox(height: 4));
          content.add(
            pw.Directionality(
              textDirection: pdfDir,
              child: pw.TableHelper.fromTextArray(
                headers: headersToUseTx,
                data: dataToUseTx,
                columnWidths: {
                  descIndex: pw.FlexColumnWidth(2),
                  for (var i = 0; i < headersToUseTx.length; i++)
                    if (i != descIndex) i: pw.IntrinsicColumnWidth(),
                },
                headerStyle:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(fontSize: 10),
                cellAlignments: isRTL
                    ? {
                        headersToUseTx.indexOf(loc.number): pw.Alignment.center,
                        headersToUseTx.indexOf(loc.description):
                            pw.Alignment.centerRight,
                      }
                    : {
                        headersToUseTx.indexOf(loc.number): pw.Alignment.center,
                        headersToUseTx.indexOf(loc.description):
                            pw.Alignment.centerLeft,
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

    // Render the PDF
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
