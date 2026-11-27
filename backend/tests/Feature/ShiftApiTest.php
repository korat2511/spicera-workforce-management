<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Shift;
use App\Models\Staff;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ShiftApiTest extends TestCase
{
    use RefreshDatabase;

    private Business $business;

    protected function setUp(): void
    {
        parent::setUp();
        Sanctum::actingAs(User::factory()->create());

        $this->business = Business::factory()->create();
    }

    public function test_it_lists_shifts_for_the_resolved_business(): void
    {
        Shift::factory()->for($this->business)->create(['name' => 'Morning Shift', 'start_time' => '08:00', 'end_time' => '16:00']);
        Shift::factory()->for($this->business)->create(['name' => 'Evening Shift', 'start_time' => '16:00', 'end_time' => '00:00']);

        $this->getJson('/api/v1/shifts')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.name', 'Morning Shift')
            ->assertJsonPath('data.0.start_time', '08:00')
            ->assertJsonPath('data.0.duration_hours', 8)
            ->assertJsonPath('data.0.staff_count', 0);
    }

    public function test_it_computes_overnight_duration_correctly(): void
    {
        Shift::factory()->for($this->business)->create(['name' => 'Night Shift', 'start_time' => '22:00', 'end_time' => '06:00']);

        $this->getJson('/api/v1/shifts')
            ->assertOk()
            ->assertJsonPath('data.0.duration_hours', 8);
    }

    public function test_it_includes_assigned_staff_and_counts(): void
    {
        $shift = Shift::factory()->for($this->business)->create(['name' => 'Morning Shift']);
        Staff::factory()->for($this->business)->create(['shift_id' => $shift->id, 'first_name' => 'Amy']);
        Staff::factory()->for($this->business)->create(['shift_id' => $shift->id, 'first_name' => 'Ben']);

        $this->getJson('/api/v1/shifts')
            ->assertOk()
            ->assertJsonPath('data.0.staff_count', 2)
            ->assertJsonCount(2, 'data.0.assigned_staff');
    }

    public function test_it_filters_shifts_by_search_and_status(): void
    {
        Shift::factory()->for($this->business)->create(['name' => 'Morning Shift', 'status' => 'active']);
        Shift::factory()->for($this->business)->create(['name' => 'Night Shift', 'status' => 'inactive']);

        $this->getJson('/api/v1/shifts?search=Morning')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Morning Shift');

        $this->getJson('/api/v1/shifts?status=inactive')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Night Shift');
    }

    public function test_shifts_from_another_business_never_leak_into_results(): void
    {
        $otherBusiness = Business::factory()->create();
        Shift::factory()->for($otherBusiness)->create(['name' => 'Other Business Shift']);
        Shift::factory()->for($this->business)->create(['name' => 'My Shift']);

        $this->getJson('/api/v1/shifts')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonMissing(['name' => 'Other Business Shift']);
    }

    public function test_it_shows_a_single_shift(): void
    {
        $shift = Shift::factory()->for($this->business)->create(['name' => 'Morning Shift']);

        $this->getJson("/api/v1/shifts/{$shift->id}")
            ->assertOk()
            ->assertJsonPath('data.name', 'Morning Shift');
    }

    public function test_it_returns_404_for_a_shift_from_another_business(): void
    {
        $otherBusiness = Business::factory()->create();
        $shift = Shift::factory()->for($otherBusiness)->create();

        $this->getJson("/api/v1/shifts/{$shift->id}")->assertNotFound();
    }

    public function test_it_creates_a_shift(): void
    {
        $payload = [
            'name' => 'Afternoon Shift',
            'shift_type' => 'SNACKS & PREP',
            'description' => 'Mid-day interval slot',
            'start_time' => '14:00',
            'end_time' => '18:00',
            'status' => 'active',
            'break_duration_minutes' => 15,
            'grace_period_minutes' => 5,
            'scheduled_days' => [1, 2, 3, 4, 5, 6],
        ];

        $this->postJson('/api/v1/shifts', $payload)
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Afternoon Shift')
            ->assertJsonPath('data.duration_hours', 4)
            ->assertJsonPath('data.scheduled_days', ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']);

        $this->assertDatabaseHas('shifts', [
            'business_id' => $this->business->id,
            'name' => 'Afternoon Shift',
        ]);
    }

    public function test_it_rejects_shift_creation_with_missing_required_fields(): void
    {
        $this->postJson('/api/v1/shifts', [])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonValidationErrors(['name', 'start_time', 'end_time', 'scheduled_days']);
    }

    public function test_it_updates_a_shift(): void
    {
        $shift = Shift::factory()->for($this->business)->create(['name' => 'Morning Shift']);

        $this->patchJson("/api/v1/shifts/{$shift->id}", ['name' => 'Updated Morning Shift'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Updated Morning Shift');

        $this->assertDatabaseHas('shifts', ['id' => $shift->id, 'name' => 'Updated Morning Shift']);
    }

    public function test_it_changes_shift_status(): void
    {
        $shift = Shift::factory()->for($this->business)->create(['status' => 'active']);

        $this->patchJson("/api/v1/shifts/{$shift->id}/status", ['status' => 'inactive'])
            ->assertOk()
            ->assertJsonPath('data.status', 'inactive');
    }

    public function test_it_deletes_a_shift_with_no_staff_assigned(): void
    {
        $shift = Shift::factory()->for($this->business)->create();

        $this->deleteJson("/api/v1/shifts/{$shift->id}")
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('shifts', ['id' => $shift->id]);
    }

    public function test_it_blocks_deleting_a_shift_with_staff_assigned(): void
    {
        $shift = Shift::factory()->for($this->business)->create();
        Staff::factory()->for($this->business)->create(['shift_id' => $shift->id]);

        $this->deleteJson("/api/v1/shifts/{$shift->id}")
            ->assertStatus(422)
            ->assertJsonPath('success', false);

        $this->assertDatabaseHas('shifts', ['id' => $shift->id]);
    }
}
