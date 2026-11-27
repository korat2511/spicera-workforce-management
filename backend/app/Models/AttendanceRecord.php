<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AttendanceRecord extends Model
{
    /** @use HasFactory<\Database\Factories\AttendanceRecordFactory> */
    use HasFactory;

    public const TYPE_CHECK_IN = 'check_in';

    public const TYPE_CHECK_OUT = 'check_out';

    protected $fillable = [
        'business_id',
        'staff_id',
        'shift_id',
        'kiosk_device_id',
        'type',
        'recorded_at',
        'photo_path',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'recorded_at' => 'datetime',
        ];
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function staff(): BelongsTo
    {
        return $this->belongsTo(Staff::class);
    }

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class);
    }

    public function kioskDevice(): BelongsTo
    {
        return $this->belongsTo(KioskDevice::class);
    }
}
