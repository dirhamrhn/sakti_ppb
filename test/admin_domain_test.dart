import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakti_final/models/jadwal_model.dart';
import 'package:sakti_final/models/kelas_model.dart';
import 'package:sakti_final/models/matakuliah_model.dart';

void main() {
  group('Konfigurasi Admin', () {
    test('mata kuliah teori praktikum mengaktifkan flow praktikum', () {
      final model = MatakuliahModel(
        id: 'mk-1',
        kode: 'IF301',
        nama: 'Pemrograman Mobile',
        sks: 4,
        semester: '5',
        programStudiId: 'if',
        programStudiNama: 'Informatika',
        deskripsi: '',
        status: true,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        jenisMatakuliah: JenisMatakuliah.teoriPraktikum.value,
      );

      expect(model.hasPraktikum, isTrue);
      expect(model.toMap()['hasPraktikum'], isTrue);
    });

    test('bobot nilai kelas harus berjumlah 100 persen', () {
      final model = KelasModel(
        id: 'kelas-1',
        namaKelas: 'A',
        matakuliahId: 'mk-1',
        matakuliahNama: 'Pemrograman Mobile',
        matakuliahKode: 'IF301',
        dosenId: 'dosen-1',
        dosenNama: 'Dosen',
        asdosIds: const [],
        asdosNama: const [],
        semesterId: '5',
        semesterNama: 'Ganjil',
        kapasitas: 40,
        jumlahMahasiswa: 0,
        status: true,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      expect(model.isBobotValid, isTrue);
      expect(model.copyWith(bobotUAS: 50).isBobotValid, isFalse);
    });

    test('jadwal menyimpan konfigurasi absensi GPS', () {
      final model = JadwalModel(
        id: 'jadwal-1',
        kelasId: 'kelas-1',
        kelasNama: 'IF301-A',
        matakuliahNama: 'Pemrograman Mobile',
        matakuliahKode: 'IF301',
        dosenNama: 'Dosen',
        hari: 'Senin',
        jamMulai: '08:00',
        jamSelesai: '10:00',
        jenisSesi: 'praktikum',
        latitude: -6.2,
        longitude: 106.8,
        radiusAbsensi: 100,
        toleransiMenit: 15,
        totalPertemuan: 8,
        status: true,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      expect(model.isPraktikum, isTrue);
      expect(model.hasGpsLocation, isTrue);
      expect(model.totalPertemuan, 8);
      expect(model.toMap()['metodeAbsensi'], 'gps');
    });
  });
}
