<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ChangeStaffStatusRequest;
use App\Http\Requests\StoreStaffRequest;
use App\Http\Requests\UpdateStaffRequest;
use App\Http\Resources\StaffResource;
use App\Services\StaffService;
use App\Support\ApiResponse;
use App\Support\BusinessContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StaffController extends Controller
{
    public function __construct(private readonly StaffService $staffService) {}

    public function index(Request $request): JsonResponse
    {
        $business = BusinessContext::resolve();

        $paginator = $this->staffService->list($business, [
            'search' => $request->query('search'),
            'status' => $request->query('status'),
            'employment_type' => $request->query('employment_type'),
            'per_page' => $request->query('per_page'),
        ]);

        return ApiResponse::paginated($paginator, StaffResource::class, 'staff', 'Staff members retrieved successfully');
    }

    public function show(int $id): JsonResponse
    {
        $business = BusinessContext::resolve();
        $staff = $this->staffService->find($business, $id);

        return ApiResponse::success(new StaffResource($staff), 'Staff member retrieved successfully');
    }

    public function store(StoreStaffRequest $request): JsonResponse
    {
        $business = BusinessContext::resolve();
        $staff = $this->staffService->create($business, $request->validated());

        return ApiResponse::success(new StaffResource($staff), 'Staff created successfully', 201);
    }

    public function update(UpdateStaffRequest $request, int $id): JsonResponse
    {
        $business = BusinessContext::resolve();
        $staff = $this->staffService->find($business, $id);
        $staff = $this->staffService->update($staff, $request->validated());

        return ApiResponse::success(new StaffResource($staff), 'Staff updated successfully');
    }

    public function changeStatus(ChangeStaffStatusRequest $request, int $id): JsonResponse
    {
        $business = BusinessContext::resolve();
        $staff = $this->staffService->find($business, $id);
        $staff = $this->staffService->changeStatus($staff, $request->validated('status'));

        return ApiResponse::success(new StaffResource($staff), 'Staff status updated successfully');
    }
}
