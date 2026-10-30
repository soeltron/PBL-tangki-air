<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('user');
            $table->timestamp('last_login_at')->nullable();
        });

        Schema::table('settings', function (Blueprint $table) {
            $table->float('capacity_liters')->default(1000);
            $table->float('pump_on_level')->default(30);
            $table->float('pump_off_level')->default(95);
            $table->boolean('automatic_pump')->default(true);
        });

        Schema::table('sensor_data', function (Blueprint $table) {
            $table->boolean('pompa')->nullable();
        });

        DB::table('settings')->update([
            'pump_on_level' => DB::raw('batas_air'),
        ]);

        Schema::create('water_fillings', function (Blueprint $table) {
            $table->id();
            $table->timestamp('started_at')->index();
            $table->timestamp('ended_at')->nullable()->index();
            $table->float('start_level')->nullable();
            $table->float('end_level')->nullable();
            $table->float('start_suhu')->nullable();
            $table->float('end_suhu')->nullable();
            $table->float('start_debit')->nullable();
            $table->float('end_debit')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('water_fillings');

        Schema::table('sensor_data', function (Blueprint $table) {
            $table->dropColumn('pompa');
        });

        Schema::table('settings', function (Blueprint $table) {
            $table->dropColumn([
                'capacity_liters',
                'pump_on_level',
                'pump_off_level',
                'automatic_pump',
            ]);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['role', 'last_login_at']);
        });
    }
};
