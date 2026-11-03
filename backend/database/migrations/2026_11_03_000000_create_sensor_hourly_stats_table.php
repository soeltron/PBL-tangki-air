<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sensor_hourly_stats', function (Blueprint $table) {
            $table->id();
            $table->string('device', 20);
            $table->dateTime('hour_start');
            $table->double('avg_level')->nullable();
            $table->double('min_level')->nullable();
            $table->double('max_level')->nullable();
            $table->double('avg_suhu')->nullable();
            $table->double('min_suhu')->nullable();
            $table->double('max_suhu')->nullable();
            $table->double('avg_debit')->nullable();
            $table->double('min_debit')->nullable();
            $table->double('max_debit')->nullable();
            $table->unsignedInteger('samples');
            $table->timestamps();

            $table->unique(['device', 'hour_start']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sensor_hourly_stats');
    }
};
