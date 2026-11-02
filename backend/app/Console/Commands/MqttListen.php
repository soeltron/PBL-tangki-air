<?php

namespace App\Console\Commands;

use App\Models\SensorData;
use Illuminate\Console\Command;
use PhpMqtt\Client\MqttClient;
use PhpMqtt\Client\ConnectionSettings;

class MqttListen extends Command
{
    protected $signature = 'mqtt:listen';
    protected $description = 'Subscribe MQTT dan simpan data ke database';

    public function handle()
    {
        $mqtt = new MqttClient(
            env('MQTT_HOST', 'mosquitto'),
            (int) env('MQTT_PORT', 1883),
            'laravel-worker'
        );
        $mqtt->connect((new ConnectionSettings)->setUsername(env("MQTT_USERNAME"))->setPassword(env("MQTT_PASSWORD")), true);
        $this->info('Terhubung ke MQTT, menunggu data...');

        $mqtt->subscribe('tandon/data', function (string $topic, string $message) {
            $d = json_decode($message, true);
            if (!is_array($d) || !isset($d['device'])) {
                return;
            }
            SensorData::create([
                'device' => $d['device'],
                'level'  => $d['level'] ?? null,
                'suhu'   => $d['suhu'] ?? null,
                'debit'  => $d['debit'] ?? null,
            ]);
            $this->line("Disimpan: $message");
        }, 0);

        $mqtt->loop(true);
    }
}
