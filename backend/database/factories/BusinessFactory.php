<?php

namespace Database\Factories;

use App\Models\Business;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Business>
 */
class BusinessFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'business_name' => fake()->unique()->company(),
            'owner_name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'phone' => '04'.fake()->numerify('########'),
            'street_address' => fake()->streetAddress(),
            'suburb' => fake()->city(),
            'state' => fake()->randomElement(['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT']),
            'postcode' => fake()->numerify('####'),
            'country' => 'Australia',
            'currency' => 'AUD',
            'timezone' => 'Australia/Sydney',
        ];
    }
}
