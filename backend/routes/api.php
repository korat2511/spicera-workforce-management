<?php

use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\KioskDeviceController;
use App\Http\Controllers\Api\ShiftController;
use App\Http\Controllers\Api\StaffController;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'message' => 'API is running',
        'timestamp' => now()->toIso8601String(),
    ]);
});

Route::prefix('v1')->group(function (): void {
    Route::post('/auth/login', [AuthController::class, 'login']);

    // Kiosk-only: no Sanctum session, gated by the paired device token instead.
    Route::middleware('kiosk')->group(function (): void {
        Route::post('/attendance/punch', [AttendanceController::class, 'punch']);
    });

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::prefix('staff')->group(function (): void {
            Route::get('/', [StaffController::class, 'index']);
            Route::get('/{id}', [StaffController::class, 'show']);
            Route::post('/', [StaffController::class, 'store']);
            Route::match(['put', 'patch'], '/{id}', [StaffController::class, 'update']);
            Route::patch('/{id}/status', [StaffController::class, 'changeStatus']);
            Route::patch('/{id}/pin', [StaffController::class, 'setPin']);
            Route::patch('/{id}/shift', [StaffController::class, 'assignShift']);
        });

        Route::prefix('shifts')->group(function (): void {
            Route::get('/', [ShiftController::class, 'index']);
            Route::get('/{id}', [ShiftController::class, 'show']);
            Route::post('/', [ShiftController::class, 'store']);
            Route::match(['put', 'patch'], '/{id}', [ShiftController::class, 'update']);
            Route::patch('/{id}/status', [ShiftController::class, 'changeStatus']);
            Route::delete('/{id}', [ShiftController::class, 'destroy']);
        });

        Route::prefix('kiosk-devices')->group(function (): void {
            Route::get('/', [KioskDeviceController::class, 'index']);
            Route::post('/', [KioskDeviceController::class, 'store']);
            Route::delete('/{id}', [KioskDeviceController::class, 'destroy']);
        });

        Route::get('/attendance', [AttendanceController::class, 'index']);
    });
});
