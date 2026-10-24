<?php

namespace App\Http\Controllers;

use App\Models\Setting;
use Illuminate\Http\Request;
use PhpMqtt\Client\MqttClient;

class SettingController extends Controller
{
    private function current(): Setting
    {
        return Setting::firstOrCreate(['id' => 1], [
            'batas_air' => 30, 'batas_suhu' => 30, 'batas_debit' => 1,
        ]);
    }

    public function show()
    {
        return $this->current();
    }

    public function update(Request $r)
    {
        $data = $r->validate([
            'batas_air'   => 'sometimes|numeric|min:0|max:100',
            'batas_suhu'  => 'sometimes|numeric|min:0|max:100',
            'batas_debit' => 'sometimes|numeric|min:0',
        ]);
        $s = $this->current();
        $s->update($data);
        $this->publish($s);
        return $s;
    }

    private function publish(Setting $s): void
    {
        try {
            $mqtt = new MqttClient(
                env('MQTT_HOST', 'mosquitto'),
                (int) env('MQTT_PORT', 1883),
                'laravel-config-' . uniqid()
            );
            $mqtt->connect();
            $mqtt->publish('tandon/config', json_encode([
                'batas_air'   => $s->batas_air,
                'batas_suhu'  => $s->batas_suhu,
                'batas_debit' => $s->batas_debit,
            ]), 0, true);   // true = retained
            $mqtt->disconnect();
        } catch (\Throwable $e) {
            report($e);
        }
    }
}
