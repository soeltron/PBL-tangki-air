<?php

namespace App\Console\Commands;

use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class AggregateSensorStats extends Command
{
    protected $signature = 'stats:aggregate {--hours=24}';

    protected $description = 'Aggregate sensor readings into hourly statistics';

    public function handle(): int
    {
        $hours = filter_var($this->option('hours'), FILTER_VALIDATE_INT);
        if ($hours === false || $hours < 1) {
            $this->error('The --hours option must be a positive integer.');

            return self::FAILURE;
        }

        $currentHour = now()->startOfHour();
        $from = $currentHour->copy()->subHours($hours - 1);
        $driver = DB::connection()->getDriverName();
        $hourExpression = match ($driver) {
            'sqlite' => "strftime('%Y-%m-%d %H:00:00', created_at)",
            default => "DATE_FORMAT(created_at, '%Y-%m-%d %H:00:00')",
        };

        $rows = DB::table('sensor_data')
            ->where('created_at', '>=', $from)
            ->where('created_at', '<', $currentHour->copy()->addHour())
            ->selectRaw("$hourExpression as hour_start")
            ->addSelect('device')
            ->selectRaw('AVG(level) as avg_level, MIN(level) as min_level, MAX(level) as max_level')
            ->selectRaw('AVG(suhu) as avg_suhu, MIN(suhu) as min_suhu, MAX(suhu) as max_suhu')
            ->selectRaw('AVG(debit) as avg_debit, MIN(debit) as min_debit, MAX(debit) as max_debit')
            ->selectRaw('COUNT(*) as samples')
            ->groupBy('device')
            ->groupByRaw($hourExpression)
            ->get();

        if ($rows->isNotEmpty()) {
            $now = Carbon::now();
            $values = $rows->map(fn (object $row) => [
                'device' => $row->device,
                'hour_start' => $row->hour_start,
                'avg_level' => $row->avg_level,
                'min_level' => $row->min_level,
                'max_level' => $row->max_level,
                'avg_suhu' => $row->avg_suhu,
                'min_suhu' => $row->min_suhu,
                'max_suhu' => $row->max_suhu,
                'avg_debit' => $row->avg_debit,
                'min_debit' => $row->min_debit,
                'max_debit' => $row->max_debit,
                'samples' => $row->samples,
                'created_at' => $now,
                'updated_at' => $now,
            ])->all();

            DB::table('sensor_hourly_stats')->upsert(
                $values,
                ['device', 'hour_start'],
                [
                    'avg_level', 'min_level', 'max_level',
                    'avg_suhu', 'min_suhu', 'max_suhu',
                    'avg_debit', 'min_debit', 'max_debit',
                    'samples', 'updated_at',
                ],
            );
        }

        $this->info("Aggregated {$rows->count()} hourly row(s).");

        return self::SUCCESS;
    }
}
