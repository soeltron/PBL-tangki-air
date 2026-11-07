<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        return view('dashboard.index', ['activeSection' => 'overview']);
    }

    public function users(): View
    {
        return view('dashboard.index', ['activeSection' => 'users']);
    }
}
