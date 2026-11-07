<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_web_login_accepts_username_or_email_and_updates_last_login(): void
    {
        $user = User::factory()->create(['name' => 'dashboard-user']);

        $this->post('/login', [
            'login' => 'dashboard-user',
            'password' => 'password',
        ])->assertRedirect('/dashboard')
            ->assertSessionHasNoErrors();
        $this->assertAuthenticatedAs($user, 'web');

        $this->assertNotNull($user->fresh()->last_login_at);
        $this->post('/logout')->assertRedirect('/login');
        $this->assertGuest('web');

        $this->post('/login', [
            'login' => $user->email,
            'password' => 'password',
        ])->assertRedirect('/dashboard')
            ->assertSessionHasNoErrors();
        $this->assertAuthenticatedAs($user, 'web');
    }

    public function test_login_is_limited_to_five_attempts_per_minute(): void
    {
        RateLimiter::clear('127.0.0.1');

        for ($attempt = 0; $attempt < 5; $attempt++) {
            $this->post('/login', ['login' => 'missing-user', 'password' => 'wrong']);
        }

        $this->post('/login', ['login' => 'missing-user', 'password' => 'wrong'])
            ->assertStatus(429);
    }

    public function test_dashboard_data_requires_a_web_session(): void
    {
        $this->getJson('/dashboard/data/latest')->assertUnauthorized();
        $this->getJson('/dashboard/data/stats?device=d1')->assertUnauthorized();
    }

    public function test_authenticated_root_redirects_to_dashboard(): void
    {
        $this->actingAs(User::factory()->create(), 'web')
            ->get('/')
            ->assertRedirect('/dashboard');
    }

    public function test_regular_user_can_load_dashboard_with_read_only_system_settings(): void
    {
        $this->actingAs(User::factory()->create(), 'web')
            ->get('/dashboard')
            ->assertOk()
            ->assertSee('Ringkasan kondisi')
            ->assertSee('Pompa otomatis')
            ->assertDontSee('Kapasitas (liter)');
    }

    public function test_user_cannot_open_admin_dashboard_or_change_admin_settings(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'web');

        $this->get('/dashboard/users')->assertForbidden();
        $this->putJson('/dashboard/data/settings', ['batas_air' => 40])->assertForbidden();
        $this->putJson('/dashboard/data/settings', ['automatic_pump' => false])
            ->assertOk()
            ->assertJsonPath('automatic_pump', false);
    }

    public function test_admin_can_open_user_management_and_change_system_settings(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin, 'web');

        $this->get('/dashboard/users')->assertOk()->assertSee('Kelola user');
        $this->putJson('/dashboard/data/settings', [
            'capacity_liters' => 1500,
            'pump_on_level' => 10,
            'pump_off_level' => 90,
        ])
            ->assertOk()
            ->assertJsonPath('capacity_liters', 1500)
            ->assertJsonPath('pump_on_level', 10)
            ->assertJsonPath('pump_off_level', 90);
    }

    public function test_user_management_requires_approval_and_prevents_self_deletion(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $this->actingAs($admin, 'web');

        $this->putJson("/dashboard/data/users/{$user->id}", ['username' => 'updated-name'])
            ->assertUnprocessable();
        $this->putJson("/dashboard/data/users/{$user->id}", [
            'username' => 'updated-name',
            'user_approved' => true,
        ])->assertOk()->assertJsonPath('name', 'updated-name');
        $this->deleteJson("/dashboard/data/users/{$admin->id}")->assertUnprocessable();
    }

    public function test_make_admin_command_prompts_for_and_hashes_password(): void
    {
        $this->artisan('app:make-admin', [
            'name' => 'created-admin',
            'email' => 'created-admin@example.com',
        ])
            ->expectsQuestion('Password (minimum 6 characters)', 'secret123')
            ->expectsQuestion('Confirm password', 'secret123')
            ->expectsOutput('Admin created-admin berhasil dibuat.')
            ->assertExitCode(0);

        $admin = User::where('email', 'created-admin@example.com')->firstOrFail();
        $this->assertSame('admin', $admin->role);
        $this->assertTrue(Hash::check('secret123', $admin->password));
    }
}
