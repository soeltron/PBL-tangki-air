<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SensorHourlyStat extends Model
{
    protected $fillable = [
        'device',
        'hour_start',
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
    ];

    protected function casts(): array
    {
        return [
            'hour_start' => 'datetime',
            'avg_level' => 'float',
            'min_level' => 'float',
            'max_level' => 'float',
            'avg_suhu' => 'float',
            'min_suhu' => 'float',
            'max_suhu' => 'float',
            'avg_debit' => 'float',
            'min_debit' => 'float',
            'max_debit' => 'float',
            'samples' => 'integer',
        ];
    }
}
