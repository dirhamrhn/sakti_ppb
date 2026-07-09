import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng initialPosition;
  const MapPickerPage({
    super.key,
    this.initialPosition = const LatLng(-5.2030, 119.4972), // Default Kampus 2 UINAM Samata
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _selectedPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi GPS'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Komponen Utama Peta Gratis (OpenStreetMap)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 17.0,
              // Mengubah posisi koordinat pin saat admin mengetuk area lain di peta
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedPosition = point;
                });
              },
            ),
            children: [
              // Mengambil aset gambar ubin peta dari server publik OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sakti_final',
              ),
              // Menampilkan Pin Merah di atas titik koordinat yang dipilih
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 45,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Tampilan Informasi Koordinat Real-time (Kotak Bawah)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Koordinat Terpilih',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lat: ${_selectedPosition.latitude.toStringAsFixed(6)}\nLng: ${_selectedPosition.longitude.toStringAsFixed(6)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Pilih Lokasi Ini',
                      onPressed: () {
                        // Mengembalikan koordinat terpilih ke form pembuatan jadwal
                        Navigator.pop(context, _selectedPosition);
                      },
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
