<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\AdminUserController;
use App\Http\Controllers\SensorController;
use App\Http\Controllers\SettingController;
use App\Http\Controllers\StatsController;
use App\Http\Middleware\EnsureAdmin;
use App\Models\SensorData;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/register', [AuthController::class, 'register'])
        ->middleware(EnsureAdmin::class);

    Route::get('/data/{device}', fn ($device) =>
        SensorData::where('device', $device)->latest()->limit(50)->get());

    Route::get('/latest', fn () => [
        'd1' => SensorData::where('device', 'd1')->latest()->first(),
        'd2' => SensorData::where('device', 'd2')->latest()->first(),
    ]);

    Route::get('/history', [SensorController::class, 'history']);
    Route::get('/history/fillings', [SensorController::class, 'fillings']);
    Route::get('/history/export', [SensorController::class, 'export']);
    Route::get('/stats', [StatsController::class, 'index']);

    Route::get('/settings', [SettingController::class, 'show']);
    Route::put('/settings', [SettingController::class, 'update']);

    Route::middleware(EnsureAdmin::class)->prefix('admin')->group(function () {
        Route::get('/users', [AdminUserController::class, 'index']);
        Route::post('/users', [AdminUserController::class, 'store']);
        Route::put('/users/{user}', [AdminUserController::class, 'update']);
        Route::delete('/users/{user}', [AdminUserController::class, 'destroy']);
    });
});
