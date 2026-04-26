"use server";
import { headers } from "next/headers";
import { getSupabaseAuth } from "./supabase";
import { redirect } from "next/navigation";

export const signInWithGoogle = async () => {
    const origin = (await headers()).get('origin');
    const { data, error } = await (await getSupabaseAuth()).auth.signInWithOAuth({
        provider: 'google',
        options: {
            redirectTo: `${origin}/api/auth/callback?next=/podcasts`
        }
    });
    if (error) {
        console.log(error, 'google');
        return null;
    }
    return data.url;
}

export const signInWithGithub = async () => {
    const origin = (await headers()).get('origin');
    const { data, error } = await (await getSupabaseAuth()).auth.signInWithOAuth({
        provider: 'github',
        options: {
            redirectTo: `${origin}/api/auth/callback?next=/podcasts`
        }
    });
    if (error) {
        console.log(error, 'github');
        return null;
    }
    return data.url;
}

export const signInWithOtp = async (email: string) => {
    const origin = (await headers()).get('origin');
    const { error } = await (await getSupabaseAuth()).auth.signInWithOtp({
        email,
        options: {
            emailRedirectTo: `${origin}/api/auth/callback?next=/podcasts`
        }
    });
    if (error) {
        console.log(error, 'otp');
        return { success: false, message: error.message };
    }
    return { success: true, message: 'Check your email for the login link!' };
}

export const verifyOtp = async (email: string, token: string) => {
    const { data, error } = await (await getSupabaseAuth()).auth.verifyOtp({
        email,
        token,
        type: 'email'
    });
    if (error) {
        console.log(error, 'verify otp');
        return { success: false, message: error.message };
    }
    return { success: true };
}

export const signOut = async () => {
    try {
        await (await getSupabaseAuth()).auth.signOut();
    } catch (error) {
        console.error('signOut error:', error);
    }
    redirect('/login');
}
