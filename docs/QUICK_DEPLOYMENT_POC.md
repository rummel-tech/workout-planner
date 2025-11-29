# Quick Deployment Guide: Supabase + Vercel (POC Edition)

**Estimated Setup Time:** 30-45 minutes  
**Cost:** Free tier to start, $25/mo when you scale  
**Target:** Get your Fitness Agent POC live with minimal effort

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Supabase Setup (15 minutes)](#supabase-setup)
3. [Backend Migration (30 minutes)](#backend-migration)
4. [Frontend Deployment to Vercel (10 minutes)](#frontend-deployment)
5. [Testing & Verification](#testing--verification)
6. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     USERS WORLDWIDE                         │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
    ┌────────────────────┐
    │   Vercel (CDN)     │
    │  Flutter Web App   │ ◄─── Automatic deploys from GitHub
    │   (FREE or $20/mo) │
    └────────┬───────────┘
             │
             │ API Calls
             │
             ▼
    ┌────────────────────────────────────┐
    │   Supabase (Single Service)        │
    │  ┌──────────────────────────────┐ │
    │  │ PostgreSQL Database          │ │
    │  │ (Automatic backups)          │ │
    │  ├──────────────────────────────┤ │
    │  │ Edge Functions               │ │
    │  │ (Your AI Logic)              │ │
    │  ├──────────────────────────────┤ │
    │  │ Authentication               │ │
    │  │ (JWT tokens)                 │ │
    │  ├──────────────────────────────┤ │
    │  │ Real-time Subscriptions      │ │
    │  │ (Live dashboards)            │ │
    │  └──────────────────────────────┘ │
    │  COST: $0-25/mo (FREE tier to start)
    └────────────────────────────────────┘

Mobile Apps (Optional):
├── iOS: `flutter build ios` → App Store
└── Android: `flutter build apk` → Play Store
```

---

## Supabase Setup

### Step 1: Create Supabase Account

1. Go to **https://supabase.com**
2. Click **"Start your project"** (top right)
3. Sign up with GitHub (easiest option)
4. Authorize Supabase

### Step 2: Create Your First Project

1. Click **"New Project"**
2. Fill in details:
   - **Project Name:** `fitness-agent-poc`
   - **Database Password:** Generate strong password (save this!)
   - **Region:** Choose closest to your users (e.g., `us-east-1`)
   - **Pricing Plan:** Select **FREE** tier
3. Click **"Create new project"** (takes 2-3 minutes)

### Step 3: Get Your Credentials

Once project is created, go to **Settings > API**:

```
Copy these values (you'll need them):

SUPABASE_URL: https://xxxxx.supabase.co
SUPABASE_ANON_KEY: eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY: eyJhbGc...
```

Save these in a `.env` file:
```bash
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
```

### Step 4: Initialize Database Schema

Go to **SQL Editor** in Supabase dashboard and run this:

```sql
-- Users table (auto-created by Supabase Auth, but we'll create a profile)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email text NOT NULL,
  username text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Health metrics table
CREATE TABLE IF NOT EXISTS public.health_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  heart_rate integer,
  hrv integer,
  sleep_hours decimal(3,1),
  resting_hr integer,
  recovery_level text,
  measured_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Workouts table
CREATE TABLE IF NOT EXISTS public.workouts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  type text NOT NULL,
  duration_minutes integer,
  intensity integer DEFAULT 3,
  calories_burned integer,
  notes text,
  completed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Goals table
CREATE TABLE IF NOT EXISTS public.goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  goal_type text NOT NULL,
  target_value text,
  current_value text,
  target_date date,
  status text DEFAULT 'active',
  progress_pct decimal(5,2) DEFAULT 0,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- AI Insights table
CREATE TABLE IF NOT EXISTS public.ai_insights (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  insight_type text NOT NULL,
  title text,
  detail text,
  recommendation text,
  generated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  expires_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can only see their own data)
CREATE POLICY "Users can view own health metrics"
  ON public.health_metrics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own health metrics"
  ON public.health_metrics FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own health metrics"
  ON public.health_metrics FOR UPDATE
  USING (auth.uid() = user_id);

-- Repeat for other tables...
CREATE POLICY "Users can view own workouts"
  ON public.workouts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workouts"
  ON public.workouts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own goals"
  ON public.goals FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own goals"
  ON public.goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own insights"
  ON public.ai_insights FOR SELECT
  USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX idx_health_metrics_user_id ON public.health_metrics(user_id);
CREATE INDEX idx_workouts_user_id ON public.workouts(user_id);
CREATE INDEX idx_goals_user_id ON public.goals(user_id);
CREATE INDEX idx_ai_insights_user_id ON public.ai_insights(user_id);
```

✅ **Supabase is now ready!**

---

## Backend Migration

### Option A: Use Supabase Edge Functions (Recommended for POC)

If you want simple backend logic, use Supabase Edge Functions instead of FastAPI.

**Step 1: Create a simple readiness calculation function**

In Supabase dashboard, go to **Functions** > **Create a new function**:

```javascript
// Function name: calculate_readiness
// Choose Node.js runtime

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const supabase = createClient(supabaseUrl, supabaseKey)

serve(async (req) => {
  try {
    const { userId } = await req.json()
    
    // Get latest health metrics
    const { data: metrics, error } = await supabase
      .from('health_metrics')
      .select('*')
      .eq('user_id', userId)
      .order('measured_at', { ascending: false })
      .limit(1)
    
    if (error) throw error
    
    if (!metrics || metrics.length === 0) {
      return new Response(JSON.stringify({ readiness: 5.0 }), {
        headers: { 'Content-Type': 'application/json' }
      })
    }
    
    const m = metrics[0]
    
    // Simple readiness calculation (0-10 scale)
    let readiness = 5.0
    if (m.sleep_hours >= 7) readiness += 2
    if (m.hrv >= 50) readiness += 1.5
    if (m.resting_hr <= 60) readiness += 1
    if (m.recovery_level === 'good') readiness += 0.5
    
    readiness = Math.min(readiness, 10)
    
    return new Response(JSON.stringify({ 
      readiness: Math.round(readiness * 10) / 10,
      metrics: m 
    }), {
      headers: { 'Content-Type': 'application/json' }
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
```

### Option B: Keep FastAPI (If you need more control)

If you prefer to keep your FastAPI backend:

**Step 1: Update FastAPI to use Supabase as database**

```python
# applications/backend/fastapi_server/main.py

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import os
from supabase import create_client, Client

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

app = FastAPI(title="Fitness Agent API")

# CORS for Vercel frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://fitness-agent-poc.vercel.app", "localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "fitness_api"}

@app.get("/readiness/{user_id}")
async def get_readiness(user_id: str):
    """Get user readiness score"""
    try:
        # Query Supabase
        response = supabase.table('health_metrics').select("*").eq(
            'user_id', user_id
        ).order('measured_at', desc=True).limit(1).execute()
        
        if not response.data:
            return {"readiness": 5.0, "message": "No metrics available"}
        
        metrics = response.data[0]
        
        # Calculate readiness
        readiness = 5.0
        if metrics.get('sleep_hours', 0) >= 7:
            readiness += 2
        if metrics.get('hrv', 0) >= 50:
            readiness += 1.5
        if metrics.get('resting_hr', 100) <= 60:
            readiness += 1
        
        readiness = min(readiness, 10)
        
        return {
            "readiness": round(readiness, 1),
            "metrics": metrics
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/workouts")
async def create_workout(workout: dict):
    """Create a new workout"""
    try:
        response = supabase.table('workouts').insert(workout).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Add more endpoints as needed...
```

**Step 2: Deploy FastAPI to Vercel (or Railway.app for free)**

Option 1: Deploy to Railway.app (free tier):
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Deploy from your fastapi_server directory
cd applications/backend/fastapi_server
railway init
railway up
```

Option 2: Deploy to Render.com (free tier):
- Go to render.com
- Connect GitHub
- Create new Web Service
- Select your repo
- Build command: `pip install -r requirements.txt`
- Start command: `uvicorn main:app --host 0.0.0.0 --port 8000`

---

## Frontend Deployment

### Step 1: Update Flutter App for Supabase

```dart
// pubspec.yaml - add this dependency

dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^1.10.0
  # ... other dependencies
```

### Step 2: Initialize Supabase in main.dart

```dart
// lib/main.dart

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',  // From .env
    anonKey: 'YOUR_ANON_KEY',   // From .env
  );
  
  runApp(const MyApp());
}

// Access Supabase client anywhere in your app:
// final supabase = Supabase.instance.client;
```

### Step 3: Update API calls to use Supabase

```dart
// Example: Getting readiness data

import 'package:supabase_flutter/supabase_flutter.dart';

Future<Map<String, dynamic>> getReadiness(String userId) async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase
        .from('health_metrics')
        .select()
        .eq('user_id', userId)
        .order('measured_at', ascending: false)
        .limit(1);
    
    if (response.isEmpty) {
      return {'readiness': 5.0};
    }
    
    final metrics = response[0];
    double readiness = 5.0;
    
    if ((metrics['sleep_hours'] ?? 0) >= 7) readiness += 2;
    if ((metrics['hrv'] ?? 0) >= 50) readiness += 1.5;
    if ((metrics['resting_hr'] ?? 100) <= 60) readiness += 1;
    
    return {
      'readiness': (readiness * 10).roundToDouble() / 10,
      'metrics': metrics
    };
  } catch (e) {
    print('Error: $e');
    return {'error': e.toString()};
  }
}
```

### Step 4: Deploy to Vercel

**Step 4a: Push code to GitHub**
```bash
cd /path/to/Fitness\ Agent
git add .
git commit -m "Add Supabase integration"
git push origin main
```

**Step 4b: Connect to Vercel**

1. Go to **https://vercel.com**
2. Sign up with GitHub
3. Click **Import Project**
4. Select your Fitness Agent repository
5. Configure build settings:
   - **Framework:** Other (since it's Flutter)
   - **Build Command:** `flutter build web`
   - **Output Directory:** `build/web`
   - **Environment Variables:** 
     ```
     SUPABASE_URL=your_url
     SUPABASE_ANON_KEY=your_key
     ```
6. Click **Deploy** (takes 3-5 minutes)

**Done!** Your app is now live at: `https://fitness-agent-poc.vercel.app`

---

## Testing & Verification

### Test Supabase Connection

1. Go to Supabase Dashboard > **SQL Editor**
2. Create a test user:
   ```sql
   INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
   VALUES ('test@example.com', crypt('password123', gen_salt('bf')), now());
   ```

3. Add test data:
   ```sql
   INSERT INTO public.health_metrics (user_id, heart_rate, hrv, sleep_hours, resting_hr, recovery_level, measured_at)
   VALUES ('USER_ID_HERE', 68, 55, 7.5, 58, 'good', now());
   ```

### Test Frontend

1. Go to your Vercel deployment URL
2. Try to:
   - View dashboard
   - See readiness score
   - View workout data
3. Check browser console for errors (F12 > Console)

### Test API (if using FastAPI)

```bash
# Test health check
curl https://your-api.railway.app/health

# Test readiness endpoint
curl https://your-api.railway.app/readiness/USER_ID
```

---

## Troubleshooting

### Issue: "Connection refused" error

**Solution:**
- Verify SUPABASE_URL and SUPABASE_ANON_KEY are correct
- Check that Supabase project is active (Settings > General)
- Clear browser cache (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)

### Issue: "Row Level Security" error

**Solution:**
- Make sure RLS policies are created correctly
- Check user is authenticated (JWT token valid)
- Verify user_id matches in database

### Issue: Vercel build fails

**Solution:**
```bash
# Test build locally first
flutter clean
flutter pub get
flutter build web

# Check for errors
flutter doctor -v
```

### Issue: Slow performance

**Solution:**
- Add database indexes (already done in schema above)
- Limit query results with `.limit(100)`
- Use `.select('column1,column2')` to fetch only needed columns
- Enable caching in Vercel dashboard (Settings > Caching)

---

## Next Steps (After POC Works)

1. **Add Mobile Apps**
   - Build iOS: `flutter build ios` → Submit to App Store
   - Build Android: `flutter build apk` → Submit to Play Store

2. **Scale Backend**
   - Keep Supabase for database
   - If FastAPI gets slow, upgrade Supabase tier ($25 → $50+)
   - Add Vercel Pro ($20/mo) for better performance

3. **Add Real Data**
   - Integrate with HealthKit (iOS)
   - Add user auth with email verification
   - Implement refresh tokens

4. **Monitor & Optimize**
   - Set up Supabase monitoring
   - Monitor Vercel analytics
   - Track API response times

---

## Quick Reference Commands

```bash
# Test locally (before deploying)
cd applications/frontend/apps/mobile_app
flutter pub get
flutter run -d web

# Build for web
flutter build web

# Push to GitHub (triggers Vercel deploy)
git add .
git commit -m "message"
git push origin main

# View Vercel logs
# https://vercel.com/dashboard → Select project → Logs

# View Supabase logs
# https://app.supabase.com → Select project → Database → Logs
```

---

**You're ready to launch! 🚀**

- POC should be live in 30-45 minutes
- Cost: $0 (free tier) or $25/mo when you scale
- No infrastructure management needed
- Scale from 100 to 100,000 users without changing architecture

Questions? Check Supabase docs: https://supabase.com/docs or Vercel docs: https://vercel.com/docs
