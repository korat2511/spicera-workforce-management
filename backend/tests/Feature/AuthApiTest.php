<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_logs_in_with_valid_credentials(): void
    {
        $business = Business::factory()->create();
        $user = User::factory()->for($business)->create(['password' => 'Romil@123']);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'Romil@123',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', $user->email)
            ->assertJsonStructure(['data' => ['token', 'user' => ['id', 'name', 'email']]]);
    }

    public function test_it_rejects_an_incorrect_password(): void
    {
        $user = User::factory()->create(['password' => 'Romil@123']);

        $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'wrong-password',
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_it_rejects_an_unknown_email(): void
    {
        $this->postJson('/api/v1/auth/login', [
            'email' => 'nobody@spicera.com',
            'password' => 'Romil@123',
        ])->assertStatus(422);
    }

    public function test_it_rejects_protected_routes_without_a_token(): void
    {
        $this->getJson('/api/v1/staff')
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_it_rejects_protected_routes_without_a_token_even_without_an_accept_header(): void
    {
        // Plain get() (unlike getJson()) does not send Accept: application/json,
        // which is how real clients that forget the header would behave —
        // this must still return 401 JSON, not redirect to a missing "login" route.
        $this->get('/api/v1/staff')
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_it_allows_protected_routes_with_a_valid_token(): void
    {
        Business::factory()->create();
        $user = User::factory()->create(['password' => 'Romil@123']);

        $login = $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'Romil@123',
        ])->json('data.token');

        $this->withHeader('Authorization', "Bearer {$login}")
            ->getJson('/api/v1/staff')
            ->assertOk();
    }

    public function test_it_logs_out_and_revokes_the_token(): void
    {
        Business::factory()->create();
        $user = User::factory()->create(['password' => 'Romil@123']);

        $token = $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'Romil@123',
        ])->json('data.token');

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/v1/auth/logout')
            ->assertOk();

        // The sanctum guard caches its resolved user per guard instance,
        // which otherwise survives across these simulated requests within
        // a single test (unlike production, where each request is fresh).
        $this->app['auth']->forgetGuards();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/staff')
            ->assertStatus(401);
    }
}
