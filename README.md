# Menjalankan sistem

Pilih dan jalankan **satu** topologi saja: VM produksi atau Docker lokal. Jangan jalankan Docker bersamaan dengan VM yang sudah menggunakan port host 8000 atau 1883.

## Mode VM

Produksi berjalan pada tiga VM Debian:

- **VM1**: Nginx, PHP-FPM, Laravel, `php artisan mqtt:listen` via systemd, dan scheduler setiap lima menit via cron.
- **VM2**: MariaDB 10.11, database `tandon`.
- **VM3**: Mosquitto dengan autentikasi wajib (1883 MQTT dan 9001 WebSocket), serta backup MariaDB harian pukul 02.00 dengan retensi 7 hari.

Konfigurasikan alamat host, kredensial, dan rahasia di environment VM masing-masing. Sesuaikan Nginx agar `/mqtt` diteruskan ke VM3:9001.

## Mode Docker

Sebelum menjalankan Docker, **matikan VM**, atau setidaknya VM1 dan VM3. Keduanya menggunakan port host yang sama. Docker menyediakan HTTP/API di `http://localhost:8000`, MQTT TCP di `localhost:1883`, dan MQTT WebSocket melalui Nginx di `ws://localhost:8000/mqtt`. Listener WebSocket Mosquitto pada port 9001 hanya tersedia di jaringan internal Docker, tidak dipublikasikan ke host.

### Tiga node logis

Compose mengelompokkan layanan ke tiga node logis. Secara default semuanya berjalan pada satu host Docker; kelompok ini menjelaskan tanggung jawab layanan, bukan tiga host yang harus disediakan:

| Node logis | Layanan | Tanggung jawab |
|---|---|---|
| Backend | `web`, `app`, `worker`, `scheduler` | Nginx/PHP-FPM, API dan dashboard Laravel, penerima MQTT, serta agregasi statistik terjadwal |
| Database | `db` | MariaDB 10.11; hanya dapat diakses melalui jaringan internal Compose, tanpa port database di host |
| MQTT + backup | `mqtt`, `backup` | Broker MQTT berautentikasi dan backup database terjadwal |

`docker-compose.dev.yml` adalah override untuk Compose utama, bukan stack terpisah. Untuk mode pengembangan dengan source backend ter-mount baca-saja:

```sh
docker compose --env-file .env.docker -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

### Migrasi data dari VM

Hentikan penulisan dari aplikasi lama dan buat backup database VM sebelum cutover. Jalankan `db` dan `mqtt` terlebih dahulu, pulihkan dump database ke MariaDB Compose, lalu jalankan layanan backend dan migrasi Laravel yang diperlukan. Jangan menghapus volume Docker selama proses perpindahan; pertahankan backup VM sampai data dan layanan baru terverifikasi.

### Untuk tim ESP32

Broker Compose mewajibkan username dan password untuk koneksi MQTT maupun WebSocket. Username dan password MQTT wajib; minta kredensialnya lewat chat pribadi, bukan dari repo. Jangan menaruh nilainya di README, source code, issue, atau log.

| Arah | Topik | Format |
|---|---|---|
| ESP32 → backend | `tandon/data` | JSON dengan `device` (`d1` atau `d2`) dan `level` numerik 0–100. `suhu`, `debit`, dan `pompa` dapat dikirim sesuai sensor; `pompa` berupa boolean. |
| Backend → ESP32 | `tandon/config` | JSON retained; backend mengirim ulang setiap kali admin menyimpan pengaturan. |
| Aplikasi → ESP32 | `tandon/pompa/cmd` | Teks `ON` atau `OFF`; kontrol aplikasi tetap nonaktif sampai firmware siap menerima perintah. |

Payload `tandon/config` berisi tujuh kunci berikut sesuai tipe nilai dari `SettingController`:

| Kunci | Tipe JSON |
|---|---|
| `capacity_liters` | number |
| `pump_on_level` | number |
| `pump_off_level` | number |
| `automatic_pump` | boolean |
| `batas_suhu` | number |
| `batas_debit` | number |
| `batas_air` | number |

Contoh payload:

```json
{
  "capacity_liters": 1500,
  "pump_on_level": 20,
  "pump_off_level": 90,
  "automatic_pump": true,
  "batas_suhu": 32,
  "batas_debit": 2.4,
  "batas_air": 35
}
```

Gunakan port MQTT TCP `1883` untuk firmware dan klien native. Flutter web memakai WebSocket melalui `ws://<host>:8000/mqtt` untuk localhost/IP atau `wss://<domain>/mqtt` di produksi. Untuk Flutter, salin `mobile/monitoring_tandon/dart_defines.example.json` menjadi `dart_defines.json`, isi konfigurasi lokal, lalu jalankan `flutter run --dart-define-from-file=dart_defines.json`; atau berikan nilai dengan `--dart-define=SERVER_HOST=...`, `--dart-define=MQTT_USERNAME=...`, dan `--dart-define=MQTT_PASSWORD=...`. File definisi lokal tidak boleh di-commit. Pastikan firmware menggunakan username/password yang sama dengan konfigurasi broker; username dan password MQTT wajib dan diminta lewat chat pribadi, bukan dari repo.

Buat file rahasia lokal dari template dan isi nilai rahasia sendiri. Jangan commit `.env.docker`.

```sh
cp .env.docker.example .env.docker
```

Set `APP_KEY` dengan `php artisan key:generate --show` dari `backend/` (salin hasilnya ke `.env.docker`). Ganti placeholder password DB dan MQTT dengan nilai acak yang panjang; tetapkan `DB_ROOT_PASSWORD` yang berbeda. `NGROK_AUTHTOKEN` hanya diperlukan bila menggunakan profile tunnel. Untuk akses lewat HTTPS/ngrok, atur `APP_URL` ke URL HTTPS publik dan `SESSION_SECURE_COOKIE=true`.

Validasi konfigurasi, bangun image, dan hidupkan layanan:

```sh
docker compose --env-file .env.docker config --quiet
docker compose --env-file .env.docker up -d --build
docker compose --env-file .env.docker ps
```

Migrasi dijalankan secara eksplisit setelah database sehat:

```sh
docker compose --env-file .env.docker exec app php artisan migrate --force
```

Buat admin pertama dengan prompt password interaktif (jalankan dari terminal interaktif):

```sh
docker compose --env-file .env.docker exec app php artisan app:make-admin admin admin@example.com
```

Buka `http://localhost:8000/login` dan masuk dengan username/email admin. Endpoint `/up` memberi pemeriksaan cepat kesehatan aplikasi. Perintah berikut mengecek health endpoint dan API login; request login memakai akun yang tidak ada agar tidak mengirim password atau token sungguhan:

```sh
curl -i http://localhost:8000/up
curl -i -H "Accept: application/json" -H "Content-Type: application/json" \
  -d '{"login":"docker-smoke-test-user","password":"not-a-real-password"}' \
  http://localhost:8000/api/login
```

Tes login yang tidak valid diharapkan mengembalikan HTTP 401. Uji handshake WebSocket melalui Nginx:

```sh
curl --http1.1 --max-time 3 -i \
  -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  http://localhost:8000/mqtt
```

Handshake berhasil jika respons memuat `101 Switching Protocols`. Batas waktu curl setelah menerima 101 normal karena koneksi WebSocket tetap terbuka.

Hidupkan tunnel ngrok hanya bila diperlukan:

```sh
docker compose --env-file .env.docker --profile tunnel up -d ngrok
```

Lihat status dan log:

```sh
docker compose --env-file .env.docker ps
docker compose --env-file .env.docker logs -f web app worker scheduler mqtt db backup
```

Hentikan layanan tanpa menghapus data volume:

```sh
docker compose --env-file .env.docker down
```

Backup otomatis berjalan setiap hari pukul 02.00 waktu Jakarta dan menyimpan arsip terkompresi pada volume Docker `backups`; arsip lebih dari tujuh hari dihapus. Daftar file backup:

```sh
docker compose --env-file .env.docker exec backup ls -lh /backups
```

Untuk menyalin backup ke host:

```sh
docker compose --env-file .env.docker cp backup:/backups/tandon-YYYYMMDD-HHMMSS.sql.gz .
```

Restore arsip SQL terkompresi ke database yang sudah berjalan (operasi ini menimpa isi database `tandon`):

```sh
gzip -dc tandon-YYYYMMDD-HHMMSS.sql.gz | docker compose --env-file .env.docker exec -T db sh -c 'mariadb -u root -p"$MARIADB_ROOT_PASSWORD"'
```

Jangan gunakan `docker compose down -v` kecuali memang ingin menghapus database, password Mosquitto, backup, dan storage Laravel yang persisten.
