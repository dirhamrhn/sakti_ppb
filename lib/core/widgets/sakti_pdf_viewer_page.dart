import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SaktiPdfViewerPage extends StatelessWidget {
  final String title;
  final String pdfUrl;

  const SaktiPdfViewerPage({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: pdfUrl.isEmpty
          ? const Center(
              child: Text(
                'File URL tidak valid.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : SfPdfViewer.network(
              pdfUrl,
              canShowScrollHead: true,
              canShowScrollStatus: true,
            ),
    );
  }
}
