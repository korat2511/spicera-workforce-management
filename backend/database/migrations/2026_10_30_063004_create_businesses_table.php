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
        Schema::create('businesses', function (Blueprint $table) {
            $table->id();
            $table->string('business_name');
            $table->string('owner_name');
            $table->string('email')->nullable();
            $table->string('phone');
            $table->string('street_address')->nullable();
            $table->string('suburb')->nullable();
            $table->string('state')->nullable();
            $table->string('postcode')->nullable();
            $table->string('country')->default('Australia');
            $table->string('currency')->default('AUD');
            $table->string('timezone')->default('Australia/Sydney');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('businesses');
    }
};
