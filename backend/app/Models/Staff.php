<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Staff extends Model
{
    /** @use HasFactory<\Database\Factories\StaffFactory> */
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'business_id',
        'staff_code',
        'first_name',
        'last_name',
        'email',
        'phone',
        'date_of_birth',
        'gender',
        'street_address',
        'suburb',
        'state',
        'postcode',
        'employment_type',
        'job_title',
        'joining_date',
        'salary_type',
        'salary_rate',
        'overtime_rate_type',
        'overtime_custom_type',
        'overtime_custom_rate',
        'status',
        'profile_photo',
        'notes',
        'shift_id',
    ];

    protected $hidden = [
        'pin_hash',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'joining_date' => 'date',
            'salary_rate' => 'decimal:2',
            'overtime_custom_rate' => 'decimal:2',
        ];
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class);
    }

    protected function fullName(): Attribute
    {
        return Attribute::make(
            get: fn (): string => trim("{$this->first_name} {$this->last_name}"),
        );
    }

    protected function overtimeLabel(): Attribute
    {
        return Attribute::make(
            get: function (): string {
                if ($this->overtime_rate_type !== 'custom') {
                    return match ($this->overtime_rate_type) {
                        '1x', '1.5x', '2x' => "{$this->overtime_rate_type} regular rate",
                        default => 'Not eligible',
                    };
                }

                return $this->overtime_custom_type === 'fixed_rate'
                    ? "\${$this->overtime_custom_rate}/hr (Custom)"
                    : "{$this->overtime_custom_rate}x regular rate (Custom)";
            },
        );
    }
}
