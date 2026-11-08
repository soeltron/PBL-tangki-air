<?php

namespace App\Console\Commands;

use App\Models\SensorData;
use App\Services\WaterFillingTracker;
use Illuminate\Console\Command;

class SeedDemo extends Command
{
    protected $signature = 'app:seed-demo {--hours=48}';

    protected $description = 'Add synthetic sensor data for demonstration';

    public function handle(): int
    {
        $hours = filter_var($this->option('hours'), FILTER_VALIDATE_INT);
        if ($hours === false || $hours < 1) {
            $this->error('The --hours option must be a positive integer.');

            return self::FAILURE;
        }

        if (!$this->confirm('This will add synthetic sensor data and aggregate stats. Continue?')) {
            $this->info('No data was written.');

            return self::SUCCESS;
        }

        $end = now();
        $start = $end->copy()->startOfHour()->subHours($hours - 1);
        $sampleCount = 0;
        $tick = 0;
        $tracker = app(WaterFillingTracker::class);

        for ($timestamp = $start->copy(); $timestamp <= $end; $timestamp->addMinutes(5)) {
            $cyclePosition = $tick % 36;
            $cycleProgress = $cyclePosition % 18;
            $pumpOn = $cyclePosition >= 18;
            $level = $pumpOn
                ? 25 + ($cycleProgress / 17 * 60)
                : 85 - ($cycleProgress / 17 * 60);
            $temperature = 25 + (1.5 * sin(2 * M_PI * $tick / 288));
            $debit = $pumpOn
                ? 1.2 + (0.3 * sin(2 * M_PI * $tick / 36))
                : 0.1;
            $createdAt = $timestamp->toDateTimeString();

            $debitReading = new SensorData([
                'device' => 'd2',
                'debit' => $debit,
            ]);
            $debitReading->forceFill([
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ])->save();
            $tracker->record($debitReading, null);

            $levelReading = new SensorData([
                'device' => 'd1',
                'level' => $level,
                'suhu' => $temperature,
                'pompa' => $pumpOn,
            ]);
            $levelReading->forceFill([
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ])->save();
            $tracker->record($levelReading, null);

            $sampleCount += 2;
            $tick++;
        }

        $this->info("Added {$sampleCount} synthetic sensor reading(s).");
        if ($this->call('stats:aggregate', ['--hours' => $hours]) !== self::SUCCESS) {
            return self::FAILURE;
        }

        return self::SUCCESS;
    }
}
