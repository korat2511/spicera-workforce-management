<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AttendancePunchRequest;
use App\Http\Resources\AttendanceRecordResource;
use App\Models\KioskDevice;
use App\Services\AttendanceService;
use App\Support\ApiResponse;
use App\Support\BusinessContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class AttendanceController extends Controller
{
    public function __construct(private readonly AttendanceService $attendanceService) {}

    public function punch(AttendancePunchRequest $request): JsonResponse
    {
        $business = BusinessContext::resolve();
        $staff = $this->attendanceService->findStaffByPin($business, $request->validated('pin'));

        if (! $staff) {
            throw ValidationException::withMessages([
                'pin' => ['Invalid PIN. Please try again.'],
            ]);
        }

        /** @var KioskDevice|null $device */
        $device = $request->attributes->get('kioskDevice');

        $record = $this->attendanceService->punch($business, $staff, $request->file('photo'), $device);

        return ApiResponse::success(new AttendanceRecordResource($record), 'Attendance recorded successfully', 201);
    }

    public function index(Request $request): JsonResponse
    {
        $business = BusinessContext::resolve();

        $paginator = $this->attendanceService->list($business, [
            'search' => $request->query('search'),
            'staff_id' => $request->query('staff_id'),
            'status' => $request->query('status'),
            'date_from' => $request->query('date_from'),
            'date_to' => $request->query('date_to'),
            'per_page' => $request->query('per_page'),
        ]);

        return ApiResponse::paginated($paginator, AttendanceRecordResource::class, 'attendance', 'Attendance records retrieved successfully');
    }
}
