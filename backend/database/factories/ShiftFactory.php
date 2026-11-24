<?php

namespace Database\Factories;

use App\Models\Business;
use App\Models\Shift;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Shift>
 */
class ShiftFactory extends Factory
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
            'name' => fake()->randomElement(['Morning Shift', 'Evening Shift', 'Night Shift']),
            'shift_type' => fake()->randomElement(['REGULAR', 'PEAK DINNER', 'SNACKS & PREP']),
            'description' => fake()->sentence(),
            'start_time' => '08:00',
            'end_time' => '16:00',
            'status' => 'active',
            'break_duration_minutes' => 15,
            'grace_period_minutes' => 10,
            'scheduled_days' => [1, 2, 3, 4, 5, 6, 7],
        ];
    }
}
