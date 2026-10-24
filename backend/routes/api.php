<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\SensorController;
use App\Http\Controllers\SettingController;
use App\Models\SensorData;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/data/{device}', fn ($device) =>
        SensorData::where('device', $device)->latest()->limit(50)->get());

    Route::get('/latest', fn () => [
        'd1' => SensorData::where('device', 'd1')->latest()->first(),
        'd2' => SensorData::where('device', 'd2')->latest()->first(),
    ]);

    Route::get('/history', [SensorController::class, 'history']);
    Route::get('/history/export', [SensorController::class, 'export']);

    Route::get('/settings', [SettingController::class, 'show']);
    Route::put('/settings', [SettingController::class, 'update']);
});
