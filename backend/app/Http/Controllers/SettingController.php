<?php

namespace App\Http\Controllers;

use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use PhpMqtt\Client\MqttClient;
use PhpMqtt\Client\ConnectionSettings;

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
        return response()->json($this->current());
    }

    public function update(Request $r)
    {
        $isAdmin = $r->user()->role === 'admin';
        if (!$isAdmin && array_diff(array_keys($r->all()), ['automatic_pump']) !== []) {
            return response()->json([
                'message' => 'Hanya admin yang dapat mengubah pengaturan sistem.',
            ], 403);
        }

        $data = $r->validate([
            'automatic_pump' => 'sometimes|boolean',
            'capacity_liters' => 'sometimes|numeric|gt:0',
            'pump_on_level' => 'sometimes|numeric|min:0|max:100',
            'pump_off_level' => 'sometimes|numeric|min:0|max:100',
            'batas_air' => 'sometimes|numeric|min:0|max:100',
            'batas_suhu' => 'sometimes|numeric|min:0|max:100',
            'batas_debit' => 'sometimes|numeric|min:0',
        ]);
        $s = $this->current();
        if ($isAdmin) {
            $pumpOn = $data['pump_on_level'] ?? $s->pump_on_level;
            $pumpOff = $data['pump_off_level'] ?? $s->pump_off_level;
            if ($pumpOn >= $pumpOff) {
                throw ValidationException::withMessages([
                    'pump_on_level' => 'Level pompa menyala harus lebih rendah dari level pompa mati.',
                ]);
            }
        }
        $s->update($data);
        if ($isAdmin && array_intersect(
            array_keys($data),
            ['batas_air', 'batas_suhu', 'batas_debit'],
        ) !== []) {
            $this->publish($s);
        }

        return response()->json($s);
    }

    private function publish(Setting $s): void
    {
        try {
            $mqtt = new MqttClient(
                env('MQTT_HOST', 'mosquitto'),
                (int) env('MQTT_PORT', 1883),
                'laravel-config-' . uniqid()
            );
            $mqtt->connect((new ConnectionSettings)->setUsername(env("MQTT_USERNAME"))->setPassword(env("MQTT_PASSWORD")), true);
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
