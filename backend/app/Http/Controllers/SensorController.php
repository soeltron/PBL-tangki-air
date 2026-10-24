<?php

namespace App\Http\Controllers;

use App\Models\SensorData;
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
            fputcsv($out, ['waktu', 'device', 'level', 'suhu', 'debit']);
            foreach ($rows as $row) {
                fputcsv($out, [$row->created_at, $row->device, $row->level, $row->suhu, $row->debit]);
            }
            fclose($out);
        }, 'history.csv', ['Content-Type' => 'text/csv']);
    }
}
