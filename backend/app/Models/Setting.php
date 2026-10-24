<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    protected $fillable = ['batas_air', 'batas_suhu', 'batas_debit'];
}
