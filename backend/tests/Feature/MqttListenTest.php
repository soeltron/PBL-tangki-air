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

    public function test_invalid_mqtt_payloads_are_not_recorded(): void
    {
        $listener = app(MqttListen::class);
        $invalidMessages = [
            '{invalid json',
            'null',
            '[]',
            '"d1"',
            '{}',
            '{"device":"d1","pompa":true}',
            '{"device":"d1","level":20}',
            '{"device":"d3","level":20,"pompa":true}',
            '{"device":"d1-extra","level":20,"pompa":true}',
            '{"device":"d1","level":"high","pompa":true}',
            '{"device":"d1","level":-1,"pompa":true}',
            '{"device":"d1","level":101,"pompa":true}',
            '{"device":"d1","level":20,"pompa":1}',
            '{"device":"d1","level":20,"pompa":"true"}',
        ];

        foreach ($invalidMessages as $message) {
            $this->assertNull($listener->processMessage($message), $message);
        }

        $this->assertDatabaseCount('sensor_data', 0);
        $this->assertDatabaseCount('water_fillings', 0);
    }

    public function test_valid_d2_message_is_recorded_without_d1_fields(): void
    {
        $listener = app(MqttListen::class);

        $sensorData = $listener->processMessage('{"device":"d2","debit":2.4}');

        $this->assertNotNull($sensorData);
        $this->assertSame('d2', $sensorData->device);
        $this->assertEquals(2.4, $sensorData->debit);
        $this->assertDatabaseCount('sensor_data', 1);
    }

    public function test_d2_message_without_debit_is_not_recorded(): void
    {
        $listener = app(MqttListen::class);

        $this->assertNull($listener->processMessage('{"device":"d2"}'));
        $this->assertDatabaseCount('sensor_data', 0);
    }
}
