<?php

namespace App\Services;

use App\Models\Business;
use App\Models\Shift;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Validation\ValidationException;

class ShiftService
{
    /**
     * @param  array{search?: ?string, status?: ?string}  $filters
     * @return Collection<int, Shift>
     */
    public function list(Business $business, array $filters): Collection
    {
        $query = Shift::query()
            ->withCount('staff')
            ->with(['staff' => fn ($q) => $q->orderBy('first_name')->limit(5)])
            ->where('business_id', $business->id);

        if (! empty($filters['search'])) {
            $query->where('name', 'like', '%'.$filters['search'].'%');
        }

        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        return $query->orderBy('start_time')->get();
    }

    public function find(Business $business, int $id): Shift
    {
        return Shift::withCount('staff')
            ->with(['staff' => fn ($q) => $q->orderBy('first_name')->limit(5)])
            ->where('business_id', $business->id)
            ->findOrFail($id);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function create(Business $business, array $data): Shift
    {
        $data['business_id'] = $business->id;
        $data['status'] = $data['status'] ?? 'active';

        $shift = Shift::create($data);

        return $this->find($business, $shift->id);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function update(Shift $shift, array $data): Shift
    {
        $shift->fill($data)->save();

        return $this->find($shift->business, $shift->id);
    }

    public function changeStatus(Shift $shift, string $status): Shift
    {
        $shift->update(['status' => $status]);

        return $this->find($shift->business, $shift->id);
    }

    public function delete(Shift $shift): void
    {
        if ($shift->staff()->exists()) {
            throw ValidationException::withMessages([
                'shift' => ['Reassign or unassign staff from this shift before deleting it.'],
            ]);
        }

        $shift->delete();
    }
}
