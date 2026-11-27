<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\KioskDevice;
use App\Models\Shift;
use App\Models\Staff;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AttendanceApiTest extends TestCase
{
    use RefreshDatabase;

    private Business $business;

    private string $kioskToken;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');

        $this->business = Business::factory()->create();
        $this->kioskToken = KioskDevice::generateToken();
        KioskDevice::factory()->for($this->business)->create([
            'token_hash' => KioskDevice::hashToken($this->kioskToken),
        ]);
    }

    private function punch(string $pin): TestResponse
    {
        return $this->withHeader('X-Kiosk-Token', $this->kioskToken)
            ->post('/api/v1/attendance/punch', [
                'pin' => $pin,
                'photo' => UploadedFile::fake()->image('selfie.jpg'),
            ], ['Accept' => 'application/json']);
    }

    public function test_it_checks_in_a_staff_member_on_the_first_punch_of_the_day(): void
    {
        Staff::factory()->for($this->business)->create(['pin_hash' => Hash::make('123456')]);

        $this->punch('123456')
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.type', 'check_in');

        $this->assertDatabaseCount('attendance_records', 1);
    }

    public function test_it_checks_out_a_staff_member_on_the_second_punch_of_the_day(): void
    {
        $staff = Staff::factory()->for($this->business)->create(['pin_hash' => Hash::make('123456')]);
        $this->punch('123456')->assertCreated();

        $this->punch('123456')
            ->assertCreated()
            ->assertJsonPath('data.type', 'check_out')
            ->assertJsonPath('data.staff.id', $staff->id);

        $this->assertDatabaseCount('attendance_records', 2);
    }

    public function test_it_rejects_a_third_punch_after_todays_attendance_is_closed(): void
    {
        Staff::factory()->for($this->business)->create(['pin_hash' => Hash::make('123456')]);
        $this->punch('123456')->assertCreated();
        $this->punch('123456')->assertCreated();

        $this->punch('123456')
            ->assertStatus(422)
            ->assertJsonValidationErrors(['pin']);

        $this->assertDatabaseCount('attendance_records', 2);
    }

    public function test_it_rejects_an_unknown_pin(): void
    {
        Staff::factory()->for($this->business)->create(['pin_hash' => Hash::make('123456')]);

        $this->punch('999999')
            ->assertStatus(422)
            ->assertJsonValidationErrors(['pin']);
    }

    public function test_it_rejects_a_pin_belonging_to_an_inactive_staff_member(): void
    {
        Staff::factory()->inactive()->for($this->business)->create(['pin_hash' => Hash::make('123456')]);

        $this->punch('123456')->assertStatus(422);
    }

    public function test_it_requires_a_photo(): void
    {
        Staff::factory()->for($this->business)->create(['pin_hash' => Hash::make('123456')]);

        $this->withHeader('X-Kiosk-Token', $this->kioskToken)
            ->postJson('/api/v1/attendance/punch', ['pin' => '123456'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['photo']);
    }

    public function test_it_rejects_punch_without_a_kiosk_token(): void
    {
        Staff::factory()->for($this->business)->create(['pin_hash' => Hash::make('123456')]);

        $this->postJson('/api/v1/attendance/punch', [
            'pin' => '123456',
            'photo' => UploadedFile::fake()->image('selfie.jpg'),
        ])->assertStatus(401);
    }

    public function test_it_rejects_punch_with_a_revoked_kiosk_token(): void
    {
        $revokedToken = KioskDevice::generateToken();
        KioskDevice::factory()->for($this->business)->create([
            'token_hash' => KioskDevice::hashToken($revokedToken),
            'revoked_at' => now(),
        ]);
        Staff::factory()->for($this->business)->create(['pin_hash' => Hash::make('123456')]);

        $this->withHeader('X-Kiosk-Token', $revokedToken)
            ->post('/api/v1/attendance/punch', [
                'pin' => '123456',
                'photo' => UploadedFile::fake()->image('selfie.jpg'),
            ], ['Accept' => 'application/json'])
            ->assertStatus(401);
    }

    public function test_pin_lookup_is_scoped_to_the_kiosk_devices_business(): void
    {
        $otherBusiness = Business::factory()->create();
        Staff::factory()->for($otherBusiness)->create(['pin_hash' => Hash::make('123456')]);
        // No staff with this PIN in $this->business.

        $this->punch('123456')->assertStatus(422);
    }

    public function test_it_marks_a_late_check_in_based_on_shift_grace_period(): void
    {
        $shift = Shift::factory()->for($this->business)->create([
            'start_time' => now()->subHours(2)->format('H:i'),
            'end_time' => now()->addHours(6)->format('H:i'),
            'grace_period_minutes' => 10,
        ]);
        Staff::factory()->for($this->business)->create([
            'pin_hash' => Hash::make('123456'),
            'shift_id' => $shift->id,
        ]);

        $this->punch('123456')
            ->assertCreated()
            ->assertJsonPath('data.status', 'late');
    }

    public function test_admin_can_list_attendance_records(): void
    {
        Sanctum::actingAs(User::factory()->for($this->business)->create());
        Staff::factory()->for($this->business)->create(['pin_hash' => Hash::make('123456')]);
        $this->punch('123456')->assertCreated();

        $this->getJson('/api/v1/attendance')
            ->assertOk()
            ->assertJsonCount(1, 'data.attendance');
    }

    public function test_admin_can_search_attendance_records_by_staff_name(): void
    {
        Sanctum::actingAs(User::factory()->for($this->business)->create());
        Staff::factory()->for($this->business)->create([
            'first_name' => 'Jonathan',
            'last_name' => 'Taylor',
            'pin_hash' => Hash::make('123456'),
        ]);
        Staff::factory()->for($this->business)->create([
            'first_name' => 'Priya',
            'last_name' => 'Nair',
            'pin_hash' => Hash::make('654321'),
        ]);
        $this->punch('123456')->assertCreated();
        $this->punch('654321')->assertCreated();

        $this->getJson('/api/v1/attendance?search=Jonathan')
            ->assertOk()
            ->assertJsonCount(1, 'data.attendance')
            ->assertJsonPath('data.attendance.0.staff.full_name', 'Jonathan Taylor');
    }
}
