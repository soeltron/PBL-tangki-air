<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AdminUserController extends Controller
{
    public function index()
    {
        return User::query()
            ->select(['id', 'name', 'email', 'role', 'last_login_at'])
            ->orderBy('name')
            ->paginate(50);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'username' => 'required|string|min:3|max:100',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => 'required|string|min:6|max:255',
        ]);

        $username = trim($data['username']);
        if ($username === '' || User::whereRaw('LOWER(name) = ?', [mb_strtolower($username)])->exists()) {
            return response()->json(['message' => 'Username sudah digunakan atau tidak valid.'], 422);
        }

        if (User::whereRaw('LOWER(email) = ?', [mb_strtolower($data['email'])])->exists()) {
            return response()->json(['message' => 'Email sudah digunakan.'], 422);
        }

        $user = User::create([
            'name' => $username,
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'role' => 'user',
        ]);

        return response()->json($user->only(['id', 'name', 'email', 'role', 'last_login_at']), 201);
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'username' => 'sometimes|required|string|min:3|max:100',
            'email' => ['sometimes', 'required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => 'sometimes|required|string|min:6|max:255',
            'user_approved' => 'required|accepted',
        ]);

        unset($data['user_approved']);
        if ($data === []) {
            return response()->json(['message' => 'Masukkan perubahan akun yang diinginkan.'], 422);
        }

        if (isset($data['username'])) {
            $username = trim($data['username']);
            if ($username === '' || User::whereRaw('LOWER(name) = ?', [mb_strtolower($username)])
                ->whereKeyNot($user->id)->exists()) {
                return response()->json(['message' => 'Username sudah digunakan atau tidak valid.'], 422);
            }
            $data['name'] = $username;
            unset($data['username']);
        }

        if (isset($data['email']) && User::whereRaw('LOWER(email) = ?', [mb_strtolower($data['email'])])
            ->whereKeyNot($user->id)->exists()) {
            return response()->json(['message' => 'Email sudah digunakan.'], 422);
        }

        $passwordChanged = isset($data['password']);
        if ($passwordChanged) {
            $data['password'] = Hash::make($data['password']);
        }

        $user->update($data);
        if ($passwordChanged) {
            $user->tokens()->delete();
        }

        return response()->json($user->only(['id', 'name', 'email', 'role', 'last_login_at']));
    }

    public function destroy(Request $request, User $user)
    {
        if ($request->user()->is($user)) {
            return response()->json(['message' => 'Admin tidak dapat menghapus akunnya sendiri.'], 422);
        }

        if ($user->role === 'admin' && User::where('role', 'admin')->count() <= 1) {
            return response()->json(['message' => 'Admin terakhir tidak dapat dihapus.'], 422);
        }

        $user->delete();

        return response()->noContent();
    }
}
