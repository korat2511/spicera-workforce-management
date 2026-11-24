<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Shift extends Model
{
    /** @use HasFactory<\Database\Factories\ShiftFactory> */
    use HasFactory;

    public const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    protected $fillable = [
        'business_id',
        'name',
        'shift_type',
        'description',
        'start_time',
        'end_time',
        'status',
        'break_duration_minutes',
        'grace_period_minutes',
        'scheduled_days',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'start_time' => 'datetime:H:i',
            'end_time' => 'datetime:H:i',
            'break_duration_minutes' => 'integer',
            'grace_period_minutes' => 'integer',
            'scheduled_days' => 'array',
        ];
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function staff(): HasMany
    {
        return $this->hasMany(Staff::class);
    }

    /**
     * Duration in hours, accounting for overnight shifts where the end time
     * is earlier in the clock than the start time.
     */
    public function durationHours(): ?float
    {
        if (! $this->start_time || ! $this->end_time) {
            return null;
        }

        $end = $this->end_time->lessThanOrEqualTo($this->start_time)
            ? $this->end_time->copy()->addDay()
            : $this->end_time;

        return round($this->start_time->diffInMinutes($end) / 60, 1);
    }

    /**
     * Scheduled weekday labels (e.g. ['Mon', 'Wed']) in week order.
     *
     * @return array<int, string>
     */
    public function scheduledDayLabels(): array
    {
        $days = $this->scheduled_days ?? [];

        return collect(self::WEEKDAYS)
            ->filter(fn (string $label, int $index): bool => in_array($index + 1, $days, true))
            ->values()
            ->all();
    }
}
