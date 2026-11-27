<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\User;
use Illuminate\Database\Seeder;

class AdminUserSeeder extends Seeder
{
    /**
     * Seed the single admin account that can log into the app. Credentials
     * are a placeholder until a proper account-management flow exists.
     */
    public function run(): void
    {
        $business = Business::firstOrFail();

        User::updateOrCreate(
            ['email' => 'admin@spicera.com'],
            [
                'name' => 'Admin',
                'password' => 'Romil@123',
                'business_id' => $business->id,
            ]
        );
    }
}
