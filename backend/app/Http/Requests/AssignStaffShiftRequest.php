<?php

namespace App\Http\Requests;

use App\Support\BusinessContext;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class AssignStaffShiftRequest extends FormRequest
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
            'shift_id' => [
                'nullable',
                'integer',
                Rule::exists('shifts', 'id')->where('business_id', $businessId),
            ],
        ];
    }
}
