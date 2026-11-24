<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('shifts', function (Blueprint $table) {
            $table->string('shift_type')->nullable()->after('name');
            $table->string('description')->nullable()->after('shift_type');
            $table->string('status')->default('active')->after('end_time');
            $table->unsignedInteger('break_duration_minutes')->default(15)->after('status');
            $table->unsignedInteger('grace_period_minutes')->default(10)->after('break_duration_minutes');
            $table->json('scheduled_days')->nullable()->after('grace_period_minutes');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('shifts', function (Blueprint $table) {
            $table->dropColumn([
                'shift_type',
                'description',
                'status',
                'break_duration_minutes',
                'grace_period_minutes',
                'scheduled_days',
            ]);
        });
    }
};
