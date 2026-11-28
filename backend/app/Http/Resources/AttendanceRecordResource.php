<?php

namespace App\Http\Resources;

use App\Models\AttendanceRecord;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

/**
 * @property AttendanceRecord $resource
 */
class AttendanceRecordResource extends JsonResource
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
            'type' => $this->type,
            'recorded_at' => $this->recorded_at?->toIso8601String(),
            'status' => $this->status,
            'photo_url' => $this->photo_path ? Storage::disk('public')->url($this->photo_path) : null,
            'staff' => [
                'id' => $this->staff->id,
                'staff_code' => $this->staff->staff_code,
                'full_name' => $this->staff->full_name,
            ],
            'shift' => $this->shift ? [
                'id' => $this->shift->id,
                'name' => $this->shift->name,
            ] : null,
        ];
    }
}
