import type { NextConfig } from "next";

const nextConfig: NextConfig = {
    typescript: {
        ignoreBuildErrors: true,
    },
    images: {
        remotePatterns: [
            {
                hostname: "lh3.googleusercontent.com",
            }, {
                protocol: "https",
                hostname: "lpcdhaeraghnskrvvxak.supabase.co",
            }, {
                protocol: "https",
                hostname: "ichef.bbci.co.uk",
            }, {
                protocol: "https",
                hostname: "oaidalleapiprodscus.blob.core.windows.net",
            },
        ],
    },
};

export default nextConfig;
