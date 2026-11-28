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
        Schema::table('staff', function (Blueprint $table) {
            $table->decimal('daily_hour_limit', 5, 2)->nullable()->after('overtime_custom_rate');
            $table->decimal('monthly_hour_limit', 6, 2)->nullable()->after('daily_hour_limit');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('staff', function (Blueprint $table) {
            $table->dropColumn(['daily_hour_limit', 'monthly_hour_limit']);
        });
    }
};
