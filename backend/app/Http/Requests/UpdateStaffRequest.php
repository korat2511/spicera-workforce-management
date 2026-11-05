<?php

namespace App\Http\Requests;

use App\Rules\AustralianPhoneNumber;
use App\Support\BusinessContext;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateStaffRequest extends FormRequest
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
     * PUT requires the core fields (full replace); PATCH treats every
     * field as optional so partial updates work, leaving fields not
     * submitted untouched.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $businessId = BusinessContext::resolve()->id;
        $staffId = $this->route('id');
        $required = $this->isMethod('put') ? 'required' : 'sometimes';

        return [
            'staff_code' => [
                'sometimes',
                'string',
                'max:50',
                Rule::unique('staff', 'staff_code')->where('business_id', $businessId)->ignore($staffId),
            ],
            'first_name' => [$required, 'string', 'max:255'],
            'last_name' => [$required, 'string', 'max:255'],
            'email' => ['sometimes', 'nullable', 'email', 'max:255'],
            'phone' => [$required, 'string', new AustralianPhoneNumber],
            'date_of_birth' => ['sometimes', 'nullable', 'date', 'before:today'],
            'gender' => ['sometimes', 'nullable', 'string', 'max:50'],
            'street_address' => ['sometimes', 'nullable', 'string', 'max:255'],
            'suburb' => ['sometimes', 'nullable', 'string', 'max:255'],
            'state' => ['sometimes', 'nullable', 'string', 'max:50'],
            'postcode' => ['sometimes', 'nullable', 'string', 'max:10'],
            'employment_type' => [$required, Rule::in(['Full-time', 'Part-time', 'Casual', 'Other'])],
            'job_title' => ['sometimes', 'nullable', 'string', 'max:255'],
            'joining_date' => [$required, 'date'],
            'salary_type' => [$required, Rule::in(['Monthly', 'Daily', 'Hourly'])],
            'salary_rate' => [$required, 'numeric', 'min:0'],
            'notes' => ['sometimes', 'nullable', 'string'],
            'profile_photo' => ['sometimes', 'nullable', 'image', 'max:5120'],
        ];
    }
}
