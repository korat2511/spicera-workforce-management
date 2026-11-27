<?php

namespace App\Http\Middleware;

use App\Models\KioskDevice;
use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ResolveKioskDevice
{
    /**
     * Handle an incoming request.
     *
     * Resolves the paired kiosk device from the `X-Kiosk-Token` header and
     * attaches it to the request so `BusinessContext::resolve()` can find
     * the right business without a logged-in user. Routes using this
     * middleware have no Sanctum auth — the device token is the only gate.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->header('X-Kiosk-Token');

        if (! $token) {
            return ApiResponse::error('Missing kiosk device token', 401);
        }

        $device = KioskDevice::findByToken($token);

        if (! $device || $device->isRevoked()) {
            return ApiResponse::error('Invalid or revoked kiosk device', 401);
        }

        $device->update(['last_seen_at' => now()]);
        $request->attributes->set('kioskDevice', $device);

        return $next($request);
    }
}
