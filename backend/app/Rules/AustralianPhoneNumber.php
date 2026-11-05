<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Translation\PotentiallyTranslatedString;

class AustralianPhoneNumber implements ValidationRule
{
    /**
     * Validates common Australian mobile/landline formats, e.g.
     * "0412 345 678", "+61412345678", "(02) 1234 5678", "61212345678".
     * Accepts optional spaces, dashes and a leading "+".
     *
     * @param  Closure(string, ?string=): PotentiallyTranslatedString  $fail
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_string($value)) {
            $fail('The :attribute must be a valid Australian phone number.');

            return;
        }

        $digits = preg_replace('/[^\d+]/', '', $value) ?? '';

        $nationalNumber = match (true) {
            str_starts_with($digits, '+61') => substr($digits, 3),
            str_starts_with($digits, '61') && strlen($digits) === 11 => substr($digits, 2),
            str_starts_with($digits, '0') && strlen($digits) === 10 => substr($digits, 1),
            default => null,
        };

        if ($nationalNumber === null || ! preg_match('/^[2-478]\d{8}$/', $nationalNumber)) {
            $fail('The :attribute must be a valid Australian phone number.');
        }
    }
}
