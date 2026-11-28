<?php

namespace App\Http\Resources;

use App\Models\Staff;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

/**
 * @property Staff $resource
 */
class StaffResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'staff_code' => $this->staff_code,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'full_name' => $this->full_name,
            'email' => $this->email,
            'phone' => $this->phone,
            'date_of_birth' => $this->date_of_birth?->toDateString(),
            'gender' => $this->gender,
            'street_address' => $this->street_address,
            'suburb' => $this->suburb,
            'state' => $this->state,
            'postcode' => $this->postcode,
            'employment_type' => $this->employment_type,
            'job_title' => $this->job_title,
            'joining_date' => $this->joining_date?->toDateString(),
            'salary_type' => $this->salary_type,
            'salary_rate' => (string) $this->salary_rate,
            'overtime_rate_type' => $this->overtime_rate_type,
            'overtime_custom_type' => $this->overtime_custom_type,
            'overtime_custom_rate' => $this->overtime_custom_rate !== null ? (string) $this->overtime_custom_rate : null,
            'overtime_label' => $this->overtime_label,
            'daily_hour_limit' => $this->daily_hour_limit !== null ? (string) $this->daily_hour_limit : null,
            'weekly_hour_limit' => $this->weekly_hour_limit !== null ? (string) $this->weekly_hour_limit : null,
            'monthly_hour_limit' => $this->monthly_hour_limit !== null ? (string) $this->monthly_hour_limit : null,
            'currency' => $this->business?->currency,
            'status' => $this->status,
            'profile_photo' => $this->profile_photo ? Storage::url($this->profile_photo) : null,
            'notes' => $this->notes,
            'pin_set' => $this->pin_hash !== null,
            'shift' => $this->whenLoaded('shift', fn () => $this->shift ? new ShiftResource($this->shift) : null),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
