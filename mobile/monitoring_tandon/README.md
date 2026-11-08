# Monitoring Tandon

## Konfigurasi

Atur alamat server dan kredensial MQTT menggunakan `--dart-define` atau
`--dart-define-from-file`. Mulai dari template `dart_defines.example.json`,
salin ke `dart_defines.json`, lalu isi nilai lokal. Jangan commit file lokal
atau menaruh password dan token di repo.

```sh
flutter run --dart-define-from-file=dart_defines.json
```

Kredensial MQTT wajib. `MQTT_PASSWORD` yang kosong akan ditampilkan sebagai
kesalahan konfigurasi di aplikasi. Username MQTT adalah `tandon`; minta
password ke tim backend secara pribadi dan jangan menuliskannya di repo.
