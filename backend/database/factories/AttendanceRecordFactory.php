<?php

namespace Database\Factories;

use App\Models\AttendanceRecord;
use App\Models\Business;
use App\Models\Staff;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AttendanceRecord>
 */
class AttendanceRecordFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'business_id' => Business::factory(),
            'staff_id' => Staff::factory(),
            'shift_id' => null,
            'kiosk_device_id' => null,
            'type' => AttendanceRecord::TYPE_CHECK_IN,
            'recorded_at' => now(),
            'photo_path' => null,
            'status' => null,
        ];
    }
}
