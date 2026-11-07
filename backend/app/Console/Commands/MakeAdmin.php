<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class MakeAdmin extends Command
{
    protected $signature = 'app:make-admin {name} {email}';

    protected $description = 'Create an admin user';

    public function handle(): int
    {
        $name = trim($this->argument('name'));
        $email = trim($this->argument('email'));
        $validator = Validator::make(
            ['name' => $name, 'email' => $email],
            [
                'name' => ['required', 'string', 'max:100', 'unique:users,name'],
                'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            ],
        );

        if ($validator->fails()) {
            foreach ($validator->errors()->all() as $error) {
                $this->error($error);
            }

            return self::FAILURE;
        }

        $password = $this->secret('Password (minimum 6 characters)');
        if (! is_string($password) || strlen($password) < 6) {
            $this->error('Password harus terdiri dari minimal 6 karakter.');

            return self::FAILURE;
        }

        if ($password !== $this->secret('Confirm password')) {
            $this->error('Konfirmasi password tidak cocok.');

            return self::FAILURE;
        }

        $user = new User([
            'name' => $name,
            'email' => $email,
            'password' => Hash::make($password),
        ]);
        $user->role = 'admin';
        $user->save();

        $this->info("Admin {$name} berhasil dibuat.");

        return self::SUCCESS;
    }
}
