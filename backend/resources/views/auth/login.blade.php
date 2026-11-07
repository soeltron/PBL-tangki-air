@extends('layouts.dashboard')

@section('title', 'Masuk - Dashboard Tandon')

@section('content')
<main class="flex min-h-screen items-center justify-center px-4 py-10">
    <section class="w-full max-w-md rounded-3xl border border-slate-800 bg-slate-900 p-8 shadow-2xl">
        <p class="text-sm font-semibold uppercase tracking-[0.2em] text-cyan-400">Monitoring Tandon</p>
        <h1 class="mt-3 text-3xl font-bold">Masuk dashboard</h1>
        <p class="mt-2 text-sm text-slate-400">Gunakan username atau email akun Anda.</p>

        @if ($errors->any())
            <div class="mt-6 rounded-xl border border-rose-900 bg-rose-950/60 p-3 text-sm text-rose-200" role="alert">
                {{ $errors->first() }}
            </div>
        @endif

        <form method="POST" action="{{ route('login.store') }}" class="mt-6 space-y-5">
            @csrf
            <label class="block text-sm font-medium">
                Username atau email
                <input name="login" value="{{ old('login') }}" required autocomplete="username"
                    class="mt-2 w-full rounded-xl border border-slate-700 bg-slate-950 px-4 py-3 text-white outline-none focus:border-cyan-400">
            </label>
            <label class="block text-sm font-medium">
                Password
                <input name="password" type="password" required autocomplete="current-password"
                    class="mt-2 w-full rounded-xl border border-slate-700 bg-slate-950 px-4 py-3 text-white outline-none focus:border-cyan-400">
            </label>
            <button class="w-full rounded-xl bg-cyan-500 px-4 py-3 font-semibold text-slate-950 hover:bg-cyan-400">
                Masuk
            </button>
        </form>
    </section>
</main>
@endsection
