<?php

namespace App\Console\Commands;

use App\Models\SensorData;
use App\Services\WaterFillingTracker;
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
            if ($this->processMessage($message) !== null) {
                $this->line("Disimpan: $message");
            }
        }, 0);

        $mqtt->loop(true);
    }

    public function processMessage(string $message): ?SensorData
    {
        $data = json_decode($message, true);
        if (!is_array($data) || !isset($data['device'])) {
            return null;
        }

        $previousPump = null;
        if ($data['device'] === 'd1') {
            $previousPump = SensorData::query()
                ->where('device', 'd1')
                ->latest('id')
                ->value('pompa');
            $previousPump = $previousPump === null ? null : (bool) $previousPump;
        }

        $sensorData = SensorData::create([
            'device' => $data['device'],
            'level' => $data['level'] ?? null,
            'suhu' => $data['suhu'] ?? null,
            'debit' => $data['debit'] ?? null,
            'pompa' => $data['pompa'] ?? null,
        ]);

        app(WaterFillingTracker::class)->record($sensorData, $previousPump);

        return $sensorData;
    }
}
