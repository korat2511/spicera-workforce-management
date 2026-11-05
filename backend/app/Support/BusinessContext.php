<?php

namespace App\Support;

use App\Models\Business;

class BusinessContext
{
    /**
     * Resolve the business that the current request operates on.
     *
     * Phase 1 has no authentication yet, so this always returns the single
     * seeded business. Phase 2 (Authentication & Business) will change only
     * this method's internals to resolve the business from the
     * authenticated Sanctum user — callers (controllers/services) do not
     * need to change.
     */
    public static function resolve(): Business
    {
        return Business::firstOrFail();
    }
}
