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
            $table->string('overtime_rate_type')->default('not_eligible')->after('salary_rate');
            $table->string('overtime_custom_type')->nullable()->after('overtime_rate_type');
            $table->decimal('overtime_custom_rate', 10, 2)->nullable()->after('overtime_custom_type');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('staff', function (Blueprint $table) {
            $table->dropColumn(['overtime_rate_type', 'overtime_custom_type', 'overtime_custom_rate']);
        });
    }
};
