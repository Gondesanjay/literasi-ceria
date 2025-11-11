#  Literasi Ceria (Aplikasi Edukasi Full-Stack)

Sebuah platform literasi digital *full-stack* untuk anak usia dini, guru, dan orang tua, dibangun menggunakan **Flutter** dan **Strapi**. Proyek ini adalah implementasi dari dokumen konsep "Literasi Ceria".



## 🌟 Konsep Inti: "Satu Aplikasi, Dua Mode"

[cite_start]Aplikasi ini menggunakan satu basis kode (codebase) untuk melayani dua antarmuka yang sangat berbeda, berdasarkan dokumen konsep[cite: 8]:

1.  **Mode Anak (Antarmuka Belajar):**
    * [cite_start]Desain visual seperti game edukasi, minim teks, dan kaya audio/video[cite: 13].
    * [cite_start]Akses tanpa login; anak cukup memilih profil mereka berdasarkan nama/foto[cite: 14].
    * [cite_start]Secara otomatis mencatat log aktivitas (konten apa yang dimainkan/ditonton) ke backend[cite: 71].

2.  **Mode Dewasa (Antarmuka Dasbor):**
    * [cite_start]Desain bersih berbasis data dan menu[cite: 17].
    * [cite_start]Akses aman menggunakan login email/password[cite: 18].
    * [cite_start]Menampilkan dasbor yang berbeda berdasarkan peran (Role) pengguna[cite: 19].

## ✨ Fitur Utama yang Telah Diimplementasikan

### Mode Anak (Publik)
* **Pemilihan Profil:** Anak memilih profil mereka (`StudentSelectionPage`).
* [cite_start]**Pustaka Konten:** Menampilkan daftar konten (video & game) secara dinamis dari Strapi (`ContentListPage`)[cite: 51, 56].
* **Video Player:** Memutar konten video langsung dari Strapi (`DetailPage` dengan `video_player`).
* [cite_start]**Pencatatan Aktivitas:** Secara otomatis mengirim log (`ActivityLog`) ke Strapi setiap kali anak membuka konten[cite: 71, 75].

### Mode Dewasa (Terproteksi)
* **Splash Screen Pintar:** Mengecek sesi (`SharedPreferences`) saat aplikasi dibuka. Jika sudah login, langsung masuk ke dasbor yang sesuai.
* **Login Berbasis Peran:** Sistem login aman yang terhubung ke Strapi (`/api/auth/local`) dan menyimpan token (JWT) serta peran pengguna (`guru` atau `orang_tua`).
* [cite_start]**Dasbor Guru:** Menampilkan daftar murid yang **hanya** tertaut ke guru yang sedang login (menggunakan *workaround* filter sisi klien untuk mengatasi bug izin relasi Strapi)[cite: 62].
* [cite_start]**Dasbor Orang Tua:** Menampilkan daftar anak yang **hanya** tertaut ke orang tua yang sedang login (logika filter yang sama)[cite: 64].
* **Laporan Kualitatif:**
    * Guru/Ortu dapat mengklik nama murid/anak untuk melihat `ActivityHistoryPage`.
    * [cite_start]Halaman ini mengambil *semua* log aktivitas untuk anak tersebut[cite: 71].
    * Halaman ini juga mengambil "kamus" konten untuk menampilkan nama konten (cth: "Cerita Kancil") bukan hanya ID ("Konten 12").
    * [cite_start]Menampilkan tab "Laporan" dengan analisis kualitatif sederhana (Total aktivitas, total durasi, dan insight)[cite: 69].

## 🛠️ Tumpukan Teknologi (Tech Stack)

* **Frontend (Aplikasi Mobile):** Flutter
* **Backend (Headless CMS):** Strapi v5
* **Database:** MySQL

---

## 🚀 Langkah-langkah Instalasi & Menjalankan Proyek

Berikut adalah cara untuk menjalankan proyek ini di komputermu.

### Prasyarat
* [Node.js](https://nodejs.org/) (v18 atau v20+)
* [Flutter SDK](https://flutter.dev/docs/get-started/install)
* [XAMPP](https://www.apachefriends.org/index.html) (atau server MySQL lainnya)
* Sebuah server database MySQL yang berjalan (buat database kosong, misal `literasi_ceria_db`).

### 1. Penyiapan Backend (Strapi)

Server Strapi **wajib** dijalankan terlebih dahulu.

1.  **Masuk ke folder backend:**
    ```bash
    cd literasi-ceria-backend
    ```

2.  **Install semua dependensi:**
    ```bash
    npm install
    ```

3.  **Konfigurasi Database:**
    * Proyek ini sudah dikonfigurasi untuk berjalan di `0.0.0.0` (untuk koneksi Emulator) menggunakan file `config/env/development/server.ts`.
    * Kamu mungkin perlu mengatur koneksi database MySQL-mu di file `config/database.js` atau di file `.env`.

4.  **Bangun (Build) Proyek:**
    * Kita perlu membangun (compile) file kustom `src/index.ts` (untuk "memaksa" izin) dan `config/server.ts` (untuk host).
    ```bash
    npm run build
    ```

5.  **Jalankan Server Strapi (Mode Develop):**
    * Gunakan `npm run develop` (bukan `start`) agar skrip "pemaksa izin" (Bootstrap) kita berjalan.
    ```bash
    npm run develop
    ```
    * Saat server menyala, **pastikan kamu melihat dua hal di log:**
        1.  `✅ Izin ... BERHASIL DI-UPDATE...` (Bukti izin beres)
        2.  `http://0.0.0.0:1337` (Bukti host beres)

6.  **Setup Manual Strapi (Wajib):**
    * Buka `http://localhost:1337/admin` dan buat akun Super Admin pertamamu.
    * Buat data `Content` (Pojok Cerita), unggah video, dan salin URL-nya ke field `video_url`. **Jangan lupa `Publish`**.
    * Buat data `User` (1 Guru, 1 Ortu), pastikan `Confirmed=TRUE`, `role=Authenticated`, dan `peran` diisi.
    * Buat data `Student` (Murid), **jangan lupa `Publish`**.
    * Tautkan `Student` ke `User` (Guru & Ortu) melalui field relasi di Strapi.

### 2. Penyiapan Frontend (Flutter)

1.  **Pastikan Server Strapi sedang berjalan!**

2.  **Masuk ke folder frontend:**
    ```bash
    cd literasi_ceria_app
    ```

3.  **Install semua dependensi:**
    ```bash
    flutter pub get
    ```

4.  **Cek Koneksi:**
    * Pastikan semua alamat IP di dalam file `.dart` (seperti `http://10.0.2.2:1337`) sudah benar untuk setup-mu. (`10.0.2.2` adalah alamat IP khusus untuk Android Emulator).

5.  **Jalankan Aplikasi:**
    * Pastikan Emulator-mu berjalan (disarankan melakukan "Wipe Data" dan "Cold Boot" jika ini pertama kalinya).
    ```bash
    flutter run
    ```