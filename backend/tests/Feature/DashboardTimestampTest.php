<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardTimestampTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_tables_format_timestamps_in_wib(): void
    {
        $this->actingAs(User::factory()->create(['role' => 'admin']), 'web')
            ->get('/dashboard/users')
            ->assertOk()
            ->assertSee("timeZone: 'Asia/Jakarta'", false)
            ->assertSee(
                "return `\${part('day')}/\${part('month')}/\${part('year')} \${part('hour')}.\${part('minute')}`;",
                false,
            )
            ->assertSee('formatWibTimestamp(row.created_at)', false)
            ->assertSee('formatWibTimestamp(row.started_at)', false)
            ->assertSee('formatWibTimestamp(row.ended_at)', false)
            ->assertSee('formatWibTimestamp(user.last_login_at)', false);
    }

    public function test_stats_chart_parses_utc_hours_and_formats_axis_and_tooltip_in_wib(): void
    {
        $this->actingAs(User::factory()->create(), 'web')
            ->get('/dashboard')
            ->assertOk()
            ->assertSee("const isoValue = value.replace(' ', 'T');", false)
            ->assertSee('`${isoValue}Z`', false)
            ->assertSee('formatWibTimestamp(parseUtcHour(point.hour), false)', false)
            ->assertSee('title: (items) =>', false)
            ->assertSee('formatWibTimestamp(parseUtcHour(point.hour))', false)
            ->assertSee("timeZone: 'Asia/Jakarta'", false);
    }
}
