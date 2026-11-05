<?php

namespace Database\Seeders;

use App\Models\Staff;
use App\Services\StaffService;
use App\Support\BusinessContext;
use Illuminate\Database\Seeder;

class StaffSeeder extends Seeder
{
    /**
     * Seed a handful of sample staff for local testing/Postman. Not run as
     * part of the production deploy instructions.
     */
    public function run(): void
    {
        $business = BusinessContext::resolve();
        $staffService = app(StaffService::class);

        for ($i = 0; $i < 8; $i++) {
            Staff::factory()->for($business)->create([
                'staff_code' => $staffService->generateStaffCode($business),
            ]);
        }

        for ($i = 0; $i < 2; $i++) {
            Staff::factory()->inactive()->for($business)->create([
                'staff_code' => $staffService->generateStaffCode($business),
            ]);
        }
    }
}
