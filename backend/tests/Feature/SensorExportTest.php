<?php

namespace Tests\Feature;

use App\Models\SensorData;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SensorExportTest extends TestCase
{
    use RefreshDatabase;

    public function test_history_export_formats_created_at_as_wib(): void
    {
        Sanctum::actingAs(User::factory()->create());

        SensorData::create([
            'device' => 'd1',
            'level' => 42.5,
            'suhu' => 21.5,
            'debit' => 2.4,
        ])->forceFill(['created_at' => '2026-11-08 14:43:36'])->save();

        $csv = $this->get('/api/history/export')
            ->assertOk()
            ->streamedContent();

        $lines = array_map('str_getcsv', explode("\n", trim($csv)));

        $this->assertSame(
            ['waktu_wib', 'device', 'level', 'suhu', 'debit'],
            $lines[0],
        );
        $this->assertSame(
            ['2026-11-08 21:43:36', 'd1', '42.5', '21.5', '2.4'],
            $lines[1],
        );
    }
}
