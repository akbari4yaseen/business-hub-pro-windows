import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:BusinessHubPro/localization/app_localizations.dart';

import '../../models/invoice.dart';
import '../../providers/account_provider.dart';
import '../../providers/info_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/date_formatters.dart';

final _currencyFormat = NumberFormat('#,##0.###');

Future<void> printInvoice({
  required BuildContext context,
  required Invoice invoice,
  required InfoProvider infoProvider,
  required InventoryProvider inventoryProvider,
  required AccountProvider accountProvider,
}) async {
  // ================= LOAD INFO =================

  await infoProvider.loadInfo();

  final info = infoProvider.info;

  // ================= CUSTOMER =================

  final customer = accountProvider.accounts.firstWhere(
    (c) => c['id'] == invoice.accountId,
    orElse: () => <String, dynamic>{
      'name': 'Unknown Customer',
    },
  );

  final currentDateTime = DateTime.now();

  // ================= LOCALIZATION =================

  final loc = AppLocalizations.of(context)!;

  final localeCode = Localizations.localeOf(context).languageCode;

  final isRTL = localeCode != 'en';

  final pdfDir = isRTL ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  // ================= COLUMN WIDTHS =================

  final columnWidths = isRTL
      ? {
          4: const pw.FixedColumnWidth(25),
          3: const pw.FlexColumnWidth(3),
        }
      : {
          0: const pw.FixedColumnWidth(25),
          1: const pw.FlexColumnWidth(3),
        };

  // ================= FONTS =================

  final fontRegular = pw.Font.ttf(
    await rootBundle.load(
      'assets/fonts/Vazirmatn-Regular.ttf',
    ),
  );

  final fontBold = pw.Font.ttf(
    await rootBundle.load(
      'assets/fonts/Vazirmatn-Bold.ttf',
    ),
  );

  // ================= PDF =================

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    ),
  );

  // ================= TABLE DATA =================

  final headers = [
    '#',
    loc.product,
    loc.quantity,
    loc.unitPrice,
    loc.total,
  ];

  final rows = invoice.items.asMap().entries.map((entry) {
    final i = entry.key + 1;

    final item = entry.value;

    final product = inventoryProvider.products.firstWhere(
      (p) => p.id == item.productId,
    );

    String unitName = '';

    if (item.unitId != null) {
      try {
        final unit = inventoryProvider.units.firstWhere(
          (u) => u.id == item.unitId,
        );

        unitName = unit.name;
      } catch (_) {}
    }

    return [
      i.toString(),
      product.name,
      '${_currencyFormat.format(item.quantity)} $unitName',
      _currencyFormat.format(item.unitPrice),
      _currencyFormat.format(item.total),
    ];
  }).toList();

  // ================= TABLE BUILDER =================

  pw.Widget buildTable() {
    List<List<String>> tableData = [
      headers,
      ...rows,
    ];

    if (isRTL) {
      tableData = tableData
          .map(
            (row) => row.reversed.toList(),
          )
          .toList();
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
        width: 0.3,
      ),
      columnWidths: columnWidths,
      children: List.generate(
        tableData.length,
        (rowIndex) {
          final row = tableData[rowIndex];

          final isHeader = rowIndex == 0;

          return pw.TableRow(
            decoration: isHeader
                ? pw.BoxDecoration(
                    color: PdfColors.blueGrey900,
                  )
                : null,
            children: List.generate(
              row.length,
              (colIndex) {
                final text = row[colIndex];

                final isNumberColumn =
                    isRTL ? colIndex == row.length - 1 : colIndex == 0;

                return pw.Padding(
                  padding: const pw.EdgeInsets.all(
                    6,
                  ),
                  child: pw.Align(
                    alignment: _getAlignment(
                      colIndex,
                      isRTL,
                    ),
                    child: pw.Text(
                      text,
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: isHeader ? PdfColors.white : PdfColors.black,
                        fontWeight: isHeader || isNumberColumn
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ================= PAGE =================

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        textDirection: pdfDir,
        // margin: const pw.EdgeInsets.all(25),
      ),

      // ================= CONTENT =================

      build: (pdfContext) => [
        // ================= HEADER =================

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  info.name ?? loc.businessName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (info.address != null)
                  pw.Text(
                    info.address!,
                    style: pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                if (info.phone != null)
                  pw.Text(
                    '${info.phone!}  ${info.whatsApp}',
                    style: pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
              ],
            ),

            // ================= LOGO =================

            if (info.logo != null && info.logo!.isNotEmpty)
              pw.Image(
                pw.MemoryImage(
                  base64Decode(
                    info.logo!,
                  ),
                ),
                width: 60,
                height: 60,
              ),
          ],
        ),

        pw.SizedBox(height: 12),

        // ================= INVOICE INFO =================

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${loc.invoice} ${invoice.invoiceNumber}',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.red900,
              ),
            ),
            pw.Text(
              formatLocalizedDate(
                context,
                invoice.date.toString(),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 5),

        // ================= CUSTOMER =================

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${loc.customer}: ${customer['name']}',
            ),
            pw.Text(
              formatLocalizedDateTime(
                context,
                currentDateTime.toString(),
              ),
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),

        pw.Divider(thickness: 1),

        // ================= TABLE =================

        buildTable(),

        pw.SizedBox(height: 12),

        // ================= TOTAL =================

        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '${loc.subtotal}: '
                '${_currencyFormat.format(invoice.subtotal)} '
                '${invoice.currency}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
            ],
          ),
        ),

        // ================= NOTES =================

        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Text(
            '${loc.note}:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(
              10,
            ),
            child: pw.Text(
              invoice.notes!,
              style: const pw.TextStyle(
                fontSize: 9,
              ),
            ),
          ),
        ],
      ],
    ),
  );

  // ================= PRINT =================

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}

// ================= ALIGNMENT HELPER =================

pw.Alignment _getAlignment(
  int colIndex,
  bool isRTL,
) {
  if (isRTL) {
    switch (colIndex) {
      case 0:
        return pw.Alignment.centerLeft;

      case 1:
        return pw.Alignment.centerLeft;

      case 2:
        return pw.Alignment.centerRight;

      case 3:
        return pw.Alignment.centerRight;

      case 4:
        return pw.Alignment.center;

      default:
        return pw.Alignment.center;
    }
  } else {
    switch (colIndex) {
      case 0:
        return pw.Alignment.center;

      case 1:
        return pw.Alignment.centerLeft;

      case 2:
        return pw.Alignment.centerLeft;

      case 3:
        return pw.Alignment.center;

      case 4:
        return pw.Alignment.centerRight;

      default:
        return pw.Alignment.center;
    }
  }
}
