<?php

namespace App\Console\Commands;

use App\Models\AttendanceRecord;
use App\Models\Business;
use App\Models\Shift;
use App\Models\Staff;
use Carbon\CarbonImmutable;
use Illuminate\Console\Command;

class SeedDummyAttendance extends Command
{
    protected $signature = 'attendance:seed-dummy {--days=30} {--fresh}';

    protected $description = 'Generate dummy check-in/check-out attendance records for active staff over the past N days';

    public function handle(): int
    {
        $business = Business::firstOrFail();
        $days = (int) $this->option('days');
        $timezone = $business->timezone ?? 'UTC';
        $today = CarbonImmutable::now($timezone)->startOfDay();

        if ($this->option('fresh')) {
            AttendanceRecord::where('business_id', $business->id)->delete();
        }

        $staffMembers = Staff::where('business_id', $business->id)
            ->where('status', 'active')
            ->with('shift')
            ->get();

        $rows = [];

        foreach ($staffMembers as $staff) {
            for ($i = $days; $i >= 1; $i--) {
                if (random_int(1, 7) === 1) {
                    continue;
                }

                $day = $today->subDays($i);
                [$scheduledStart, $scheduledEnd] = $this->scheduledWindow($day, $staff->shift);
                $grace = $staff->shift?->grace_period_minutes ?? 0;

                $checkIn = $scheduledStart->addMinutes($this->randomCheckInOffsetMinutes());
                $checkOut = $scheduledEnd->addMinutes($this->randomCheckOutOffsetMinutes());

                $rows[] = $this->record(
                    $business->id,
                    $staff,
                    AttendanceRecord::TYPE_CHECK_IN,
                    $checkIn,
                    $staff->shift ? ($checkIn->greaterThan($scheduledStart->addMinutes($grace)) ? 'late' : 'on_time') : null,
                );

                $rows[] = $this->record(
                    $business->id,
                    $staff,
                    AttendanceRecord::TYPE_CHECK_OUT,
                    $checkOut,
                    $staff->shift ? $this->checkOutStatus($checkOut, $scheduledEnd, $grace) : null,
                );
            }
        }

        AttendanceRecord::insert($rows);

        $this->info(sprintf(
            'Seeded %d dummy attendance records for %d active staff over the last %d days.',
            count($rows),
            $staffMembers->count(),
            $days,
        ));

        return self::SUCCESS;
    }

    /**
     * @return array{0: CarbonImmutable, 1: CarbonImmutable}
     */
    private function scheduledWindow(CarbonImmutable $day, ?Shift $shift): array
    {
        if (! $shift || ! $shift->start_time || ! $shift->end_time) {
            return [$day->setTime(9, 0), $day->setTime(17, 0)];
        }

        $start = $day->setTime($shift->start_time->hour, $shift->start_time->minute);
        $end = $day->setTime($shift->end_time->hour, $shift->end_time->minute);

        if ($shift->end_time->lessThanOrEqualTo($shift->start_time)) {
            $end = $end->addDay();
        }

        return [$start, $end];
    }

    private function randomCheckInOffsetMinutes(): int
    {
        $roll = random_int(1, 100);

        return match (true) {
            $roll <= 70 => random_int(-10, 5),
            $roll <= 90 => random_int(11, 35),
            default => random_int(36, 60),
        };
    }

    private function randomCheckOutOffsetMinutes(): int
    {
        $roll = random_int(1, 100);

        return match (true) {
            $roll <= 20 => random_int(-60, -10),
            $roll <= 80 => random_int(0, 20),
            default => random_int(30, 90),
        };
    }

    private function checkOutStatus(CarbonImmutable $checkOut, CarbonImmutable $scheduledEnd, int $grace): string
    {
        if ($checkOut->lessThan($scheduledEnd)) {
            return 'early_leave';
        }

        return $checkOut->greaterThan($scheduledEnd->addMinutes($grace)) ? 'overtime' : 'on_time';
    }

    /**
     * @return array<string, mixed>
     */
    private function record(int $businessId, Staff $staff, string $type, CarbonImmutable $recordedAt, ?string $status): array
    {
        return [
            'business_id' => $businessId,
            'staff_id' => $staff->id,
            'shift_id' => $staff->shift_id,
            'kiosk_device_id' => null,
            'type' => $type,
            'recorded_at' => $recordedAt->utc(),
            'photo_path' => null,
            'status' => $status,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}
