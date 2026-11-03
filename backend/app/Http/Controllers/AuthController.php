<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $r)
    {
        $data = $r->validate([
            'name'     => 'required|string|max:100|unique:users,name',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|min:6',
        ]);
        $user = User::create([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
        ]);
        return response()->json([
            'token' => $user->createToken('mobile')->plainTextToken,
            'user'  => $user,
        ], 201);
    }

    public function login(Request $r)
    {
        $data = $r->validate([
            'login'    => 'required_without:email|string',
            'email'    => 'required_without:login|string',
            'password' => 'required',
        ]);
        $login = $data['login'] ?? $data['email'];
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

    public function logout(Request $r)
    {
        $r->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logout berhasil']);
    }
}
