<?php

namespace Tests\Feature;

use App\Console\Commands\MqttListen;
use App\Models\WaterFilling;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MqttListenTest extends TestCase
{
    use RefreshDatabase;

    public function test_mqtt_sensor_messages_are_recorded_as_water_fillings(): void
    {
        $listener = app(MqttListen::class);

        $listener->processMessage(json_encode([
            'device' => 'd2',
            'debit' => 1.2,
        ]));
        $listener->processMessage(json_encode([
            'device' => 'd1',
            'level' => 15,
            'suhu' => 25,
            'pompa' => true,
        ]));
        $listener->processMessage(json_encode([
            'device' => 'd2',
            'debit' => 1.5,
        ]));
        $listener->processMessage(json_encode([
            'device' => 'd1',
            'level' => 80,
            'suhu' => 26,
            'pompa' => false,
        ]));

        $this->assertDatabaseCount('water_fillings', 1);
        $this->assertNotNull(WaterFilling::firstOrFail()->ended_at);
    }
}
