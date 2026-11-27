<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RegisterKioskDeviceRequest;
use App\Http\Resources\KioskDeviceResource;
use App\Models\KioskDevice;
use App\Support\ApiResponse;
use App\Support\BusinessContext;
use Illuminate\Http\JsonResponse;

class KioskDeviceController extends Controller
{
    public function index(): JsonResponse
    {
        $business = BusinessContext::resolve();

        $devices = KioskDevice::where('business_id', $business->id)
            ->orderByDesc('created_at')
            ->get();

        return ApiResponse::success(
            KioskDeviceResource::collection($devices),
            'Kiosk devices retrieved successfully',
        );
    }

    public function store(RegisterKioskDeviceRequest $request): JsonResponse
    {
        $business = BusinessContext::resolve();
        $token = KioskDevice::generateToken();

        $device = KioskDevice::create([
            'business_id' => $business->id,
            'name' => $request->validated('name'),
            'platform' => $request->validated('platform'),
            'model' => $request->validated('model'),
            'token_hash' => KioskDevice::hashToken($token),
        ]);

        return ApiResponse::success([
            'device' => new KioskDeviceResource($device),
            // Only ever returned here — not retrievable again afterwards.
            'token' => $token,
        ], 'Kiosk device registered successfully', 201);
    }

    public function destroy(int $id): JsonResponse
    {
        $business = BusinessContext::resolve();
        $device = KioskDevice::where('business_id', $business->id)->findOrFail($id);
        $device->update(['revoked_at' => now()]);

        return ApiResponse::success(null, 'Kiosk device revoked successfully');
    }
}
