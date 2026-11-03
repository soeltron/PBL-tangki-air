<?php

namespace App\Http\Controllers;

use App\Models\SensorHourlyStat;
use Illuminate\Http\Request;

class StatsController extends Controller
{
    public function index(Request $request)
    {
        $validated = $request->validate([
            'device' => ['required', 'in:d1,d2'],
            'range' => ['sometimes', 'in:24h,7d'],
        ]);
        $range = $validated['range'] ?? '24h';
        $hours = $range === '7d' ? 168 : 24;
        $currentHour = now()->startOfHour();
        $from = $currentHour->copy()->subHours($hours - 1);

        $stats = SensorHourlyStat::query()
            ->where('device', $validated['device'])
            ->whereBetween('hour_start', [$from, $currentHour])
            ->orderBy('hour_start')
            ->get();

        $fields = [
            'level' => ['avg_level', 'min_level', 'max_level'],
            'suhu' => ['avg_suhu', 'min_suhu', 'max_suhu'],
            'debit' => ['avg_debit', 'min_debit', 'max_debit'],
        ];
        $summary = [];

        foreach ($fields as $field => [$average, $minimum, $maximum]) {
            $summary[$average] = $stats->whereNotNull($average)->avg($average);
            $summary[$minimum] = $stats->whereNotNull($minimum)->min($minimum);
            $summary[$maximum] = $stats->whereNotNull($maximum)->max($maximum);
        }

        return response()->json([
            'device' => $validated['device'],
            'range' => $range,
            'points' => $stats->map(fn (SensorHourlyStat $stat) => [
                'hour' => $stat->hour_start->toDateTimeString(),
                'avg_level' => $stat->avg_level,
                'min_level' => $stat->min_level,
                'max_level' => $stat->max_level,
                'avg_suhu' => $stat->avg_suhu,
                'min_suhu' => $stat->min_suhu,
                'max_suhu' => $stat->max_suhu,
                'avg_debit' => $stat->avg_debit,
                'min_debit' => $stat->min_debit,
                'max_debit' => $stat->max_debit,
                'samples' => $stat->samples,
            ])->values(),
            'summary' => $summary,
        ]);
    }
}
