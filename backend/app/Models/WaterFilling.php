<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WaterFilling extends Model
{
    protected $fillable = [
        'started_at',
        'ended_at',
        'start_level',
        'end_level',
        'start_suhu',
        'end_suhu',
        'start_debit',
        'end_debit',
    ];

    protected function casts(): array
    {
        return [
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
        ];
    }
}
