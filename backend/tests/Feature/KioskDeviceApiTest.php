<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\KioskDevice;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class KioskDeviceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_registers_a_kiosk_device(): void
    {
        $business = Business::factory()->create();
        Sanctum::actingAs(User::factory()->for($business)->create());

        $response = $this->postJson('/api/v1/kiosk-devices', [
            'name' => 'Front Counter iPad',
            'platform' => 'iOS',
            'model' => 'iPad (iOS 17.4)',
        ]);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.device.name', 'Front Counter iPad')
            ->assertJsonPath('data.device.platform', 'iOS')
            ->assertJsonPath('data.device.model', 'iPad (iOS 17.4)')
            ->assertJsonStructure([
                'data' => ['device' => ['id', 'name', 'platform', 'model'], 'token'],
            ]);

        $token = $response->json('data.token');
        $this->assertNotEmpty($token);

        $this->assertDatabaseHas('kiosk_devices', [
            'business_id' => $business->id,
            'name' => 'Front Counter iPad',
            'platform' => 'iOS',
            'model' => 'iPad (iOS 17.4)',
            'token_hash' => KioskDevice::hashToken($token),
        ]);
    }

    public function test_it_rejects_registration_without_a_name(): void
    {
        Sanctum::actingAs(User::factory()->for(Business::factory()->create())->create());

        $this->postJson('/api/v1/kiosk-devices', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    }

    public function test_it_rejects_registration_without_authentication(): void
    {
        $this->postJson('/api/v1/kiosk-devices', ['name' => 'Kitchen Tablet'])
            ->assertStatus(401);
    }

    public function test_it_only_lists_devices_for_the_authenticated_business(): void
    {
        $businessA = Business::factory()->create();
        $businessB = Business::factory()->create();

        KioskDevice::factory()->for($businessA)->count(2)->create();
        KioskDevice::factory()->for($businessB)->count(1)->create();

        Sanctum::actingAs(User::factory()->for($businessA)->create());

        $this->getJson('/api/v1/kiosk-devices')
            ->assertOk()
            ->assertJsonCount(2, 'data');
    }

    public function test_it_revokes_a_kiosk_device(): void
    {
        $business = Business::factory()->create();
        $device = KioskDevice::factory()->for($business)->create();

        Sanctum::actingAs(User::factory()->for($business)->create());

        $this->deleteJson("/api/v1/kiosk-devices/{$device->id}")
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('kiosk_devices', [
            'id' => $device->id,
        ]);
        $this->assertNotNull($device->fresh()->revoked_at);
    }

    public function test_it_cannot_revoke_a_device_belonging_to_another_business(): void
    {
        $businessA = Business::factory()->create();
        $businessB = Business::factory()->create();
        $device = KioskDevice::factory()->for($businessB)->create();

        Sanctum::actingAs(User::factory()->for($businessA)->create());

        $this->deleteJson("/api/v1/kiosk-devices/{$device->id}")
            ->assertNotFound();
    }

    public function test_kiosk_device_token_round_trips_through_hash_and_lookup(): void
    {
        $business = Business::factory()->create();
        $token = KioskDevice::generateToken();

        $device = KioskDevice::factory()->for($business)->create([
            'token_hash' => KioskDevice::hashToken($token),
        ]);

        $found = KioskDevice::findByToken($token);

        $this->assertNotNull($found);
        $this->assertSame($device->id, $found->id);
        $this->assertNull(KioskDevice::findByToken('not-the-right-token'));
    }
}
