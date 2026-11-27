<?php

namespace App\Services;

use App\Models\AttendanceRecord;
use App\Models\Business;
use App\Models\KioskDevice;
use App\Models\Staff;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AttendanceService
{
    /**
     * Find the active staff member whose PIN matches, or null. PIN hashes
     * are salted, so each candidate has to be checked individually — see
     * StaffService::assertPinNotInUseByAnotherStaffMember() for the same
     * constraint on the set side.
     */
    public function findStaffByPin(Business $business, string $pin): ?Staff
    {
        return Staff::where('business_id', $business->id)
            ->where('status', 'active')
            ->whereNotNull('pin_hash')
            ->get()
            ->first(fn (Staff $staff): bool => Hash::check($pin, $staff->pin_hash));
    }

    public function punch(Business $business, Staff $staff, UploadedFile $photo, ?KioskDevice $device): AttendanceRecord
    {
        $now = CarbonImmutable::now($business->timezone ?? 'UTC');

        $todaysRecords = AttendanceRecord::where('business_id', $business->id)
            ->where('staff_id', $staff->id)
            ->whereBetween('recorded_at', [
                $now->startOfDay()->utc(),
                $now->endOfDay()->utc(),
            ])
            ->orderBy('recorded_at')
            ->get();

        $type = $this->determinePunchType($todaysRecords);
        $photoPath = $photo->store('attendance-photos', 'public');

        return AttendanceRecord::create([
            'business_id' => $business->id,
            'staff_id' => $staff->id,
            'shift_id' => $staff->shift_id,
            'kiosk_device_id' => $device?->id,
            'type' => $type,
            // $now is in the business's local timezone (needed for the
            // day-boundary query above and the shift-time comparisons in
            // determineStatus()) — convert to UTC only at the point of
            // storage, matching every other timestamp column in this app.
            'recorded_at' => $now->utc(),
            'photo_path' => $photoPath,
            'status' => $this->determineStatus($type, $staff, $now),
        ])->load(['staff', 'shift']);
    }

    /**
     * @param  \Illuminate\Support\Collection<int, AttendanceRecord>  $todaysRecords
     */
    private function determinePunchType($todaysRecords): string
    {
        if ($todaysRecords->isEmpty()) {
            return AttendanceRecord::TYPE_CHECK_IN;
        }

        if ($todaysRecords->last()->type === AttendanceRecord::TYPE_CHECK_IN) {
            return AttendanceRecord::TYPE_CHECK_OUT;
        }

        throw ValidationException::withMessages([
            'pin' => ["You've already completed today's attendance. Contact your manager if you need a correction."],
        ]);
    }

    private function determineStatus(string $type, Staff $staff, CarbonImmutable $now): ?string
    {
        $shift = $staff->shift;

        if (! $shift || ! $shift->start_time || ! $shift->end_time) {
            return null;
        }

        $grace = $shift->grace_period_minutes ?? 0;
        $scheduledStart = $now->setTime($shift->start_time->hour, $shift->start_time->minute);
        $scheduledEnd = $now->setTime($shift->end_time->hour, $shift->end_time->minute);

        if ($shift->end_time->lessThanOrEqualTo($shift->start_time)) {
            $scheduledEnd = $scheduledEnd->addDay();
        }

        if ($type === AttendanceRecord::TYPE_CHECK_IN) {
            return $now->greaterThan($scheduledStart->addMinutes($grace)) ? 'late' : 'on_time';
        }

        if ($now->lessThan($scheduledEnd)) {
            return 'early_leave';
        }

        return $now->greaterThan($scheduledEnd->addMinutes($grace)) ? 'overtime' : 'on_time';
    }

    /**
     * @param  array{search?: ?string, staff_id?: ?int, status?: ?string, date_from?: ?string, date_to?: ?string, per_page?: ?int}  $filters
     */
    public function list(Business $business, array $filters): LengthAwarePaginator
    {
        $query = AttendanceRecord::with(['staff', 'shift'])->where('business_id', $business->id);

        if (! empty($filters['search'])) {
            $search = $filters['search'];
            $query->whereHas('staff', function ($q) use ($search): void {
                $q->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('staff_code', 'like', "%{$search}%");
            });
        }

        if (! empty($filters['staff_id'])) {
            $query->where('staff_id', $filters['staff_id']);
        }

        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (! empty($filters['date_from'])) {
            $query->whereDate('recorded_at', '>=', $filters['date_from']);
        }

        if (! empty($filters['date_to'])) {
            $query->whereDate('recorded_at', '<=', $filters['date_to']);
        }

        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        return $query->orderByDesc('recorded_at')->paginate($perPage);
    }
}
