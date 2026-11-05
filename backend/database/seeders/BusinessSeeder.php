<?php

namespace Database\Seeders;

use App\Models\Business;
use Illuminate\Database\Seeder;

class BusinessSeeder extends Seeder
{
    /**
     * Seed the single business Phase 1 operates against (see
     * App\Support\BusinessContext). Placeholder fields like owner_name and
     * phone are meant to be edited later via the Phase 2 business profile
     * API, once authentication exists.
     */
    public function run(): void
    {
        Business::firstOrCreate(
            ['business_name' => 'JK Dhosa House'],
            [
                'owner_name' => 'Owner',
                'email' => null,
                'phone' => '+61400000000',
                'country' => 'Australia',
                'currency' => 'AUD',
                'timezone' => 'Australia/Sydney',
            ]
        );
    }
}
