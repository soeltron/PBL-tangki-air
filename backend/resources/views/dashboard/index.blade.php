@extends('layouts.dashboard')

@section('title', 'Dashboard Tandon')

@section('content')
@php($isAdmin = auth()->user()->role === 'admin')
<div class="min-h-screen">
    <header class="border-b border-slate-800 bg-slate-900/80">
        <div class="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4 px-4 py-4 sm:px-6">
            <div>
                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-400">Monitoring Tandon</p>
                <h1 class="mt-1 text-xl font-bold">Dashboard</h1>
            </div>
            <div class="flex items-center gap-4">
                <div class="text-right">
                    <p class="font-medium">{{ auth()->user()->name }}</p>
                    <p class="text-xs text-slate-400">{{ $isAdmin ? 'Administrator' : 'Pengguna' }}</p>
                </div>
                <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button class="rounded-lg border border-slate-700 px-3 py-2 text-sm hover:bg-slate-800">Keluar</button>
                </form>
            </div>
        </div>
    </header>

    <main class="mx-auto max-w-7xl px-4 py-6 sm:px-6">
        <nav class="mb-6 flex gap-2 overflow-x-auto pb-2" aria-label="Navigasi dashboard">
            @foreach ([
                'overview' => 'Ringkasan',
                'stats' => 'Statistik',
                'history' => 'Riwayat Telemetri',
                'fillings' => 'Riwayat Pengisian',
                'settings' => 'Pengaturan',
            ] as $key => $label)
                <button type="button" data-nav="{{ $key }}"
                    class="nav-button whitespace-nowrap rounded-xl border border-slate-800 px-4 py-2 text-sm hover:border-cyan-500">
                    {{ $label }}
                </button>
            @endforeach
            @if ($isAdmin)
                <a href="{{ route('dashboard.users') }}"
                    class="whitespace-nowrap rounded-xl border border-slate-800 px-4 py-2 text-sm hover:border-cyan-500">
                    Kelola User
                </a>
            @endif
        </nav>

        <div id="dashboard-error" class="mb-5 hidden rounded-xl border border-rose-900 bg-rose-950/60 p-4 text-sm text-rose-200" role="alert"></div>
        <div id="dashboard-notice" class="mb-5 hidden rounded-xl border border-emerald-900 bg-emerald-950/60 p-4 text-sm text-emerald-200" role="status"></div>

        <section data-section="overview" class="dashboard-section">
            <div class="mb-5 flex flex-wrap items-end justify-between gap-3">
                <div>
                    <h2 class="text-2xl font-bold">Ringkasan kondisi</h2>
                    <p class="mt-1 text-sm text-slate-400">Data terbaru diperbarui otomatis setiap 5 detik.</p>
                </div>
                <p id="latest-updated" class="text-xs text-slate-500"></p>
            </div>
            <div class="grid gap-5 lg:grid-cols-2">
                @foreach (['d1' => 'Perangkat D1', 'd2' => 'Perangkat D2'] as $device => $label)
                    <article class="rounded-2xl border border-slate-800 bg-slate-900 p-5">
                        <div class="mb-4 flex items-center justify-between">
                            <h3 class="font-semibold">{{ $label }}</h3>
                            <span id="{{ $device }}-time" class="text-xs text-slate-500">Menunggu data</span>
                        </div>
                        <div class="grid grid-cols-2 gap-3">
                            @foreach (['level' => 'Level', 'suhu' => 'Suhu', 'debit' => 'Debit', 'pompa' => 'Status pompa'] as $field => $title)
                                <div class="rounded-xl bg-slate-800/70 p-4">
                                    <p class="text-xs text-slate-400">{{ $title }}</p>
                                    <p id="{{ $device }}-{{ $field }}" class="mt-2 text-xl font-bold">—</p>
                                </div>
                            @endforeach
                        </div>
                    </article>
                @endforeach
            </div>
        </section>

        <section data-section="stats" class="dashboard-section hidden">
            <div class="mb-5">
                <h2 class="text-2xl font-bold">Statistik per jam</h2>
                <p class="mt-1 text-sm text-slate-400">Rata-rata, minimum, dan maksimum dari sensor_hourly_stats.</p>
            </div>
            <div class="mb-4 flex flex-wrap gap-3">
                <label class="text-sm text-slate-300">Perangkat
                    <select id="stats-device" class="ml-2 rounded-lg border border-slate-700 bg-slate-900 px-3 py-2">
                        <option value="d1">D1</option><option value="d2">D2</option>
                    </select>
                </label>
                <label class="text-sm text-slate-300">Rentang
                    <select id="stats-range" class="ml-2 rounded-lg border border-slate-700 bg-slate-900 px-3 py-2">
                        <option value="24h">24 jam</option><option value="7d">7 hari</option>
                    </select>
                </label>
                <label class="text-sm text-slate-300">Sensor
                    <select id="stats-metric" class="ml-2 rounded-lg border border-slate-700 bg-slate-900 px-3 py-2">
                        <option value="level">Level</option><option value="suhu">Suhu</option><option value="debit">Debit</option>
                    </select>
                </label>
            </div>
            <div class="rounded-2xl border border-slate-800 bg-slate-900 p-4 sm:p-6">
                <canvas id="stats-chart" height="110" aria-label="Grafik statistik per jam"></canvas>
            </div>
        </section>

        <section data-section="history" class="dashboard-section hidden">
            <div class="mb-5 flex flex-wrap items-center justify-between gap-3">
                <div>
                    <h2 class="text-2xl font-bold">Riwayat telemetri</h2>
                    <p class="mt-1 text-sm text-slate-400">Data sensor terbaru, 20 baris per halaman.</p>
                </div>
                <a id="history-export" href="/dashboard/data/history/export"
                    class="rounded-xl bg-cyan-500 px-4 py-2 text-sm font-semibold text-slate-950 hover:bg-cyan-400">
                    Export CSV
                </a>
            </div>
            <div class="overflow-x-auto rounded-2xl border border-slate-800 bg-slate-900">
                <table class="w-full min-w-[640px] text-left text-sm">
                    <thead class="bg-slate-800/70 text-slate-300"><tr><th class="p-3">Waktu</th><th class="p-3">Perangkat</th><th class="p-3">Level</th><th class="p-3">Suhu</th><th class="p-3">Debit</th></tr></thead>
                    <tbody id="history-rows" class="divide-y divide-slate-800"></tbody>
                </table>
            </div>
            <div class="mt-4 flex items-center justify-between text-sm">
                <span id="history-page" class="text-slate-400"></span>
                <div class="flex gap-2">
                    <button data-page-prev="history" class="rounded-lg border border-slate-700 px-3 py-2 disabled:opacity-40">Sebelumnya</button>
                    <button data-page-next="history" class="rounded-lg border border-slate-700 px-3 py-2 disabled:opacity-40">Berikutnya</button>
                </div>
            </div>
        </section>

        <section data-section="fillings" class="dashboard-section hidden">
            <div class="mb-5">
                <h2 class="text-2xl font-bold">Riwayat pengisian</h2>
                <p class="mt-1 text-sm text-slate-400">Siklus pengisian yang tercatat, 20 baris per halaman.</p>
            </div>
            <div class="overflow-x-auto rounded-2xl border border-slate-800 bg-slate-900">
                <table class="w-full min-w-[760px] text-left text-sm">
                    <thead class="bg-slate-800/70 text-slate-300"><tr><th class="p-3">Mulai</th><th class="p-3">Selesai</th><th class="p-3">Level awal</th><th class="p-3">Level akhir</th><th class="p-3">Debit awal</th><th class="p-3">Debit akhir</th></tr></thead>
                    <tbody id="fillings-rows" class="divide-y divide-slate-800"></tbody>
                </table>
            </div>
            <div class="mt-4 flex items-center justify-between text-sm">
                <span id="fillings-page" class="text-slate-400"></span>
                <div class="flex gap-2">
                    <button data-page-prev="fillings" class="rounded-lg border border-slate-700 px-3 py-2 disabled:opacity-40">Sebelumnya</button>
                    <button data-page-next="fillings" class="rounded-lg border border-slate-700 px-3 py-2 disabled:opacity-40">Berikutnya</button>
                </div>
            </div>
        </section>

        <section data-section="settings" class="dashboard-section hidden">
            <div class="mb-5">
                <h2 class="text-2xl font-bold">Pengaturan</h2>
                <p class="mt-1 text-sm text-slate-400">
                    {{ $isAdmin ? 'Admin dapat mengubah seluruh pengaturan sistem.' : 'Pengguna hanya dapat mengubah mode pompa otomatis.' }}
                </p>
            </div>
            <form id="settings-form" class="max-w-2xl space-y-5 rounded-2xl border border-slate-800 bg-slate-900 p-5">
                <label class="flex items-center justify-between gap-4 rounded-xl bg-slate-800/70 p-4">
                    <span><span class="block font-medium">Pompa otomatis</span><span class="text-xs text-slate-400">Aktifkan kendali otomatis.</span></span>
                    <input type="checkbox" name="automatic_pump" class="h-5 w-5 accent-cyan-400">
                </label>
                @if ($isAdmin)
                    <div class="grid gap-4 sm:grid-cols-2">
                        @foreach ([
                            'capacity_liters' => ['Kapasitas (liter)', 'min=0.01 step=any'],
                            'pump_on_level' => ['Level pompa menyala (%)', 'min=0 max=100 step=any'],
                            'pump_off_level' => ['Level pompa mati (%)', 'min=0 max=100 step=any'],
                            'batas_air' => ['Batas level (%)', 'min=0 max=100 step=any'],
                            'batas_suhu' => ['Batas suhu (°C)', 'min=0 max=100 step=any'],
                            'batas_debit' => ['Batas debit', 'min=0 step=any'],
                        ] as $field => [$label, $limits])
                            <label class="block text-sm font-medium">{{ $label }}
                                <input name="{{ $field }}" type="number" {{ $limits }}
                                    class="mt-2 w-full rounded-xl border border-slate-700 bg-slate-950 px-3 py-2">
                            </label>
                        @endforeach
                    </div>
                @endif
                <button class="rounded-xl bg-cyan-500 px-4 py-2 font-semibold text-slate-950 hover:bg-cyan-400">Simpan pengaturan</button>
            </form>
        </section>

        @if ($isAdmin)
            <section data-section="users" class="dashboard-section {{ $activeSection === 'users' ? '' : 'hidden' }}">
                <div class="mb-5">
                    <h2 class="text-2xl font-bold">Kelola user</h2>
                    <p class="mt-1 text-sm text-slate-400">Ubah akun memerlukan persetujuan eksplisit pemilik akun.</p>
                </div>
                <div class="grid gap-5 xl:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]">
                    <form id="user-create-form" class="h-fit space-y-4 rounded-2xl border border-slate-800 bg-slate-900 p-5">
                        <h3 class="font-semibold">Tambah user</h3>
                        <label class="block text-sm">Username<input name="username" required minlength="3" maxlength="100" class="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2"></label>
                        <label class="block text-sm">Email<input name="email" type="email" required maxlength="255" class="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2"></label>
                        <label class="block text-sm">Password<input name="password" type="password" required minlength="6" maxlength="255" autocomplete="new-password" class="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2"></label>
                        <button class="rounded-lg bg-cyan-500 px-4 py-2 font-semibold text-slate-950">Tambah</button>
                    </form>

                    <div class="overflow-x-auto rounded-2xl border border-slate-800 bg-slate-900">
                        <table class="w-full min-w-[600px] text-left text-sm">
                            <thead class="bg-slate-800/70 text-slate-300"><tr><th class="p-3">Username</th><th class="p-3">Email</th><th class="p-3">Role</th><th class="p-3">Login terakhir</th><th class="p-3">Aksi</th></tr></thead>
                            <tbody id="users-rows" class="divide-y divide-slate-800"></tbody>
                        </table>
                        <div class="flex items-center justify-between p-3 text-sm">
                            <span id="users-page" class="text-slate-400"></span>
                            <div class="flex gap-2">
                                <button data-page-prev="users" class="rounded-lg border border-slate-700 px-3 py-2 disabled:opacity-40">Sebelumnya</button>
                                <button data-page-next="users" class="rounded-lg border border-slate-700 px-3 py-2 disabled:opacity-40">Berikutnya</button>
                            </div>
                        </div>
                    </div>
                </div>
                <form id="user-edit-form" class="mt-5 hidden max-w-xl space-y-4 rounded-2xl border border-cyan-900 bg-slate-900 p-5">
                    <div class="flex items-center justify-between"><h3 class="font-semibold">Ubah akun</h3><button type="button" id="user-edit-cancel" class="text-sm text-slate-400">Batal</button></div>
                    <input type="hidden" name="id">
                    <label class="block text-sm">Username<input name="username" minlength="3" maxlength="100" class="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2"></label>
                    <label class="block text-sm">Email<input name="email" type="email" maxlength="255" class="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2"></label>
                    <label class="block text-sm">Password baru (opsional)<input name="password" type="password" minlength="6" maxlength="255" autocomplete="new-password" class="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2"></label>
                    <label class="flex items-start gap-2 text-sm"><input name="user_approved" type="checkbox" required class="mt-1 accent-cyan-400"><span>Saya telah memperoleh persetujuan user untuk perubahan ini.</span></label>
                    <button class="rounded-lg bg-cyan-500 px-4 py-2 font-semibold text-slate-950">Simpan perubahan</button>
                </form>
            </section>
        @endif
    </main>
</div>
@endsection

@push('scripts')
<script>
(() => {
    const isAdmin = @json($isAdmin);
    const initialSection = @json($activeSection);
    const csrf = document.querySelector('meta[name="csrf-token"]').content;
    const pages = { history: 1, fillings: 1, users: 1 };
    let chart;
    let usersById = {};

    const escapeHtml = (value) => String(value ?? '—').replace(/[&<>"']/g, (char) => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;'
    })[char]);
    const display = (value, suffix = '') => value === null || value === undefined ? '—' : `${escapeHtml(value)}${suffix}`;
    const showMessage = (id, message) => {
        const element = document.getElementById(id);
        element.textContent = message;
        element.classList.remove('hidden');
        window.setTimeout(() => element.classList.add('hidden'), 5000);
    };
    const request = async (url, options = {}) => {
        const response = await fetch(url, {
            ...options,
            headers: {
                Accept: 'application/json',
                ...(options.body ? { 'Content-Type': 'application/json' } : {}),
                ...(options.method && options.method !== 'GET' ? { 'X-CSRF-TOKEN': csrf } : {}),
                ...options.headers,
            },
        });
        const payload = response.status === 204 ? null : await response.json();
        if (!response.ok) {
            const errors = payload?.errors ? Object.values(payload.errors).flat().join(' ') : payload?.message;
            throw new Error(errors || `Permintaan gagal (${response.status}).`);
        }
        return payload;
    };
    const params = (page) => new URLSearchParams({ page: String(page), per_page: '20' });
    const setSection = (name) => {
        document.querySelectorAll('.dashboard-section').forEach((section) => {
            section.classList.toggle('hidden', section.dataset.section !== name);
        });
        document.querySelectorAll('.nav-button').forEach((button) => {
            button.classList.toggle('border-cyan-500', button.dataset.nav === name);
            button.classList.toggle('bg-slate-800', button.dataset.nav === name);
        });
        if (name === 'overview') loadLatest();
        if (name === 'stats') loadStats();
        if (name === 'history') loadHistory();
        if (name === 'fillings') loadFillings();
        if (name === 'settings') loadSettings();
        if (name === 'users' && isAdmin) loadUsers();
    };

    async function loadLatest() {
        try {
            const data = await request('/dashboard/data/latest');
            ['d1', 'd2'].forEach((device) => {
                const row = data[device];
                ['level', 'suhu', 'debit'].forEach((field) => {
                    document.getElementById(`${device}-${field}`).textContent = row
                        ? `${row[field] ?? '—'}${field === 'level' ? '%' : field === 'suhu' ? '°C' : ''}`
                        : '—';
                });
                document.getElementById(`${device}-pompa`).textContent = row?.pompa === null || row?.pompa === undefined
                    ? '—' : row.pompa ? 'Menyala' : 'Mati';
                document.getElementById(`${device}-time`).textContent = row?.created_at
                    ? new Date(row.created_at).toLocaleString('id-ID') : 'Belum ada data';
            });
            document.getElementById('latest-updated').textContent = `Diperbarui ${new Date().toLocaleTimeString('id-ID')}`;
        } catch (error) {
            showMessage('dashboard-error', error.message);
        }
    }

    async function loadStats() {
        try {
            const device = document.getElementById('stats-device').value;
            const range = document.getElementById('stats-range').value;
            const metric = document.getElementById('stats-metric').value;
            const query = new URLSearchParams({ device, range });
            const data = await request(`/dashboard/data/stats?${query}`);
            const labels = data.points.map((point) => new Date(point.hour.replace(' ', 'T')).toLocaleString('id-ID', {
                month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit'
            }));
            const options = {
                responsive: true,
                interaction: { mode: 'index', intersect: false },
                scales: { x: { ticks: { color: '#94a3b8', maxTicksLimit: 12 }, grid: { color: '#1e293b' } },
                    y: { ticks: { color: '#94a3b8' }, grid: { color: '#1e293b' } } },
                plugins: { legend: { labels: { color: '#e2e8f0' } } }
            };
            const datasets = [
                { key: `avg_${metric}`, label: 'Rata-rata', color: '#22d3ee' },
                { key: `min_${metric}`, label: 'Minimum', color: '#a78bfa' },
                { key: `max_${metric}`, label: 'Maksimum', color: '#fb7185' },
            ].map(({ key, label, color }) => ({
                label, data: data.points.map((point) => point[key]), borderColor: color,
                backgroundColor: color, tension: 0.25, spanGaps: true,
            }));
            if (chart) chart.destroy();
            chart = new Chart(document.getElementById('stats-chart'), {
                type: 'line', data: { labels, datasets }, options,
            });
        } catch (error) {
            showMessage('dashboard-error', error.message);
        }
    }

    async function loadHistory() {
        try {
            const data = await request(`/dashboard/data/history?${params(pages.history)}`);
            document.getElementById('history-rows').innerHTML = data.data.map((row) => `
                <tr><td class="p-3">${escapeHtml(row.created_at)}</td><td class="p-3">${escapeHtml(row.device)}</td>
                <td class="p-3">${display(row.level, '%')}</td><td class="p-3">${display(row.suhu, '°C')}</td>
                <td class="p-3">${display(row.debit)}</td></tr>`).join('') || '<tr><td colspan="5" class="p-4 text-center text-slate-400">Belum ada data.</td></tr>';
            document.getElementById('history-page').textContent = `Halaman ${data.current_page} dari ${data.last_page}`;
            document.querySelector('[data-page-prev="history"]').disabled = data.current_page <= 1;
            document.querySelector('[data-page-next="history"]').disabled = data.current_page >= data.last_page;
        } catch (error) { showMessage('dashboard-error', error.message); }
    }

    async function loadFillings() {
        try {
            const data = await request(`/dashboard/data/fillings?${params(pages.fillings)}`);
            document.getElementById('fillings-rows').innerHTML = data.data.map((row) => `
                <tr><td class="p-3">${escapeHtml(row.started_at)}</td><td class="p-3">${escapeHtml(row.ended_at)}</td>
                <td class="p-3">${display(row.start_level, '%')}</td><td class="p-3">${display(row.end_level, '%')}</td>
                <td class="p-3">${display(row.start_debit)}</td><td class="p-3">${display(row.end_debit)}</td></tr>`).join('') || '<tr><td colspan="6" class="p-4 text-center text-slate-400">Belum ada riwayat pengisian.</td></tr>';
            document.getElementById('fillings-page').textContent = `Halaman ${data.current_page} dari ${data.last_page}`;
            document.querySelector('[data-page-prev="fillings"]').disabled = data.current_page <= 1;
            document.querySelector('[data-page-next="fillings"]').disabled = data.current_page >= data.last_page;
        } catch (error) { showMessage('dashboard-error', error.message); }
    }

    async function loadSettings() {
        try {
            const settings = await request('/dashboard/data/settings');
            const form = document.getElementById('settings-form');
            form.elements.automatic_pump.checked = Boolean(settings.automatic_pump);
            if (isAdmin) {
                ['capacity_liters', 'pump_on_level', 'pump_off_level', 'batas_air', 'batas_suhu', 'batas_debit']
                    .forEach((field) => { form.elements[field].value = settings[field] ?? ''; });
            }
        } catch (error) { showMessage('dashboard-error', error.message); }
    }

    async function loadUsers() {
        try {
            const data = await request(`/dashboard/data/users?${params(pages.users)}`);
            usersById = Object.fromEntries(data.data.map((user) => [user.id, user]));
            document.getElementById('users-rows').innerHTML = data.data.map((user) => `
                <tr><td class="p-3">${escapeHtml(user.name)}</td><td class="p-3">${escapeHtml(user.email)}</td>
                <td class="p-3">${escapeHtml(user.role)}</td><td class="p-3">${escapeHtml(user.last_login_at)}</td>
                <td class="flex gap-2 p-3">
                    <button data-edit-user="${user.id}" class="text-cyan-300 hover:underline">Ubah</button>
                    ${user.id === @json(auth()->id()) ? '' : `<button data-delete-user="${user.id}" class="text-rose-300 hover:underline">Hapus</button>`}
                </td></tr>`).join('') || '<tr><td colspan="5" class="p-4 text-center text-slate-400">Belum ada user.</td></tr>';
            document.getElementById('users-page').textContent = `Halaman ${data.current_page} dari ${data.last_page}`;
            document.querySelector('[data-page-prev="users"]').disabled = data.current_page <= 1;
            document.querySelector('[data-page-next="users"]').disabled = data.current_page >= data.last_page;
        } catch (error) { showMessage('dashboard-error', error.message); }
    }

    document.querySelectorAll('[data-nav]').forEach((button) => button.addEventListener('click', () => setSection(button.dataset.nav)));
    document.querySelectorAll('[data-page-prev]').forEach((button) => button.addEventListener('click', () => {
        const name = button.dataset.pagePrev;
        pages[name] = Math.max(1, pages[name] - 1);
        ({ history: loadHistory, fillings: loadFillings, users: loadUsers })[name]();
    }));
    document.querySelectorAll('[data-page-next]').forEach((button) => button.addEventListener('click', () => {
        const name = button.dataset.pageNext;
        pages[name] += 1;
        ({ history: loadHistory, fillings: loadFillings, users: loadUsers })[name]();
    }));
    ['stats-device', 'stats-range', 'stats-metric'].forEach((id) => {
        document.getElementById(id).addEventListener('change', loadStats);
    });

    document.getElementById('settings-form').addEventListener('submit', async (event) => {
        event.preventDefault();
        const form = event.currentTarget;
        const body = { automatic_pump: form.elements.automatic_pump.checked };
        if (isAdmin) {
            ['capacity_liters', 'pump_on_level', 'pump_off_level', 'batas_air', 'batas_suhu', 'batas_debit']
                .forEach((field) => { body[field] = Number(form.elements[field].value); });
        }
        try {
            await request('/dashboard/data/settings', { method: 'PUT', body: JSON.stringify(body) });
            showMessage('dashboard-notice', 'Pengaturan berhasil disimpan.');
        } catch (error) { showMessage('dashboard-error', error.message); }
    });

    if (isAdmin) {
        document.getElementById('user-create-form').addEventListener('submit', async (event) => {
            event.preventDefault();
            const body = Object.fromEntries(new FormData(event.currentTarget));
            try {
                await request('/dashboard/data/users', { method: 'POST', body: JSON.stringify(body) });
                event.currentTarget.reset();
                await loadUsers();
                showMessage('dashboard-notice', 'User berhasil ditambahkan.');
            } catch (error) { showMessage('dashboard-error', error.message); }
        });
        document.getElementById('users-rows').addEventListener('click', async (event) => {
            const editButton = event.target.closest('[data-edit-user]');
            const deleteButton = event.target.closest('[data-delete-user]');
            if (editButton) {
                const user = usersById[editButton.dataset.editUser];
                const form = document.getElementById('user-edit-form');
                form.elements.id.value = user.id;
                form.elements.username.value = user.name;
                form.elements.email.value = user.email;
                form.elements.password.value = '';
                form.elements.user_approved.checked = false;
                form.classList.remove('hidden');
                form.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
            if (deleteButton && window.confirm('Hapus user ini?')) {
                try {
                    await request(`/dashboard/data/users/${deleteButton.dataset.deleteUser}`, { method: 'DELETE' });
                    await loadUsers();
                    showMessage('dashboard-notice', 'User berhasil dihapus.');
                } catch (error) { showMessage('dashboard-error', error.message); }
            }
        });
        document.getElementById('user-edit-cancel').addEventListener('click', () => {
            document.getElementById('user-edit-form').classList.add('hidden');
        });
        document.getElementById('user-edit-form').addEventListener('submit', async (event) => {
            event.preventDefault();
            const form = event.currentTarget;
            const body = {
                username: form.elements.username.value,
                email: form.elements.email.value,
                user_approved: form.elements.user_approved.checked,
            };
            if (form.elements.password.value) body.password = form.elements.password.value;
            try {
                await request(`/dashboard/data/users/${form.elements.id.value}`, {
                    method: 'PUT', body: JSON.stringify(body),
                });
                form.classList.add('hidden');
                await loadUsers();
                showMessage('dashboard-notice', 'Akun berhasil diperbarui.');
            } catch (error) { showMessage('dashboard-error', error.message); }
        });
    }

    const initial = initialSection === 'users' && isAdmin ? 'users' : 'overview';
    setSection(initial);
    loadHistory();
    loadFillings();
    window.setInterval(loadLatest, 5000);
})();
</script>
@endpush
