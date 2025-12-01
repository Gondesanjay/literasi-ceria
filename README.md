# 📚 Literasi Ceria (Aplikasi Edukasi Anak Usia Dini) - Final Version

Platform literasi digital *full-stack* yang interaktif untuk anak, guru, dan orang tua. Dibangun menggunakan **Flutter** (Frontend) dan **Strapi v5** (Backend). Proyek ini mengimplementasikan konsep "Satu Aplikasi, Dua Mode" untuk menjembatani kesenjangan teknologi di PAUD.

## 🌟 Konsep Inti: "Satu Aplikasi, Dua Mode"

Aplikasi ini melayani dua pengguna utama dengan antarmuka yang berbeda:

1.  **Mode Anak (Antarmuka Belajar):**
    * **Desain:** Ceria, tombol besar, minim teks, dan navigasi visual.
    * **Interaksi:** Game Drag & Drop, Audio Interaktif, dan Video Player ramah anak.
    * **Akses:** Tanpa password, cukup pilih foto profil ("Smart Session").

2.  **Mode Dewasa (Antarmuka Dasbor):**
    * **Desain:** Bersih, berbasis data, dan profesional.
    * **Akses:** Login aman (Email/Password) dengan filter peran (Guru vs Orang Tua).
    * **Fungsi:** Memantau laporan perkembangan anak dan mengakses materi ajar.

---

## ✨ Fitur Unggulan (Selesai Dibangun)

### 👶 Mode Anak (Student Features)
* **Login Visual:** Anak memilih akun berdasarkan foto wajah mereka sendiri.
* **Smart Session:** Aplikasi mengingat anak yang terakhir bermain, jadi tidak perlu login ulang setiap kali membuka aplikasi.
* **Pojok Cerita (Bioskop Mini):**
    * Menonton video pembelajaran dengan UI ramah anak (menggunakan *Chewie Player*).
    * Mendukung mode layar penuh (*Full Screen*) dan kontrol mudah.
* **Taman Huruf (Game Interaktif):**
    * **Konsep:** Mengenal huruf dan benda.
    * **Gameplay:** *Drag & Drop* (Seret & Lepas) gambar benda (misal: Apel) ke kotak huruf yang sesuai (misal: A).
    * **Audio:** Suara huruf/instruksi diputar instan (menggunakan aset lokal).
    * **Feedback:** Animasi bintang/konfeti (*Lottie*) saat jawaban benar.
    * **Acak (Shuffle):** Urutan soal dan posisi gambar selalu berubah agar anak tidak bosan.
* **Petualangan Angka (Numerasi):**
    * Game berhitung benda (misal: Hitung jumlah bola, seret ke angka 3).
    * Menggunakan logika interaktif yang sama dengan Taman Huruf.

### 🧑‍🏫 Mode Guru (Teacher Features)
* **Dasbor Kelas:** Melihat daftar murid yang tertaut di kelasnya saja (Privasi Data Terjamin).
* **Mode Presentasi (Pustaka Materi):**
    * Tab khusus berisi materi ajar yang bersih dan formal.
    * **Fitur Panduan Diskusi:** Menampilkan teks panduan/pertanyaan pemantik di bawah video untuk membantu guru memimpin diskusi kelas.
* **Laporan Perkembangan Canggih:**
    * **Visual:** Grafik Pie Chart (Perbandingan Aktivitas Video vs Game).
    * **Detail Log:** Mencatat secara spesifik apakah anak "Sukses" atau "Gagal", berapa lama durasi pengerjaan (detik), dan detail kesalahannya.

### 👪 Mode Orang Tua (Parent Features)
* Memantau aktivitas belajar anak dari rumah.
* Melihat laporan detail yang sama dengan guru untuk sinkronisasi perkembangan anak.

---

## 🛠️ Tumpukan Teknologi (Tech Stack)

* **Frontend:** Flutter (Dart SDK ^3.0)
* **Backend:** Strapi v5 (Node.js)
* **Database:** MySQL
* **Paket Flutter Kunci:**
    * `audioplayers`: Untuk efek suara game yang responsif.
    * `lottie`: Untuk animasi kemenangan yang menarik.
    * `chewie` & `video_player`: Untuk pemutar video yang kustomisasi.
    * `fl_chart`: Untuk visualisasi data laporan.
    * `shared_preferences`: Untuk manajemen sesi login.
    * `http`: Untuk komunikasi API dengan Strapi.

---

## 🚀 Cara Menjalankan Proyek (Wajib Dibaca!)

Karena proyek ini melibatkan koneksi antara Emulator HP dan Server Lokal, pengaturan Jaringan (IP Address) sangat krusial.

### Prasyarat
* [Node.js](https://nodejs.org/) (v18 atau v20)
* [Flutter SDK](https://flutter.dev/)
* [XAMPP](https://www.apachefriends.org/) (MySQL Database)

### 1. Menjalankan Backend (Strapi)

Kita menggunakan versi backend terbaru (`v2`) yang sudah dilengkapi skrip izin otomatis.

1.  Pastikan MySQL di XAMPP sudah menyala (Start).
2.  Masuk ke folder backend:
    ```bash
    cd literasi-ceria-backend-v2
    ```
3.  Install dependensi (jika belum):
    ```bash
    npm install
    ```
4.  Jalankan server dalam mode develop:
    ```bash
    npm run develop
    ```
    * *Note: Skrip `src/index.ts` akan otomatis mengatur semua Izin (Permission) Public & Authenticated saat server menyala.*
    * **Pastikan** terminal menampilkan akses di: `http://0.0.0.0:1337` (Ini tanda server siap diakses dari luar).

### 2. Menyiapkan Data (Strapi Admin)
Buka `http://localhost:1337/admin` dan pastikan data berikut ada dan berstatus **Published**:
* **Quiz:** Buat soal (Pertanyaan: "A", Gambar URL: [Link], Audio URL: [Link]).
* **Content:** Buat konten Game/Video dan tautkan dengan Quiz di atas.
* **Student & User:** Pastikan data murid terhubung dengan Guru/Ortu.

### 3. Menjalankan Frontend (Flutter)

**PENTING: Pengaturan IP Address**
Emulator Android tidak bisa mengakses `localhost`. Kita harus menggunakan IP WiFi komputer.

1.  Buka Command Prompt (CMD) di komputer, ketik `ipconfig`.
2.  Salin **IPv4 Address** (contoh: `192.168.1.10`).
3.  Buka folder `literasi_ceria_app/lib/`.
4.  Ganti variabel `_strapiBaseUrl` atau `_strapiIP` di file-file berikut dengan IP barumu:
    * `main.dart` / `splash_page.dart`
    * `student_selection_page.dart`
    * `content_list_page.dart`
    * `detail_page.dart`
    * `quiz_game_widget.dart` & `number_game_widget.dart`
    * `video_player_widget.dart`
    * `dashboard_page.dart` & `parent_dashboard_page.dart`
    * `activity_history_page.dart`

5.  Pastikan folder aset audio ada: `literasi_ceria_app/assets/audio/` (isi dengan file `a.mp3`, `1.mp3`, dll).

6.  Jalankan aplikasi:
    ```bash
    cd literasi_ceria_app
    flutter run
    ```

---

## 📝 Struktur Database (Strapi Collection Types)

* **Users:** Menyimpan akun Guru & Orang Tua (dengan field custom `peran`).
* **School:** Menyimpan data sekolah.
* **Student:** Profil anak (Nama, Foto) yang berelasi dengan Guru & Ortu.
* **Content:** Materi ajar (Judul, Tipe, Thumbnail, Deskripsi, Video URL).
* **Quiz:** Soal-soal untuk game (Pertanyaan/Huruf, Gambar URL, Audio URL).
* **ActivityLog:** Mencatat riwayat bermain (Student ID, Content ID, Durasi, Module, Action, Result, Detail).

---
*Dibuat dengan semangat untuk memajukan pendidikan anak usia dini di Indonesia.* 🇮🇩