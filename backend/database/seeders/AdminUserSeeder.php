<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $name = config('admin.name');
        $email = config('admin.email');
        $password = config('admin.password');

        if (!$name || !$email || !$password) {
            $this->command?->warn('Admin awal dilewati: ADMIN_NAME, ADMIN_EMAIL, dan ADMIN_PASSWORD harus diisi.');

            return;
        }

        $user = User::firstOrNew(['email' => $email]);
        if (!$user->exists) {
            $user->name = $name;
            $user->password = Hash::make($password);
        }

        $user->role = 'admin';
        $user->save();

        $this->command?->info("Admin tersedia untuk {$email}.");
    }
}
