<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SensorData extends Model
{
    protected $table = 'sensor_data';
    protected $fillable = ['device', 'level', 'suhu', 'debit', 'pompa'];

    protected function casts(): array
    {
        return ['pompa' => 'boolean'];
    }
}
