import 'package:pdf/pdf.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../utils/date_formatters.dart';
import '../../models/invoice.dart';
import '../../providers/info_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/account_provider.dart';

final _currencyFormat = NumberFormat('#,###.##');

Future<void> printInvoice({
  required BuildContext context,
  required Invoice invoice,
  required InfoProvider infoProvider,
  required InventoryProvider inventoryProvider,
  required AccountProvider accountProvider,
}) async {
  await infoProvider.loadInfo();
  final info = infoProvider.info;

  final customer = accountProvider.accounts.firstWhere(
    (c) => c['id'] == invoice.accountId,
    orElse: () => <String, dynamic>{'name': 'Unknown Customer'},
  );
  final customerName = customer['name'];
  final currentDateTime = DateTime.now();

  final loc = AppLocalizations.of(context)!;
  final localeCode = Localizations.localeOf(context).languageCode;
  final isRTL = localeCode != 'en';
  final pdfDir = isRTL ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  // Load custom fonts
  final fontDataRegular =
      await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
  final fontDataBold = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
  final vazirFontRegular = pw.Font.ttf(fontDataRegular);
  final vazirFontBold = pw.Font.ttf(fontDataBold);

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(
      base: vazirFontRegular,
      bold: vazirFontBold,
    ),
  );

  // Table headers
  final itemHeaders = [
    loc.product,
    loc.description,
    loc.quantity,
    loc.unitPrice,
    loc.total,
  ];
  final headersToUse = isRTL ? itemHeaders.reversed.toList() : itemHeaders;

  // Table data rows
  final itemRows = invoice.items.map((item) {
    final product = inventoryProvider.products.firstWhere(
      (p) => p.id == item.productId,
    );
    return [
      product.name,
      item.description ?? '',
      (item.quantity).toString(),
      _currencyFormat.format(item.unitPrice),
      _currencyFormat.format(item.total),
    ];
  }).toList();
  final dataToUse =
      isRTL ? itemRows.map((r) => r.reversed.toList()).toList() : itemRows;

  // Defensive assertion to ensure headers and data row lengths match
  assert(
      headersToUse.length == (dataToUse.isNotEmpty ? dataToUse[0].length : 0),
      'Table headers and data row length mismatch: headers=[$headersToUse.length], row=[$dataToUse.isNotEmpty ? dataToUse[0].length : 0]');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pdfDir,
      header: (pdfContext) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Business info
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        info.name ?? loc.businessName,
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      if (info.address != null)
                        pw.Text(info.address!,
                            style: pw.TextStyle(fontSize: 10)),
                      if (info.phone != null)
                        pw.Text(info.phone!, style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),

                // Logo
                (() {
                  if (info.logo != null && info.logo!.isNotEmpty) {
                    try {
                      final bytes = base64Decode(info.logo!);
                      if (bytes.isNotEmpty) {
                        return pw.Container(
                          width: 60,
                          height: 60,
                          child: pw.Image(
                            pw.MemoryImage(bytes),
                            fit: pw.BoxFit.contain,
                          ),
                        );
                      }
                    } catch (e) {
                      // Ignore and fall through to placeholder
                    }
                  }
                  return pw.SizedBox(width: 60, height: 60);
                })(),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${loc.invoice} ${invoice.invoiceNumber}',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '${loc.printed(formatLocalizedDateTime(context, currentDateTime.toString()))}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            // Invoice & due dates row

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${loc.customer}: ${customerName}'),
                pw.Text(
                    '${loc.invoiceDate}: ${formatLocalizedDate(context, invoice.date.toString())}'),
                if (invoice.dueDate != null)
                  pw.Text(
                    '${loc.dueDate}: ${formatLocalizedDate(context, invoice.dueDate.toString())}',
                    style: pw.TextStyle(
                        color: invoice.isOverdue ? PdfColors.red : null),
                  ),
              ],
            ),

            pw.Divider(thickness: 1),
          ],
        ),
      ),
      build: (pdfContext) {
        final List<pw.Widget> content = [];

        // Items table with header styling and alternating rows
        content.add(
          pw.Directionality(
            textDirection: pdfDir,
            child: pw.TableHelper.fromTextArray(
              headers: headersToUse,
              data: dataToUse,
              headerStyle: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey900),
              rowDecoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey400))),
              oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
              cellStyle: pw.TextStyle(fontSize: 10),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              cellAlignments: isRTL
                  ? {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.center,
                      3: pw.Alignment.centerRight,
                      4: pw.Alignment.centerRight,
                    }
                  : {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.center,
                      3: pw.Alignment.centerLeft,
                      4: pw.Alignment.centerLeft,
                    },
            ),
          ),
        );

        content.add(pw.SizedBox(height: 12));

        // Totals card
        content.add(
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${loc.subtotal}: ${_currencyFormat.format(invoice.subtotal)} ${invoice.currency}',
                  style: pw.TextStyle(fontSize: 11),
                ),
                if (invoice.paidAmount != null && invoice.paidAmount! > 0)
                  pw.Text(
                    '${loc.paidAmount}: ${_currencyFormat.format(invoice.paidAmount)} ${invoice.currency}',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.green),
                  ),
                pw.Divider(),
                pw.Text(
                  '${loc.balanceDue}: ${_currencyFormat.format(invoice.balance)} ${invoice.currency}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: invoice.balance > 0
                        ? (invoice.isOverdue ? PdfColors.red : PdfColors.orange)
                        : PdfColors.green,
                  ),
                ),
              ],
            ),
          ),
        );

        // Optional notes section
        if (invoice.notes != null && invoice.notes!.isNotEmpty) {
          content.add(pw.SizedBox(height: 20));
          content.add(pw.Text('${loc.note}:',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)));
          content.add(pw.SizedBox(height: 8));
          content.add(
            pw.Text(invoice.notes!, style: pw.TextStyle(fontSize: 10)),
          );
        }

        content.add(pw.Spacer());
        content.add(pw.Divider());
        content.add(
          pw.Center(
            child: pw.Text(
              loc.soldGoodsNotReturnable,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        );

        return content;
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) => pdf.save(),
  );
}
