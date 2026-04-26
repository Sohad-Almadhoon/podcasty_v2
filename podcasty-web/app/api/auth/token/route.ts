import { NextResponse } from 'next/server'
import { getSupabaseAuth } from '@/app/lib/supabase'

export const dynamic = 'force-dynamic'

export async function GET() {
  const supabase = await getSupabaseAuth()
  const { data: { session } } = await supabase.auth.getSession()
  if (!session?.access_token) {
    return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })
  }
  return NextResponse.json({ access_token: session.access_token })
}
