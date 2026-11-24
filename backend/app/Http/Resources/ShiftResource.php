<?php

namespace App\Http\Resources;

use App\Models\Shift;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @property Shift $resource
 */
class ShiftResource extends JsonResource
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
            'name' => $this->name,
            'shift_type' => $this->shift_type,
            'description' => $this->description,
            'start_time' => $this->start_time?->format('H:i'),
            'end_time' => $this->end_time?->format('H:i'),
            'duration_hours' => $this->durationHours(),
            'status' => $this->status,
            'break_duration_minutes' => $this->break_duration_minutes,
            'grace_period_minutes' => $this->grace_period_minutes,
            'scheduled_days' => $this->scheduledDayLabels(),
            'staff_count' => $this->whenCounted('staff'),
            'assigned_staff' => $this->whenLoaded('staff', fn () => $this->staff->map(fn ($staff) => [
                'id' => $staff->id,
                'full_name' => $staff->full_name,
            ])),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
