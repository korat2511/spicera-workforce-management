<?php

namespace Database\Factories;

use App\Models\Business;
use App\Models\KioskDevice;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<KioskDevice>
 */
class KioskDeviceFactory extends Factory
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
            'name' => fake()->randomElement(['Front Counter iPad', 'Kitchen Tablet', 'Back Office Phone']),
            'platform' => fake()->randomElement(['iOS', 'Android']),
            'model' => fake()->randomElement(['iPad (iOS 17.4)', 'samsung SM-G998B (Android 14)']),
            'token_hash' => KioskDevice::hashToken(KioskDevice::generateToken()),
            'last_seen_at' => null,
            'revoked_at' => null,
        ];
    }
}
