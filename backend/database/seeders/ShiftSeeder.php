<?php

namespace Database\Seeders;

use App\Models\Shift;
use App\Support\BusinessContext;
use Illuminate\Database\Seeder;

class ShiftSeeder extends Seeder
{
    /**
     * Seed the default shifts the single Phase 1 business operates with.
     */
    public function run(): void
    {
        $business = BusinessContext::resolve();

        $defaults = [
            [
                'name' => 'Morning Shift',
                'start_time' => '08:00',
                'end_time' => '16:00',
                'shift_type' => 'REGULAR',
                'description' => 'Breakfast & lunch rush operations',
                'status' => 'active',
                'break_duration_minutes' => 15,
                'grace_period_minutes' => 10,
                'scheduled_days' => [1, 2, 3, 4, 5, 6, 7],
            ],
            [
                'name' => 'Evening Shift',
                'start_time' => '16:00',
                'end_time' => '00:00',
                'shift_type' => 'PEAK DINNER',
                'description' => 'High volume dinner & family dining',
                'status' => 'active',
                'break_duration_minutes' => 15,
                'grace_period_minutes' => 10,
                'scheduled_days' => [1, 2, 3, 4, 5, 6, 7],
            ],
            [
                'name' => 'Night Shift',
                'start_time' => '00:00',
                'end_time' => '08:00',
                'shift_type' => 'OVERNIGHT',
                'description' => 'Overnight security & prep slot',
                'status' => 'inactive',
                'break_duration_minutes' => 15,
                'grace_period_minutes' => 5,
                'scheduled_days' => [1, 2, 3, 4, 5, 6],
            ],
        ];

        foreach ($defaults as $shift) {
            Shift::updateOrCreate(
                ['business_id' => $business->id, 'name' => $shift['name']],
                $shift,
            );
        }
    }
}
