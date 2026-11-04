<?php

namespace Tests\Feature;

use App\Models\SensorData;
use App\Models\SensorHourlyStat;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SensorStatsTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_aggregation_calculates_statistics_and_is_idempotent(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-11-03 14:30:00'));
        $this->createReading([
            'device' => 'd1',
            'level' => 10,
            'suhu' => 20,
            'debit' => 1,
        ], '2026-11-03 14:05:00');
        $this->createReading([
            'device' => 'd1',
            'level' => 30,
            'suhu' => null,
            'debit' => 3,
        ], '2026-11-03 14:45:00');
        $this->createReading([
            'device' => 'd2',
            'level' => 99,
            'suhu' => 40,
            'debit' => 8,
        ], '2026-11-03 14:10:00');

        $this->artisan('stats:aggregate', ['--hours' => 24])
            ->expectsOutput('Aggregated 2 hourly row(s).')
            ->assertExitCode(0);

        $this->assertDatabaseHas('sensor_hourly_stats', [
            'device' => 'd1',
            'hour_start' => '2026-11-03 14:00:00',
            'avg_level' => 20,
            'min_level' => 10,
            'max_level' => 30,
            'avg_suhu' => 20,
            'samples' => 2,
        ]);
        $this->assertDatabaseCount('sensor_hourly_stats', 2);

        $this->createReading([
            'device' => 'd1',
            'level' => 50,
            'suhu' => 30,
            'debit' => 5,
        ], '2026-11-03 14:55:00');

        $this->artisan('stats:aggregate', ['--hours' => 24])->assertExitCode(0);

        $this->assertDatabaseCount('sensor_hourly_stats', 2);
        $this->assertDatabaseHas('sensor_hourly_stats', [
            'device' => 'd1',
            'hour_start' => '2026-11-03 14:00:00',
            'avg_level' => 30,
            'max_level' => 50,
            'avg_suhu' => 25,
            'samples' => 3,
        ]);
    }

    public function test_stats_endpoint_requires_auth_and_valid_device(): void
    {
        $this->getJson('/api/stats?device=d1')->assertUnauthorized();

        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/stats?device=invalid')->assertUnprocessable();
    }

    public function test_authenticated_user_can_read_ordered_hourly_stats(): void
    {
        Sanctum::actingAs(User::factory()->create());
        SensorHourlyStat::create([
            'device' => 'd1',
            'hour_start' => now()->startOfHour()->subHour(),
            'avg_level' => 20,
            'min_level' => 10,
            'max_level' => 30,
            'samples' => 2,
        ]);
        SensorHourlyStat::create([
            'device' => 'd1',
            'hour_start' => now()->startOfHour(),
            'avg_level' => 40,
            'min_level' => 35,
            'max_level' => 45,
            'samples' => 3,
        ]);

        $this->getJson('/api/stats?device=d1&range=24h')
            ->assertOk()
            ->assertJsonPath('device', 'd1')
            ->assertJsonPath('range', '24h')
            ->assertJsonPath('points.0.avg_level', 20)
            ->assertJsonPath('points.1.avg_level', 40)
            ->assertJsonPath('summary.avg_level', 32)
            ->assertJsonStructure([
                'device',
                'range',
                'points' => [[
                    'hour',
                    'avg_level',
                    'min_level',
                    'max_level',
                    'avg_suhu',
                    'min_suhu',
                    'max_suhu',
                    'avg_debit',
                    'min_debit',
                    'max_debit',
                    'samples',
                ]],
                'summary' => [
                    'avg_level',
                    'min_level',
                    'max_level',
                    'avg_suhu',
                    'min_suhu',
                    'max_suhu',
                    'avg_debit',
                    'min_debit',
                    'max_debit',
                ],
            ]);
    }

    public function test_stats_summary_averages_are_weighted_by_valid_sample_counts(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-11-04 12:00:00'));
        Sanctum::actingAs(User::factory()->create());

        foreach ([
            [
                'avg_level' => 47.5,
                'avg_suhu' => 21,
                'avg_debit' => 4.5,
                'samples' => 2,
            ],
            [
                'avg_level' => 30,
                'avg_suhu' => 20,
                'avg_debit' => 3,
                'samples' => 1,
            ],
            [
                'avg_level' => 55,
                'avg_suhu' => 30,
                'avg_debit' => 5,
                'samples' => 1,
            ],
            [
                'avg_level' => 70,
                'avg_suhu' => 50,
                'avg_debit' => 7,
                'samples' => 1,
            ],
            [
                'avg_level' => null,
                'avg_suhu' => null,
                'avg_debit' => null,
                'samples' => 10,
            ],
        ] as $index => $averages) {
            SensorHourlyStat::create([
                'device' => 'd1',
                'hour_start' => now()->startOfHour()->subHours($index),
                ...$averages,
            ]);
        }

        $this->getJson('/api/stats?device=d1&range=24h')
            ->assertOk()
            ->assertJsonPath('summary.avg_level', 50)
            ->assertJsonPath('summary.avg_suhu', 28.4)
            ->assertJsonPath('summary.avg_debit', 4.8);
    }

    private function createReading(array $attributes, string $createdAt): void
    {
        SensorData::create($attributes)
            ->forceFill(['created_at' => $createdAt])
            ->save();
    }
}
