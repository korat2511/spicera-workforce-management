<?php

namespace Database\Factories;

use App\Models\Business;
use App\Models\Staff;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Staff>
 */
class StaffFactory extends Factory
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
            'staff_code' => strtoupper(fake()->unique()->bothify('STF###')),
            'first_name' => fake()->firstName(),
            'last_name' => fake()->lastName(),
            'email' => fake()->boolean(80) ? fake()->unique()->safeEmail() : null,
            'phone' => '04'.fake()->numerify('########'),
            'date_of_birth' => fake()->boolean(70) ? fake()->date() : null,
            'gender' => fake()->boolean(50) ? fake()->randomElement(['Male', 'Female', 'Other']) : null,
            'street_address' => fake()->streetAddress(),
            'suburb' => fake()->city(),
            'state' => fake()->randomElement(['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT']),
            'postcode' => fake()->numerify('####'),
            'employment_type' => fake()->randomElement(['Full-time', 'Part-time', 'Casual', 'Other']),
            'job_title' => fake()->jobTitle(),
            'joining_date' => fake()->dateTimeBetween('-3 years', 'now')->format('Y-m-d'),
            'salary_type' => fake()->randomElement(['Monthly', 'Daily', 'Hourly']),
            'salary_rate' => fake()->randomFloat(2, 20, 60),
            'status' => 'active',
            'profile_photo' => null,
            'notes' => null,
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn (array $attributes): array => [
            'status' => 'inactive',
        ]);
    }
}
