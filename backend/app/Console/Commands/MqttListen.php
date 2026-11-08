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
        $data = json_decode($message);
        if (
            !is_object($data)
            || !isset($data->device)
            || !in_array($data->device, ['d1', 'd2'], true)
        ) {
            return null;
        }

        if ($data->device === 'd1') {
            if (
                !isset($data->level)
                || !is_numeric($data->level)
                || $data->level < 0
                || $data->level > 100
                || !isset($data->suhu)
                || !is_numeric($data->suhu)
                || !property_exists($data, 'pompa')
                || !is_bool($data->pompa)
            ) {
                return null;
            }
        } elseif (
            !isset($data->debit)
            || !is_numeric($data->debit)
            || $data->debit < 0
        ) {
            return null;
        }

        $previousPump = null;
        if ($data->device === 'd1') {
            $previousPump = SensorData::query()
                ->where('device', 'd1')
                ->latest('id')
                ->value('pompa');
            $previousPump = $previousPump === null ? null : (bool) $previousPump;
        }

        $sensorData = SensorData::create([
            'device' => $data->device,
            'level' => $data->level ?? null,
            'suhu' => $data->suhu ?? null,
            'debit' => $data->debit ?? null,
            'pompa' => $data->pompa ?? null,
        ]);

        app(WaterFillingTracker::class)->record($sensorData, $previousPump);

        return $sensorData;
    }
}
