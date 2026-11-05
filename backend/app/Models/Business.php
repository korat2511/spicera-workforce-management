<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Business extends Model
{
    /** @use HasFactory<\Database\Factories\BusinessFactory> */
    use HasFactory;

    protected $fillable = [
        'business_name',
        'owner_name',
        'email',
        'phone',
        'street_address',
        'suburb',
        'state',
        'postcode',
        'country',
        'currency',
        'timezone',
    ];

    public function staff(): HasMany
    {
        return $this->hasMany(Staff::class);
    }

    /**
     * Derive a staff-code prefix from the business name's initials, e.g.
     * "JK Dhosa House" -> "JK". Not stored — computed only when a new
     * staff code needs generating.
     */
    public function staffCodePrefix(): string
    {
        $words = preg_split('/\s+/', trim($this->business_name)) ?: [];

        $initials = collect($words)
            ->map(fn (string $word): string => mb_strtoupper(mb_substr($word, 0, 1)))
            ->implode('');

        $initials = mb_substr($initials, 0, 3);

        return $initials !== '' ? $initials : 'STF';
    }
}
