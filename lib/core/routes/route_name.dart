class RouteName {
  RouteName._();

  // ─── Core ──────────────────────────────────────────────────
  static const String splash = '/';

  // ─── Auth ──────────────────────────────────────────────────
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // ─── Admin ─────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProfile = '/admin/profile';

  // Admin — Mahasiswa
  static const String adminMahasiswaList = '/admin/mahasiswa';
  static const String adminMahasiswaForm = '/admin/mahasiswa/form';

  // Admin — Dosen
  static const String adminDosenList = '/admin/dosen';
  static const String adminDosenForm = '/admin/dosen/form';

  // Admin — Asdos
  static const String adminAsdosList = '/admin/asdos';
  static const String adminAsdosForm = '/admin/asdos/form';

  // Admin — Mata Kuliah
  static const String adminMatakuliahList = '/admin/matakuliah';
  static const String adminMatakuliahForm = '/admin/matakuliah/form';

  // Admin — Kelas
  static const String adminKelasList = '/admin/kelas';
  static const String adminKelasForm = '/admin/kelas/form';
  static const String adminKelasDetail = '/admin/kelas/detail';

  // Admin — Jadwal
  static const String adminJadwalList = '/admin/jadwal';
  static const String adminJadwalForm = '/admin/jadwal/form';

  // Admin — Gedung dan Ruangan
  static const String adminGedungList = '/admin/gedung';
  static const String adminGedungForm = '/admin/gedung/form';
  static const String adminRuanganList = '/admin/gedung/ruangan';
  static const String adminRuanganForm = '/admin/gedung/ruangan/form';

  // ─── Mahasiswa ─────────────────────────────────────────────
  static const String mahasiswaDashboard = '/mahasiswa/dashboard';
  static const String mahasiswaNilai = '/mahasiswa/nilai';

  // ─── Dosen ─────────────────────────────────────────────────
  static const String dosenDashboard = '/dosen/dashboard';
  static const String dosenKelasDetail = '/dosen/kelas/detail';

  // ─── Asdos ─────────────────────────────────────────────────
  static const String asdosDashboard = '/asdos/dashboard';
}
