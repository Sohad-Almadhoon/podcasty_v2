import type { Config } from "tailwindcss";

export default {
	darkMode: ["class"],
	content: [
		"./pages/**/*.{js,ts,jsx,tsx,mdx}",
		"./components/**/*.{js,ts,jsx,tsx,mdx}",
		"./app/**/*.{js,ts,jsx,tsx,mdx}",
	],
	theme: {
		extend: {
			boxShadow: {
				'app': 'var(--app-shadow)',
				'app-md': 'var(--app-shadow-md)',
			},
			colors: {
				'app-bg': 'var(--app-bg)',
				'app-surface': 'var(--app-surface)',
				'app-raised': 'var(--app-raised)',
				'app-border': 'var(--app-border)',
				'app-text': 'var(--app-text)',
				'app-muted': 'var(--app-muted)',
				'app-subtle': 'var(--app-subtle)',
				'app-accent': 'var(--app-accent)',
				'app-accent-fg': 'var(--app-accent-fg)',
			},
			fontFamily: {
				montserrat: [
					'Montserrat',
					'sans-serif'
				],
				dancingScript: [
					'Dancing Script',
					'cursive'
				]
			},
			borderRadius: {
				lg: 'var(--radius)',
				md: 'calc(var(--radius) - 2px)',
				sm: 'calc(var(--radius) - 4px)'
			}
		}
	},
	plugins: [require("tailwindcss-animate")]
} satisfies Config;
