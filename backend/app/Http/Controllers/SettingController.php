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
        if ($isAdmin) {
            $this->publish($s);
        }

        return response()->json($s);
    }

    protected function publish(Setting $s): void
    {
        $this->publishMessage(
            'tandon/config',
            json_encode($this->configPayload($s)),
            0,
            true,
        );
    }

    protected function publishMessage(string $topic, string $message, int $qos, bool $retained): void
    {
        try {
            $mqtt = new MqttClient(
                env('MQTT_HOST', 'mosquitto'),
                (int) env('MQTT_PORT', 1883),
                'laravel-config-' . uniqid()
            );
            $mqtt->connect((new ConnectionSettings)->setUsername(env("MQTT_USERNAME"))->setPassword(env("MQTT_PASSWORD")), true);
            $mqtt->publish($topic, $message, $qos, $retained);
            $mqtt->disconnect();
        } catch (\Throwable $e) {
            report($e);
        }
    }

    protected function configPayload(Setting $s): array
    {
        return [
            'batas_air' => (float) $s->batas_air,
            'batas_suhu' => (float) $s->batas_suhu,
            'batas_debit' => (float) $s->batas_debit,
            'capacity_liters' => (float) $s->capacity_liters,
            'pump_on_level' => (float) $s->pump_on_level,
            'pump_off_level' => (float) $s->pump_off_level,
            'automatic_pump' => (bool) $s->automatic_pump,
        ];
    }
}
