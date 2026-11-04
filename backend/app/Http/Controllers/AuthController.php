<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    public function register(Request $r)
    {
        $data = $r->validate([
            'username' => ['required_without:name', 'string', 'min:3', 'max:100', Rule::unique('users', 'name')],
            'name'     => ['required_without:username', 'string', 'max:100', Rule::unique('users', 'name')],
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|min:6',
        ]);
        $name = trim($data['username'] ?? $data['name']);
        $user = User::create([
            'name'     => $name,
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
            'role'     => 'user',
        ])->refresh();
        return response()->json([
            'token' => $user->createToken('mobile')->plainTextToken,
            'user'  => $user,
        ], 201);
    }

    public function login(Request $r)
    {
        $data = $r->validate([
            'login'    => 'required_without_all:username,email|string',
            'username' => 'required_without_all:login,email|string',
            'email'    => 'required_without_all:login,username|string',
            'password' => 'required',
        ]);
        $login = $data['login'] ?? $data['username'] ?? $data['email'];
        $user = User::where('email', $login)->orWhere('name', $login)->first();
        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Username/email atau password salah'], 401);
        }
        $user->forceFill(['last_login_at' => now()])->save();
        return response()->json([
            'token' => $user->createToken('mobile')->plainTextToken,
            'user'  => $user,
        ]);
    }

    public function me(Request $request)
    {
        return response()->json($request->user()->only([
            'id',
            'name',
            'email',
            'role',
            'last_login_at',
        ]));
    }

    public function logout(Request $r)
    {
        $r->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logout berhasil']);
    }
}
