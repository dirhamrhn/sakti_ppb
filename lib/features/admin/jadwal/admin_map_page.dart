import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  // Titik koordinat awal default saat peta dibuka (Contoh: Makassar/Gowa)
  LatLng _selectedLocation = const LatLng(-5.147665, 119.432731);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentukan Koordinat Lokasi'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. Komponen Utama Peta Gratis (OpenStreetMap)
          FlutterMap(
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 13.0,
              // Mengubah posisi koordinat pin saat admin mengetuk area lain di peta
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              // Mengambil aset gambar ubin peta dari server publik OpenStreetMap
              TileLayer(
                urlTemplate: 'https://openstreetmap.org{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sakti_final',
              ),
              // Menampilkan Pin Merah di atas titik koordinat yang dipilih
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
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

          // 2. Tampilan Informasi Koordinat Real-time (Kotak Atas)
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Card(
              color: Colors.white.withOpacity(0.9),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Koordinat Terpilih:\nLat: ${_selectedLocation.latitude}\nLng: ${_selectedLocation.longitude}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),

          // 3. Tombol Simpan untuk Admin (Aksi Kirim ke Firebase)
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'SIMPAN KOORDINAT LOKASI',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // TODO: Hubungkan fungsi simpan ini ke database Firestore Anda
                // Contoh pengiriman data: _selectedLocation.latitude dan _selectedLocation.longitude
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Koordinat berhasil dikunci: $_selectedLocation'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
