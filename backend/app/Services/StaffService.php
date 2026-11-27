<?php

namespace App\Services;

use App\Models\Business;
use App\Models\Staff;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class StaffService
{
    /**
     * @param  array{search?: ?string, status?: ?string, employment_type?: ?string, per_page?: ?int}  $filters
     */
    public function list(Business $business, array $filters): LengthAwarePaginator
    {
        $query = Staff::query()->with(['business', 'shift'])->where('business_id', $business->id);

        if (! empty($filters['search'])) {
            $search = $filters['search'];
            $query->where(function ($q) use ($search): void {
                $q->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('staff_code', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (! empty($filters['employment_type'])) {
            $query->where('employment_type', $filters['employment_type']);
        }

        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        return $query->orderByDesc('created_at')->paginate($perPage);
    }

    public function find(Business $business, int $id): Staff
    {
        return Staff::with(['business', 'shift'])->where('business_id', $business->id)->findOrFail($id);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function create(Business $business, array $data): Staff
    {
        return DB::transaction(function () use ($business, $data): Staff {
            $data['business_id'] = $business->id;
            $data['phone'] = $this->normalizeAustralianPhone($data['phone']);
            $data['status'] = 'active';
            $data['staff_code'] = $data['staff_code'] ?? $this->generateStaffCode($business);
            $data['overtime_rate_type'] = $data['overtime_rate_type'] ?? 'not_eligible';
            $data = $this->normalizeOvertimeFields($data);

            return Staff::create($data)->load(['business', 'shift']);
        });
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function update(Staff $staff, array $data): Staff
    {
        if (array_key_exists('phone', $data)) {
            $data['phone'] = $this->normalizeAustralianPhone($data['phone']);
        }

        $data = $this->normalizeOvertimeFields($data);

        $staff->fill($data)->save();

        return $staff->fresh(['business', 'shift']);
    }

    public function changeStatus(Staff $staff, string $status): Staff
    {
        $staff->update(['status' => $status]);

        return $staff->fresh(['business', 'shift']);
    }

    public function setPin(Staff $staff, string $pin): Staff
    {
        $this->assertPinNotInUseByAnotherStaffMember($staff, $pin);

        $staff->pin_hash = Hash::make($pin);
        $staff->save();

        return $staff->fresh(['business', 'shift']);
    }

    /**
     * PIN hashes are salted (bcrypt), so two staff members using the same
     * PIN produce two different hash strings — a DB unique constraint on
     * the hash column can't catch a collision. Each candidate has to be
     * checked individually instead.
     */
    private function assertPinNotInUseByAnotherStaffMember(Staff $staff, string $pin): void
    {
        $hasConflict = Staff::where('business_id', $staff->business_id)
            ->where('id', '!=', $staff->id)
            ->whereNotNull('pin_hash')
            ->get(['pin_hash'])
            ->contains(fn (Staff $other): bool => Hash::check($pin, $other->pin_hash));

        if ($hasConflict) {
            throw ValidationException::withMessages([
                'pin' => ['This PIN is already in use by another staff member.'],
            ]);
        }
    }

    public function assignShift(Staff $staff, ?int $shiftId): Staff
    {
        $staff->update(['shift_id' => $shiftId]);

        return $staff->fresh(['business', 'shift']);
    }

    public function generateStaffCode(Business $business): string
    {
        $prefix = $business->staffCodePrefix();
        $count = Staff::withoutGlobalScopes()->where('business_id', $business->id)->count();

        return $prefix.str_pad((string) ($count + 1), 3, '0', STR_PAD_LEFT);
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function normalizeOvertimeFields(array $data): array
    {
        if (array_key_exists('overtime_rate_type', $data) && $data['overtime_rate_type'] !== 'custom') {
            $data['overtime_custom_type'] = null;
            $data['overtime_custom_rate'] = null;
        }

        return $data;
    }

    public function normalizeAustralianPhone(string $phone): string
    {
        $digits = preg_replace('/[^\d+]/', '', $phone) ?? '';

        $national = match (true) {
            str_starts_with($digits, '+61') => substr($digits, 3),
            str_starts_with($digits, '61') && strlen($digits) === 11 => substr($digits, 2),
            str_starts_with($digits, '0') && strlen($digits) === 10 => substr($digits, 1),
            default => ltrim($digits, '0'),
        };

        return '0'.$national;
    }
}
