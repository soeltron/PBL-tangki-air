<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    protected $fillable = [
        'batas_air',
        'batas_suhu',
        'batas_debit',
        'capacity_liters',
        'pump_on_level',
        'pump_off_level',
        'automatic_pump',
    ];

    protected function casts(): array
    {
        return [
            'automatic_pump' => 'boolean',
        ];
    }
}
