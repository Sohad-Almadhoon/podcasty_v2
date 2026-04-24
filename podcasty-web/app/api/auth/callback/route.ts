import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function GET(request: NextRequest) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')
  const next = requestUrl.searchParams.get('next') ?? '/'

  const forwardedHost = request.headers.get('x-forwarded-host') ?? request.headers.get('host')
  const forwardedProto = request.headers.get('x-forwarded-proto') ?? requestUrl.protocol.replace(':', '')
  const publicBase = forwardedHost ? `${forwardedProto}://${forwardedHost}` : requestUrl.origin

  if (code) {
    const cookieStore = await cookies()
    const supabase = createServerClient(
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

    const { error } = await supabase.auth.exchangeCodeForSession(code)
    
    if (!error) {
      // Get the user to ensure they exist in our database
      const { data: { user } } = await supabase.auth.getUser()
      
      if (user) {
        // Check if user exists in public.users table, if not create them
        const { data: existingUser } = await supabase
          .from('users')
          .select('id')
          .eq('id', user.id)
          .single()

        if (!existingUser) {
          // Create user in public.users table
          const { error: insertError } = await supabase.from('users').insert({
            id: user.id,
            email: user.email,
            username: user.user_metadata.full_name || user.email?.split('@')[0] || 'User',
            avatar_url: user.user_metadata.avatar_url || user.user_metadata.picture || null,
          })
          if (insertError) {
            console.error('Failed to create user in public.users:', insertError)
          }
        }
      }
      
      return NextResponse.redirect(new URL(next, publicBase))
    }
  }

  // Return the user to an error page with instructions
  return NextResponse.redirect(new URL('/login?error=auth_failed', publicBase))
}
