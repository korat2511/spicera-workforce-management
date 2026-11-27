<?php

namespace App\Support;

use App\Models\Business;
use App\Models\KioskDevice;

class BusinessContext
{
    /**
     * Resolve the business that the current request operates on.
     *
     * Resolves from the authenticated Sanctum user's business first, then
     * from a paired kiosk device (see ResolveKioskDevice middleware) for
     * unauthenticated kiosk requests, falling back to the single seeded
     * business otherwise.
     */
    public static function resolve(): Business
    {
        $user = request()->user();

        if ($user?->business) {
            return $user->business;
        }

        /** @var KioskDevice|null $device */
        $device = request()->attributes->get('kioskDevice');

        return $device?->business ?? Business::firstOrFail();
    }
}
