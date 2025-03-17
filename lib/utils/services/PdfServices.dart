import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:train_app/controllers/HiveController.dart';
import 'package:barcode/barcode.dart' as bc; // Add this import

Future<void> generateAndOpenTicketPdf({
  required BuildContext context,
  required String departureCity,
  required String arrivalCity,
  required String departureTime,
  required String arrivalTime,
  required String departureDate,
  required String arrivalDate,
  required double price,
  int? numberOfPassengers,
  String? status,
  List<String>? passengerNames,
  String? ticketId,
}) async {
  final pdf = pw.Document();

  // Create barcode
  final barcode = bc.Barcode.code128();
  final svg =
      ticketId != null
          ? barcode.toSvg(ticketId, width: 200, height: 80, fontHeight: 0)
          : null;

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(20),
      build:
          (pw.Context context) => pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 2),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            padding: const pw.EdgeInsets.all(15),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    color: pw.PdfColor(0, 0.5, 0, 1), // Green background
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Text(
                    'Train Ticket',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: pw.PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 15),

                // Travel Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'From: $departureCity',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          departureTime.isNotEmpty ? departureTime : 'Not set',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.Text(
                          departureDate.isNotEmpty ? departureDate : 'Not set',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'To: $arrivalCity',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          arrivalTime.isNotEmpty ? arrivalTime : 'Not set',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.Text(
                          arrivalDate.isNotEmpty ? arrivalDate : 'Not set',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Divider
                pw.Divider(),

                // Ticket Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Ticket Number',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: pw.PdfColors.grey,
                          ),
                        ),
                        pw.Text(
                          ticketId ?? 'Not provided',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Passenger ID',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: pw.PdfColors.grey,
                          ),
                        ),
                        pw.Text(
                          Get.find<HiveController>().getUserIdSync(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Passengers',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: pw.PdfColors.grey,
                          ),
                        ),
                        pw.Text(
                          '${numberOfPassengers ?? 1} Adult${(numberOfPassengers ?? 1) > 1 ? 's' : ''}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Price',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: pw.PdfColors.grey,
                          ),
                        ),
                        pw.Text(
                          '\$${price.toStringAsFixed(0)}',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: pw.PdfColor(0, 0.5, 0, 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),

                // Passenger Names (if available)
                if (passengerNames != null && passengerNames.isNotEmpty) ...[
                  pw.Text(
                    'Passenger Names',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: pw.PdfColors.grey,
                    ),
                  ),
                  pw.Text(
                    passengerNames.join(', '),
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 15),
                ],

                // Status (if available)
                if (status != null) ...[
                  pw.Text(
                    'Status',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: pw.PdfColors.grey,
                    ),
                  ),
                  pw.Text(
                    status,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                ],

                // Barcode
                pw.Divider(),
                pw.SizedBox(height: 10),
                if (svg != null)
                  pw.Center(
                    child: pw.SvgImage(svg: svg, width: 300, height: 80),
                  )
                else
                  pw.Container(
                    height: 50,
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                      color: pw.PdfColors.grey300,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Barcode/QR Code Placeholder (Ticket ID: N/A)',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 10),

                // Footer
                pw.Text(
                  'Please present this ticket at boarding',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: pw.PdfColors.grey,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
    ),
  );

  try {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/train_ticket_${ticketId ?? DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open PDF: ${result.message}')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }
}
