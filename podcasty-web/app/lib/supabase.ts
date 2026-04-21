"use server";
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export const getUser = async () => {
  if (process.env.BYPASS_AUTH === 'true') {
    return {
      id: 'dev-user-id',
      email: 'dev@localhost.com',
      user_metadata: {
        full_name: 'Dev User',
        avatar_url: '',
      },
    } as any;
  }
  const auth = (await getSupabaseAuth()).auth;
  const user = (await auth.getUser()).data.user;
  return user;
}
export async function getSupabaseAuth() {
    const cookieStore = await cookies()

    const supabaseClient =  createServerClient(
        process.env.SUPABASE_URL!,
        process.env.SUPABASE_ANON_KEY!,
        {
            cookies: {
                getAll() {
                    return cookieStore.getAll()
                },
                setAll(cookiesToSet) {
                    try {
                        cookiesToSet.forEach(({ name, value, options }) =>
                            cookieStore.set(name, value, options)
                        )
                    } catch {
                        // The `setAll` method was called from a Server Component.
                        // This can be ignored if you have middleware refreshing
                        // user sessions.
                    }
                },
            },
        }
    )
    return supabaseClient;
}

