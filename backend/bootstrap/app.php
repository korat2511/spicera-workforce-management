<?php

use App\Support\ApiResponse;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $isApiRequest = fn (Request $request): bool => $request->is('api/*') || $request->expectsJson();

        $exceptions->shouldRenderJsonWhen($isApiRequest);

        $exceptions->render(function (ValidationException $e, Request $request) use ($isApiRequest) {
            if (! $isApiRequest($request)) {
                return null;
            }

            return ApiResponse::error('Validation failed', 422, $e->errors());
        });

        $exceptions->render(function (ModelNotFoundException $e, Request $request) use ($isApiRequest) {
            if (! $isApiRequest($request)) {
                return null;
            }

            return ApiResponse::error('Resource not found', 404);
        });

        $exceptions->render(function (NotFoundHttpException $e, Request $request) use ($isApiRequest) {
            if (! $isApiRequest($request)) {
                return null;
            }

            return ApiResponse::error('Resource not found', 404);
        });

        $exceptions->render(function (AuthenticationException $e, Request $request) use ($isApiRequest) {
            if (! $isApiRequest($request)) {
                return null;
            }

            return ApiResponse::error('Unauthenticated', 401);
        });

        $exceptions->render(function (Throwable $e, Request $request) use ($isApiRequest) {
            if (! $isApiRequest($request)) {
                return null;
            }

            // Let other, more specific handlers above take any already-matched cases.
            if ($e instanceof HttpExceptionInterface && $e->getStatusCode() < 500) {
                return ApiResponse::error($e->getMessage() ?: 'Request failed', $e->getStatusCode());
            }

            if (config('app.debug')) {
                return null; // fall through to Laravel's default detailed renderer locally
            }

            return ApiResponse::error('Something went wrong. Please try again later.', 500);
        });
    })->create();
