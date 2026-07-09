import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
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
        actions: [
          if (pdfUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_rounded, color: AppColors.primary),
              tooltip: 'Unduh / Buka di Browser',
              onPressed: () async {
                final uri = Uri.parse(pdfUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tidak dapat membuka file di browser.')),
                    );
                  }
                }
              },
            ),
        ],
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
