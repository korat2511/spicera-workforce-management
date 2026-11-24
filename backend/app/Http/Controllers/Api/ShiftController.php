<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ChangeShiftStatusRequest;
use App\Http\Requests\StoreShiftRequest;
use App\Http\Requests\UpdateShiftRequest;
use App\Http\Resources\ShiftResource;
use App\Services\ShiftService;
use App\Support\ApiResponse;
use App\Support\BusinessContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShiftController extends Controller
{
    public function __construct(private readonly ShiftService $shiftService) {}

    public function index(Request $request): JsonResponse
    {
        $business = BusinessContext::resolve();

        $shifts = $this->shiftService->list($business, [
            'search' => $request->query('search'),
            'status' => $request->query('status'),
        ]);

        return ApiResponse::success(
            ShiftResource::collection($shifts),
            'Shifts retrieved successfully',
        );
    }

    public function show(int $id): JsonResponse
    {
        $business = BusinessContext::resolve();
        $shift = $this->shiftService->find($business, $id);

        return ApiResponse::success(new ShiftResource($shift), 'Shift retrieved successfully');
    }

    public function store(StoreShiftRequest $request): JsonResponse
    {
        $business = BusinessContext::resolve();
        $shift = $this->shiftService->create($business, $request->validated());

        return ApiResponse::success(new ShiftResource($shift), 'Shift created successfully', 201);
    }

    public function update(UpdateShiftRequest $request, int $id): JsonResponse
    {
        $business = BusinessContext::resolve();
        $shift = $this->shiftService->find($business, $id);
        $shift = $this->shiftService->update($shift, $request->validated());

        return ApiResponse::success(new ShiftResource($shift), 'Shift updated successfully');
    }

    public function changeStatus(ChangeShiftStatusRequest $request, int $id): JsonResponse
    {
        $business = BusinessContext::resolve();
        $shift = $this->shiftService->find($business, $id);
        $shift = $this->shiftService->changeStatus($shift, $request->validated('status'));

        return ApiResponse::success(new ShiftResource($shift), 'Shift status updated successfully');
    }

    public function destroy(int $id): JsonResponse
    {
        $business = BusinessContext::resolve();
        $shift = $this->shiftService->find($business, $id);
        $this->shiftService->delete($shift);

        return ApiResponse::success(null, 'Shift deleted successfully');
    }
}
