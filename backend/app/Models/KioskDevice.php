<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class KioskDevice extends Model
{
    /** @use HasFactory<\Database\Factories\KioskDeviceFactory> */
    use HasFactory;

    protected $fillable = [
        'business_id',
        'name',
        'platform',
        'model',
        'token_hash',
        'last_seen_at',
        'revoked_at',
    ];

    protected $hidden = [
        'token_hash',
    ];

    protected function casts(): array
    {
        return [
            'last_seen_at' => 'datetime',
            'revoked_at' => 'datetime',
        ];
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function isRevoked(): bool
    {
        return $this->revoked_at !== null;
    }

    /**
     * Generate a new plaintext device token. Only ever returned once, at
     * registration time — only its hash is persisted.
     */
    public static function generateToken(): string
    {
        return Str::random(60);
    }

    public static function hashToken(string $token): string
    {
        return hash('sha256', $token);
    }

    public static function findByToken(string $token): ?self
    {
        return static::where('token_hash', static::hashToken($token))->first();
    }
}
