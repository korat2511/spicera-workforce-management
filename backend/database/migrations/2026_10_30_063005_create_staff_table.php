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
        Schema::create('staff', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained('businesses')->cascadeOnDelete();
            $table->string('staff_code');
            $table->string('first_name');
            $table->string('last_name');
            $table->string('email')->nullable();
            $table->string('phone');
            $table->date('date_of_birth')->nullable();
            $table->string('gender')->nullable();
            $table->string('street_address')->nullable();
            $table->string('suburb')->nullable();
            $table->string('state')->nullable();
            $table->string('postcode')->nullable();
            $table->string('employment_type');
            $table->string('job_title')->nullable();
            $table->date('joining_date');
            $table->string('salary_type');
            $table->decimal('salary_rate', 10, 2);
            $table->string('status')->default('active');
            $table->string('profile_photo')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['business_id', 'staff_code']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('staff');
    }
};
