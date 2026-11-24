<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Shift;
use App\Models\Staff;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class StaffApiTest extends TestCase
{
    use RefreshDatabase;

    private Business $business;

    protected function setUp(): void
    {
        parent::setUp();

        $this->business = Business::factory()->create();
    }

    public function test_it_lists_staff_with_pagination(): void
    {
        Staff::factory()->count(20)->for($this->business)->create();

        $response = $this->getJson('/api/v1/staff');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.pagination.total', 20)
            ->assertJsonPath('data.pagination.per_page', 15)
            ->assertJsonPath('data.pagination.last_page', 2)
            ->assertJsonCount(15, 'data.staff');
    }

    public function test_it_respects_per_page_query_param(): void
    {
        Staff::factory()->count(20)->for($this->business)->create();

        $response = $this->getJson('/api/v1/staff?per_page=5');

        $response->assertOk()->assertJsonCount(5, 'data.staff');
    }

    public function test_it_searches_staff_by_name_code_and_phone(): void
    {
        Staff::factory()->for($this->business)->create(['first_name' => 'Jonathan', 'last_name' => 'Taylor', 'staff_code' => 'ABC001']);
        Staff::factory()->for($this->business)->create(['first_name' => 'Priya', 'last_name' => 'Nair', 'staff_code' => 'ABC002']);

        $response = $this->getJson('/api/v1/staff?search=Jonathan');

        $response->assertOk()->assertJsonCount(1, 'data.staff')
            ->assertJsonPath('data.staff.0.first_name', 'Jonathan');

        $this->getJson('/api/v1/staff?search=ABC002')
            ->assertOk()
            ->assertJsonCount(1, 'data.staff')
            ->assertJsonPath('data.staff.0.staff_code', 'ABC002');
    }

    public function test_it_filters_staff_by_status(): void
    {
        Staff::factory()->count(3)->for($this->business)->create(['status' => 'active']);
        Staff::factory()->inactive()->count(2)->for($this->business)->create();

        $this->getJson('/api/v1/staff?status=inactive')
            ->assertOk()
            ->assertJsonCount(2, 'data.staff');
    }

    public function test_it_filters_staff_by_employment_type(): void
    {
        Staff::factory()->count(2)->for($this->business)->create(['employment_type' => 'Casual']);
        Staff::factory()->count(1)->for($this->business)->create(['employment_type' => 'Full-time']);

        $this->getJson('/api/v1/staff?employment_type=Casual')
            ->assertOk()
            ->assertJsonCount(2, 'data.staff');
    }

    public function test_it_shows_a_single_staff_member(): void
    {
        $staff = Staff::factory()->for($this->business)->create();

        $this->getJson("/api/v1/staff/{$staff->id}")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $staff->id)
            ->assertJsonPath('data.currency', 'AUD');
    }

    public function test_it_returns_404_for_an_unknown_staff_member(): void
    {
        $this->getJson('/api/v1/staff/999999')
            ->assertNotFound()
            ->assertJsonPath('success', false);
    }

    public function test_it_creates_a_staff_member(): void
    {
        $payload = [
            'first_name' => 'John',
            'last_name' => 'Smith',
            'phone' => '0412345678',
            'employment_type' => 'Full-time',
            'joining_date' => '2026-01-10',
            'salary_type' => 'Hourly',
            'salary_rate' => 28.50,
        ];

        $response = $this->postJson('/api/v1/staff', $payload);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.first_name', 'John')
            ->assertJsonPath('data.status', 'active')
            ->assertJsonPath('data.currency', 'AUD');

        $this->assertDatabaseHas('staff', [
            'business_id' => $this->business->id,
            'first_name' => 'John',
            'last_name' => 'Smith',
        ]);
    }

    public function test_it_rejects_staff_creation_with_missing_required_fields(): void
    {
        $this->postJson('/api/v1/staff', [])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonValidationErrors(['first_name', 'last_name', 'phone', 'employment_type', 'joining_date', 'salary_type', 'salary_rate']);
    }

    public function test_it_rejects_an_invalid_australian_phone_number(): void
    {
        $payload = $this->validStaffPayload(['phone' => '12345']);

        $this->postJson('/api/v1/staff', $payload)
            ->assertStatus(422)
            ->assertJsonValidationErrors(['phone']);
    }

    public function test_it_rejects_a_duplicate_staff_code_within_the_same_business(): void
    {
        Staff::factory()->for($this->business)->create(['staff_code' => 'DUP001']);

        $payload = $this->validStaffPayload(['staff_code' => 'DUP001']);

        $this->postJson('/api/v1/staff', $payload)
            ->assertStatus(422)
            ->assertJsonValidationErrors(['staff_code']);
    }

    public function test_it_rejects_a_negative_salary_rate(): void
    {
        $payload = $this->validStaffPayload(['salary_rate' => -10]);

        $this->postJson('/api/v1/staff', $payload)
            ->assertStatus(422)
            ->assertJsonValidationErrors(['salary_rate']);
    }

    public function test_it_fully_replaces_a_staff_member_with_put(): void
    {
        $staff = Staff::factory()->for($this->business)->create();

        $payload = $this->validStaffPayload(['first_name' => 'Replaced']);

        $this->putJson("/api/v1/staff/{$staff->id}", $payload)
            ->assertOk()
            ->assertJsonPath('data.first_name', 'Replaced');
    }

    public function test_it_partially_updates_a_staff_member_with_patch(): void
    {
        $staff = Staff::factory()->for($this->business)->create(['job_title' => 'Chef']);

        $this->patchJson("/api/v1/staff/{$staff->id}", ['job_title' => 'Head Chef'])
            ->assertOk()
            ->assertJsonPath('data.job_title', 'Head Chef')
            ->assertJsonPath('data.first_name', $staff->first_name);
    }

    public function test_it_changes_staff_status(): void
    {
        $staff = Staff::factory()->for($this->business)->create(['status' => 'active']);

        $this->patchJson("/api/v1/staff/{$staff->id}/status", ['status' => 'inactive'])
            ->assertOk()
            ->assertJsonPath('data.status', 'inactive');

        $this->assertDatabaseHas('staff', ['id' => $staff->id, 'status' => 'inactive']);
    }

    public function test_it_rejects_an_invalid_status_value(): void
    {
        $staff = Staff::factory()->for($this->business)->create();

        $this->patchJson("/api/v1/staff/{$staff->id}/status", ['status' => 'retired'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['status']);
    }

    public function test_it_sets_a_staff_pin(): void
    {
        $staff = Staff::factory()->for($this->business)->create();

        $this->patchJson("/api/v1/staff/{$staff->id}/pin", [
            'pin' => '123456',
            'pin_confirmation' => '123456',
        ])
            ->assertOk()
            ->assertJsonPath('data.pin_set', true)
            ->assertJsonMissingPath('data.pin_hash')
            ->assertJsonMissingPath('data.pin');

        $this->assertTrue(Hash::check('123456', $staff->fresh()->pin_hash));
    }

    public function test_it_rejects_a_pin_confirmation_mismatch(): void
    {
        $staff = Staff::factory()->for($this->business)->create();

        $this->patchJson("/api/v1/staff/{$staff->id}/pin", [
            'pin' => '123456',
            'pin_confirmation' => '654321',
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['pin']);
    }

    public function test_it_rejects_a_pin_that_is_not_six_digits(): void
    {
        $staff = Staff::factory()->for($this->business)->create();

        $this->patchJson("/api/v1/staff/{$staff->id}/pin", [
            'pin' => '12',
            'pin_confirmation' => '12',
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['pin']);
    }

    public function test_it_assigns_a_shift_to_staff(): void
    {
        $staff = Staff::factory()->for($this->business)->create();
        $shift = Shift::factory()->for($this->business)->create(['name' => 'Morning Shift']);

        $this->patchJson("/api/v1/staff/{$staff->id}/shift", ['shift_id' => $shift->id])
            ->assertOk()
            ->assertJsonPath('data.shift.id', $shift->id)
            ->assertJsonPath('data.shift.name', 'Morning Shift');

        $this->assertDatabaseHas('staff', ['id' => $staff->id, 'shift_id' => $shift->id]);
    }

    public function test_it_unassigns_a_shift_from_staff(): void
    {
        $shift = Shift::factory()->for($this->business)->create();
        $staff = Staff::factory()->for($this->business)->create(['shift_id' => $shift->id]);

        $this->patchJson("/api/v1/staff/{$staff->id}/shift", ['shift_id' => null])
            ->assertOk()
            ->assertJsonPath('data.shift', null);

        $this->assertDatabaseHas('staff', ['id' => $staff->id, 'shift_id' => null]);
    }

    public function test_it_rejects_an_unknown_shift_id(): void
    {
        $staff = Staff::factory()->for($this->business)->create();

        $this->patchJson("/api/v1/staff/{$staff->id}/shift", ['shift_id' => 999999])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['shift_id']);
    }

    public function test_it_rejects_a_shift_belonging_to_another_business(): void
    {
        $staff = Staff::factory()->for($this->business)->create();
        $otherBusiness = Business::factory()->create();
        $otherShift = Shift::factory()->for($otherBusiness)->create();

        $this->patchJson("/api/v1/staff/{$staff->id}/shift", ['shift_id' => $otherShift->id])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['shift_id']);
    }

    public function test_staff_from_another_business_never_leaks_into_results(): void
    {
        $otherBusiness = Business::factory()->create();
        $otherStaff = Staff::factory()->for($otherBusiness)->create();
        Staff::factory()->for($this->business)->create();

        $this->getJson('/api/v1/staff')
            ->assertOk()
            ->assertJsonMissing(['id' => $otherStaff->id]);

        $this->getJson("/api/v1/staff/{$otherStaff->id}")
            ->assertNotFound();
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function validStaffPayload(array $overrides = []): array
    {
        return array_merge([
            'first_name' => 'John',
            'last_name' => 'Smith',
            'phone' => '0412345678',
            'employment_type' => 'Full-time',
            'joining_date' => '2026-01-10',
            'salary_type' => 'Hourly',
            'salary_rate' => 28.50,
        ], $overrides);
    }
}
