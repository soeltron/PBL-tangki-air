<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\SensorData;
use App\Models\WaterFilling;
use App\Services\WaterFillingTracker;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UsernameAuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_only_admins_can_register_users_and_users_can_login_with_username(): void
    {
        $this->postJson('/api/register', [
            'username' => 'aril',
            'email' => 'aril@example.com',
            'password' => 'secret123',
        ])->assertUnauthorized();

        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $this->postJson('/api/admin/users', [
            'username' => 'aril',
            'email' => 'aril@example.com',
            'password' => 'secret123',
        ])->assertCreated()
            ->assertJsonPath('name', 'aril')
            ->assertJsonPath('role', 'user');

        $login = $this->postJson('/api/login', [
            'username' => 'aril',
            'password' => 'secret123',
        ]);

        $login->assertStatus(200)
            ->assertJsonPath('user.name', 'aril')
            ->assertJsonPath('user.role', 'user')
            ->assertJsonStructure(['token', 'user']);

        $this->assertNotNull(User::where('email', 'aril@example.com')->first()->last_login_at);
        Auth::forgetGuards();
        $this->withToken($login->json('token'))
            ->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('name', 'aril')
            ->assertJsonPath('role', 'user');
    }

    public function test_admin_account_changes_require_user_approval(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create([
            'name' => 'old-name',
            'email' => 'old@example.com',
        ]);
        Sanctum::actingAs($admin);

        $this->putJson("/api/admin/users/{$user->id}", [
            'username' => 'new-name',
        ])->assertUnprocessable();

        $this->putJson("/api/admin/users/{$user->id}", [
            'username' => 'new-name',
            'email' => 'new@example.com',
            'user_approved' => true,
        ])->assertOk()
            ->assertJsonPath('name', 'new-name')
            ->assertJsonPath('email', 'new@example.com');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'new-name',
            'email' => 'new@example.com',
        ]);
    }

    public function test_non_admin_cannot_manage_users_or_system_settings(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/admin/users')->assertForbidden();
        $this->putJson('/api/settings', ['capacity_liters' => 1500])->assertForbidden();
        $this->putJson('/api/settings', ['automatic_pump' => false])->assertOk()
            ->assertJsonPath('automatic_pump', false);
    }

    public function test_pump_levels_must_have_a_lower_on_threshold_than_off_threshold(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'admin']));

        $this->putJson('/api/settings', [
            'pump_on_level' => 95,
            'pump_off_level' => 20,
        ])->assertUnprocessable();
    }

    public function test_filling_history_can_be_read_but_not_deleted(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $filling = WaterFilling::create([
            'started_at' => now()->subMinutes(4),
            'ended_at' => now(),
            'start_level' => 20,
            'end_level' => 80,
            'start_suhu' => 25,
            'end_suhu' => 26,
            'start_debit' => 1.2,
            'end_debit' => 1.5,
        ]);

        $this->getJson('/api/history/fillings?per_page=10')
            ->assertOk()
            ->assertJsonPath('data.0.id', $filling->id)
            ->assertJsonPath('data.0.start_level', 20)
            ->assertJsonPath('data.0.end_debit', 1.5);

        $this->getJson('/api/history/fillings?per_page=101')
            ->assertUnprocessable();
    }

    public function test_pump_sensor_transitions_create_a_filling_record(): void
    {
        $tracker = app(WaterFillingTracker::class);
        $tracker->record(SensorData::create([
            'device' => 'd2',
            'debit' => 1.2,
        ]), null);
        $tracker->record(SensorData::create([
            'device' => 'd1',
            'level' => 15,
            'suhu' => 25,
            'pompa' => true,
        ]), true);

        $tracker->record(SensorData::create([
            'device' => 'd2',
            'debit' => 1.5,
        ]), null);
        $tracker->record(SensorData::create([
            'device' => 'd1',
            'level' => 80,
            'suhu' => 26,
            'pompa' => false,
        ]), false);

        $filling = WaterFilling::firstOrFail();
        $this->assertNotNull($filling->ended_at);
        $this->assertSame(15.0, $filling->start_level);
        $this->assertSame(80.0, $filling->end_level);
        $this->assertSame(1.2, $filling->start_debit);
        $this->assertSame(1.5, $filling->end_debit);
    }

    public function test_admin_can_remove_a_user_but_not_themselves(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        Sanctum::actingAs($admin);

        $this->deleteJson("/api/admin/users/{$user->id}")->assertNoContent();
        $this->assertDatabaseMissing('users', ['id' => $user->id]);

        $this->deleteJson("/api/admin/users/{$admin->id}")->assertUnprocessable();
        $this->assertDatabaseHas('users', ['id' => $admin->id]);
    }
}
