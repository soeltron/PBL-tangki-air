<?php

namespace App\Services;

use App\Models\SensorData;
use App\Models\WaterFilling;
use Illuminate\Support\Facades\DB;

class WaterFillingTracker
{
    public function record(SensorData $sensor, ?bool $pumpOn): void
    {
        if ($sensor->device === 'd1' && $pumpOn !== null) {
            $this->recordPumpState($sensor, $pumpOn);

            return;
        }

        if ($sensor->device === 'd2') {
            WaterFilling::query()
                ->whereNull('ended_at')
                ->latest('started_at')
                ->first()
                ?->update(['end_debit' => $sensor->debit]);
        }
    }

    private function recordPumpState(SensorData $sensor, bool $pumpOn): void
    {
        DB::transaction(function () use ($sensor, $pumpOn): void {
            $flow = SensorData::query()
                ->where('device', 'd2')
                ->orderByDesc('id')
                ->value('debit');
            $filling = WaterFilling::query()
                ->whereNull('ended_at')
                ->lockForUpdate()
                ->latest('started_at')
                ->first();

            if ($pumpOn) {
                if (!$filling) {
                    $filling = new WaterFilling([
                        'started_at' => $sensor->created_at,
                        'start_level' => $sensor->level,
                        'start_suhu' => $sensor->suhu,
                        'start_debit' => $flow,
                    ]);
                }

                $filling->end_level = $sensor->level;
                $filling->end_suhu = $sensor->suhu;
                $filling->end_debit = $flow;
                $filling->save();
            } elseif ($filling) {
                $filling->ended_at = $sensor->created_at;
                $filling->end_level = $sensor->level;
                $filling->end_suhu = $sensor->suhu;
                $filling->end_debit = $flow;
                $filling->save();
            }
        });
    }
}
