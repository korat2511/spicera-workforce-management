<?php

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
    // No auth:sanctum middleware yet — Phase 1 has no authentication.
    // Phase 2 adds it here without changing the route shape.
    Route::prefix('staff')->group(function (): void {
        Route::get('/', [StaffController::class, 'index']);
        Route::get('/{id}', [StaffController::class, 'show']);
        Route::post('/', [StaffController::class, 'store']);
        Route::match(['put', 'patch'], '/{id}', [StaffController::class, 'update']);
        Route::patch('/{id}/status', [StaffController::class, 'changeStatus']);
    });
});
