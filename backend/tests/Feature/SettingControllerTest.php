<?php

namespace Tests\Feature;

use App\Http\Controllers\SettingController;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SettingControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_settings_are_published_with_retained_config_fields_on_every_save(): void
    {
        $controller = new class extends SettingController
        {
            public array $publishedMessages = [];

            protected function publishMessage(string $topic, string $message, int $qos, bool $retained): void
            {
                $this->publishedMessages[] = [
                    'topic' => $topic,
                    'payload' => json_decode($message, true),
                    'qos' => $qos,
                    'retained' => $retained,
                ];
            }
        };
        $this->app->instance(SettingController::class, $controller);
        Sanctum::actingAs(User::factory()->create(['role' => 'admin']));

        $this->putJson('/api/settings', [
            'batas_air' => 35,
            'batas_suhu' => 32,
            'batas_debit' => 2.4,
            'capacity_liters' => 1500,
            'pump_on_level' => 20,
            'pump_off_level' => 90,
            'automatic_pump' => false,
        ])->assertOk();

        $this->assertSame([
            'topic' => 'tandon/config',
            'payload' => [
                'batas_air' => 35,
                'batas_suhu' => 32,
                'batas_debit' => 2.4,
                'capacity_liters' => 1500,
                'pump_on_level' => 20,
                'pump_off_level' => 90,
                'automatic_pump' => false,
            ],
            'qos' => 0,
            'retained' => true,
        ], $controller->publishedMessages[0]);

        $this->putJson('/api/settings', ['capacity_liters' => 1600])->assertOk();

        $this->assertCount(2, $controller->publishedMessages);
        $this->assertSame(
            1600,
            $controller->publishedMessages[1]['payload']['capacity_liters'],
        );
    }
}
