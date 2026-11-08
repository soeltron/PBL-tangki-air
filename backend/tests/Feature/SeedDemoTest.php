<?php

namespace Tests\Feature;

use App\Models\SensorData;
use App\Models\SensorHourlyStat;
use App\Models\WaterFilling;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SeedDemoTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_demo_command_adds_synthetic_readings_and_aggregates_without_deleting_existing_data(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-11-08 14:30:00'));
        $existing = SensorData::create([
            'device' => 'd1',
            'level' => 50,
            'suhu' => 25,
            'pompa' => false,
        ]);
        $existing->forceFill([
            'created_at' => now()->subDay(),
            'updated_at' => now()->subDay(),
        ])->save();

        $this->artisan('app:seed-demo', ['--hours' => 1])
            ->expectsConfirmation(
                'This will add synthetic sensor data and aggregate stats. Continue?',
                'yes',
            )
            ->expectsOutput('Added 14 synthetic sensor reading(s).')
            ->expectsOutput('Aggregated 2 hourly row(s).')
            ->assertExitCode(0);

        $this->assertDatabaseCount('sensor_data', 15);
        $this->assertDatabaseHas('sensor_data', [
            'id' => $existing->id,
            'device' => 'd1',
            'level' => 50,
        ]);
        $this->assertDatabaseCount('sensor_hourly_stats', 2);
        $this->assertSame(7, SensorHourlyStat::where('device', 'd1')->firstOrFail()->samples);
        $this->assertSame(7, SensorHourlyStat::where('device', 'd2')->firstOrFail()->samples);
    }

    public function test_demo_command_does_not_write_when_confirmation_is_declined(): void
    {
        $this->artisan('app:seed-demo', ['--hours' => 1])
            ->expectsConfirmation(
                'This will add synthetic sensor data and aggregate stats. Continue?',
                'no',
            )
            ->expectsOutput('No data was written.')
            ->assertExitCode(0);

        $this->assertDatabaseCount('sensor_data', 0);
        $this->assertDatabaseCount('sensor_hourly_stats', 0);
    }

    public function test_demo_command_creates_complete_fillings_from_pump_cycles(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-11-08 14:30:00'));

        $this->artisan('app:seed-demo', ['--hours' => 8])
            ->expectsConfirmation(
                'This will add synthetic sensor data and aggregate stats. Continue?',
                'yes',
            )
            ->expectsOutput('Added 182 synthetic sensor reading(s).')
            ->expectsOutput('Aggregated 16 hourly row(s).')
            ->assertExitCode(0);

        $this->assertDatabaseCount('sensor_data', 182);
        $fillings = WaterFilling::whereNotNull('ended_at')->get();
        $this->assertCount(2, $fillings);

        foreach ($fillings as $filling) {
            $this->assertNotNull($filling->started_at);
            $this->assertNotNull($filling->ended_at);
            $this->assertNotNull($filling->start_level);
            $this->assertNotNull($filling->end_level);
            $this->assertNotNull($filling->start_suhu);
            $this->assertNotNull($filling->end_suhu);
            $this->assertNotNull($filling->start_debit);
            $this->assertNotNull($filling->end_debit);
        }
    }
}
