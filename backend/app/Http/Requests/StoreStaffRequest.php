<?php

namespace App\Http\Requests;

use App\Rules\AustralianPhoneNumber;
use App\Support\BusinessContext;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreStaffRequest extends FormRequest
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
        $businessId = BusinessContext::resolve()->id;

        return [
            'staff_code' => [
                'nullable',
                'string',
                'max:50',
                Rule::unique('staff', 'staff_code')->where('business_id', $businessId),
            ],
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['required', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255'],
            'phone' => ['required', 'string', new AustralianPhoneNumber],
            'date_of_birth' => ['nullable', 'date', 'before:today'],
            'gender' => ['nullable', 'string', 'max:50'],
            'street_address' => ['nullable', 'string', 'max:255'],
            'suburb' => ['nullable', 'string', 'max:255'],
            'state' => ['nullable', 'string', 'max:50'],
            'postcode' => ['nullable', 'string', 'max:10'],
            'employment_type' => ['required', Rule::in(['Full-time', 'Part-time', 'Casual', 'Other'])],
            'job_title' => ['nullable', 'string', 'max:255'],
            'joining_date' => ['required', 'date'],
            'salary_type' => ['required', Rule::in(['Monthly', 'Daily', 'Hourly'])],
            'salary_rate' => ['required', 'numeric', 'min:0'],
            'overtime_rate_type' => ['nullable', Rule::in(['not_eligible', '1x', '1.5x', '2x', 'custom'])],
            'overtime_custom_type' => ['required_if:overtime_rate_type,custom', 'nullable', Rule::in(['multiplier', 'fixed_rate'])],
            'overtime_custom_rate' => ['required_if:overtime_rate_type,custom', 'nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string'],
            'profile_photo' => ['nullable', 'image', 'max:5120'],
        ];
    }
}
