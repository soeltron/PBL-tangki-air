# Menjalankan sistem

Pilih dan jalankan **satu** topologi saja: VM produksi atau Docker lokal. Jangan jalankan Docker bersamaan dengan VM yang sudah menggunakan port 8000, 1883, atau 9001.

## Mode VM

Produksi berjalan pada tiga VM Debian:

- **VM1**: Nginx, PHP-FPM, Laravel, `php artisan mqtt:listen` via systemd, dan scheduler setiap lima menit via cron.
- **VM2**: MariaDB 10.11, database `tandon`.
- **VM3**: Mosquitto dengan autentikasi wajib (1883 MQTT dan 9001 WebSocket), serta backup MariaDB harian pukul 02.00 dengan retensi 7 hari.

Konfigurasikan alamat host, kredensial, dan rahasia di environment VM masing-masing. Sesuaikan Nginx agar `/mqtt` diteruskan ke VM3:9001.

## Mode Docker

Sebelum menjalankan Docker, **matikan VM**, atau setidaknya VM1 dan VM3. Keduanya menggunakan port host yang sama. Docker menyediakan HTTP/API di `http://localhost:8000`, MQTT di `localhost:1883`, dan MQTT WebSocket di `ws://localhost:9001` serta `ws://localhost:8000/mqtt`.

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

Broker Compose mewajibkan autentikasi username/password untuk koneksi MQTT dan WebSocket. Kredensial diberikan ke tim firmware melalui kanal aman di luar repo; jangan menaruhnya di README, source code, issue, atau log.

| Arah | Topik | Format |
|---|---|---|
| ESP32 → backend | `tandon/data` | JSON dengan `device` (`d1` atau `d2`) dan `level` numerik 0–100. `suhu`, `debit`, dan `pompa` dapat dikirim sesuai sensor; `pompa` berupa boolean. |
| Backend → ESP32 | `tandon/config` | JSON retained berisi `batas_air`, `batas_suhu`, `batas_debit`, `capacity_liters`, `pump_on_level`, `pump_off_level`, dan `automatic_pump`. |
| Aplikasi → ESP32 | `tandon/pompa/cmd` | Teks `ON` atau `OFF`; kontrol aplikasi tetap nonaktif sampai firmware siap menerima perintah. |

Gunakan port MQTT TCP `1883`; port WebSocket `9001` disediakan untuk klien yang memerlukannya. Pastikan firmware menggunakan username/password yang sama dengan konfigurasi broker, tanpa menaruh nilainya di firmware yang dibagikan atau dokumentasi publik.

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
