# Deployment — Hostinger

Target: `spicera-workforce.velocoresolutions.com`, custom folder
`/home/u427491165/domains/velocoresolutions.com/public_html/spicera-workforce`
(per hPanel → Domains → Subdomains).

## One-time setup in hPanel

1. **PHP version** — set this subdomain's PHP version to **8.4** (hPanel →
   Advanced → PHP Configuration, select the site). Laravel 13 requires PHP
   ≥8.2; the app is developed/tested against 8.4, so pin it to match. ✅ done.
2. **Document root** — this Hostinger plan has no per-subdomain "document
   root" setting, so the subdomain's webroot is the project root itself
   (`spicera-workforce/`), not `public/`. Instead of relying on a docroot
   setting, the committed root **`.htaccess`** transparently rewrites every
   request into `public/` (which has its own Laravel-shipped `.htaccess`
   that dispatches to `index.php`), and explicitly blocks direct access to
   `.env`. This file must always be deployed alongside the app — if it's
   ever missing, the site falls back to Hostinger's generic 404 page.
3. **MySQL database** — already created: `u427491165_spicera`
   (hPanel → Databases). Grab the DB username/password from hPanel when
   writing the production `.env` (do not paste them into chat/memory).
4. **SSL** — confirm Hostinger's free HTTPS is active for the subdomain. ✅ done.
5. **`exec()` is disabled** on this host (shared-hosting hardening). This
   breaks `php artisan storage:link` (it shells out internally) — create
   the symlink manually instead: `ln -sfn ../storage/app/public public/storage`.

## Deploy steps

```bash
# From the backend/ directory, on the server (via SSH) or via a CI step:
composer install --no-dev --optimize-autoloader

cp .env.example .env   # first deploy only — then edit in place after
php artisan key:generate

# Edit .env: set APP_ENV=production, APP_DEBUG=false, APP_URL to the
# subdomain, and the real DB_DATABASE/DB_USERNAME/DB_PASSWORD from hPanel.

php artisan migrate --force
php artisan db:seed --class=BusinessSeeder --force

# storage:link's internal exec() call is blocked on this host — do it manually:
ln -sfn ../storage/app/public public/storage

# Cache config/routes for production performance:
php artisan config:cache
php artisan route:cache
```

## Permissions

Ensure the web server user can write to:

```bash
chmod -R 775 storage bootstrap/cache
```

## Verifying the deploy

```bash
curl https://spicera-workforce.velocoresolutions.com/api/health
# {"status":"ok","message":"API is running","timestamp":"..."}

curl https://spicera-workforce.velocoresolutions.com/api/v1/staff
# {"success":true,"message":"Staff members retrieved successfully","data":{...}}
```

## Notes

- **Never run `php artisan db:seed --class=StaffSeeder` (or the bare
  `--seed`/`migrate --seed` flag, which runs the full `DatabaseSeeder` and
  therefore `StaffSeeder` too) in production.** `StaffSeeder` depends on
  `fakerphp/faker`, which is a `require-dev`-only package and is correctly
  absent after `composer install --no-dev` — running it will fail with
  `Call to undefined function fake()`. Only `BusinessSeeder` (no Faker
  dependency, idempotent via `firstOrCreate`) is safe to run in production.
- Cron jobs, queue workers are not needed for Phase 1 (no async work yet).
- Re-run `php artisan config:cache` / `route:cache` after every subsequent
  deploy that changes `.env` or routes.
