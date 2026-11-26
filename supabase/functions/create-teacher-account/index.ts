// Supabase Edge Function: create-teacher-account
// Creates an auth.users record using the Service Role key, then invokes the
// transactional `create_teacher` Postgres RPC as the calling principal/super_admin.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const authHeader = req.headers.get('Authorization') ?? '';
  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  // 1. Verify caller is principal or super_admin
  const { data: caller, error: authErr } = await callerClient.auth.getUser();
  if (authErr || !caller.user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey);
  const { data: callerProfile } = await adminClient
    .from('profiles')
    .select('role, institute_id')
    .eq('id', caller.user.id)
    .single();

  if (!callerProfile || !['principal', 'super_admin'].includes(callerProfile.role)) {
    return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });
  }

  const payload = await req.json();
  const email = payload.email as string;

  // 2. Invite or create auth user
  const { data: createdUser, error: inviteErr } =
    await adminClient.auth.admin.inviteUserByEmail(email, {
      data: {
        role: 'teacher',
        institute_id: callerProfile.institute_id,
        first_name: payload.first_name,
        last_name: payload.last_name,
      },
    });

  if (inviteErr || !createdUser.user) {
    return new Response(
      JSON.stringify({ error: inviteErr?.message ?? 'Failed to create auth user' }),
      { status: 400 },
    );
  }

  // 3. Call transactional create_teacher RPC using caller's JWT context
  const { data: teacherId, error: rpcErr } = await callerClient.rpc(
    'create_teacher',
    { payload: { ...payload, profile_id: createdUser.user.id } },
  );

  if (rpcErr) {
    // Rollback auth user if DB transaction fails
    await adminClient.auth.admin.deleteUser(createdUser.user.id);
    return new Response(JSON.stringify({ error: rpcErr.message }), { status: 400 });
  }

  return new Response(JSON.stringify({ teacher_id: teacherId }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
