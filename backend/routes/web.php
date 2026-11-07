<?php

use App\Http\Controllers\AdminUserController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\SensorController;
use App\Http\Controllers\SettingController;
use App\Http\Controllers\StatsController;
use App\Http\Controllers\WebAuthController;
use App\Http\Middleware\EnsureAdmin;
use App\Models\SensorData;
use Illuminate\Support\Facades\Route;

Route::get('/login', [WebAuthController::class, 'create'])->name('login');
Route::post('/login', [WebAuthController::class, 'store'])
    ->middleware('throttle:5,1')
    ->name('login.store');
Route::post('/logout', [WebAuthController::class, 'destroy'])
    ->middleware('auth:web')
    ->name('logout');

Route::middleware('auth:web')->group(function () {
    Route::get('/', fn () => redirect()->route('dashboard'));
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard/users', [DashboardController::class, 'users'])
        ->middleware(EnsureAdmin::class)
        ->name('dashboard.users');

    Route::prefix('/dashboard/data')->group(function () {
        Route::get('/latest', fn () => response()->json([
            'd1' => SensorData::where('device', 'd1')->latest()->first(),
            'd2' => SensorData::where('device', 'd2')->latest()->first(),
        ]));
        Route::get('/stats', [StatsController::class, 'index']);
        Route::get('/history', [SensorController::class, 'history']);
        Route::get('/history/export', [SensorController::class, 'export']);
        Route::get('/fillings', [SensorController::class, 'fillings']);
        Route::get('/settings', [SettingController::class, 'show']);
        Route::put('/settings', [SettingController::class, 'update']);

        Route::middleware(EnsureAdmin::class)->prefix('/users')->group(function () {
            Route::get('/', [AdminUserController::class, 'index']);
            Route::post('/', [AdminUserController::class, 'store']);
            Route::put('/{user}', [AdminUserController::class, 'update']);
            Route::delete('/{user}', [AdminUserController::class, 'destroy']);
        });
    });
});
