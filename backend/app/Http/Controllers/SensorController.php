<?php

namespace App\Http\Controllers;

use App\Models\SensorData;
use App\Models\WaterFilling;
use Carbon\Carbon;
use Illuminate\Http\Request;

class SensorController extends Controller
{
    private function query(Request $r)
    {
        $q = SensorData::query();
        if ($r->filled('device')) $q->where('device', $r->device);
        if ($r->filled('from'))   $q->where('created_at', '>=', $r->from);
        if ($r->filled('to'))     $q->where('created_at', '<=', $r->to . ' 23:59:59');
        return $q->orderByDesc('created_at');
    }

    public function history(Request $r)
    {
        return $this->query($r)->paginate($r->integer('per_page', 50));
    }

    public function export(Request $r)
    {
        $rows = $this->query($r)->limit(10000)->get();

        return response()->streamDownload(function () use ($rows) {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['waktu_wib', 'device', 'level', 'suhu', 'debit']);
            foreach ($rows as $row) {
                $waktuWib = Carbon::parse(
                    $row->getRawOriginal('created_at'),
                    'UTC',
                )->setTimezone('Asia/Jakarta')->format('Y-m-d H:i:s');
                fputcsv($out, [$waktuWib, $row->device, $row->level, $row->suhu, $row->debit]);
            }
            fclose($out);
        }, 'history.csv', ['Content-Type' => 'text/csv']);
    }

    public function fillings(Request $request)
    {
        $validated = $request->validate([
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ]);

        return WaterFilling::query()
            ->orderByDesc('started_at')
            ->paginate($validated['per_page'] ?? 50);
    }
}
