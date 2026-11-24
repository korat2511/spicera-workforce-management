<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreShiftRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * Phase 1 has no authentication/authorization yet — Phase 2 will add
     * real policy checks here.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'shift_type' => ['nullable', 'string', 'max:50'],
            'description' => ['nullable', 'string', 'max:255'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i'],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
            'break_duration_minutes' => ['sometimes', 'integer', 'min:0', 'max:180'],
            'grace_period_minutes' => ['sometimes', 'integer', 'min:0', 'max:60'],
            'scheduled_days' => ['required', 'array', 'min:1'],
            'scheduled_days.*' => ['integer', 'between:1,7'],
        ];
    }
}
