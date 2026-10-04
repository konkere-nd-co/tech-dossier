import type { Config } from 'tailwindcss'

export default {
  darkMode: 'class',
  content: [
    './app/**/*.{vue,js,ts,jsx,tsx}',
    './components/**/*.{vue,js,ts,jsx,tsx}',
    './layouts/**/*.{vue,js,ts,jsx,tsx}',
    './pages/**/*.{vue,js,ts,jsx,tsx}',
    './plugins/**/*.{vue,js,ts,jsx,tsx}',
    './nuxt.config.{js,ts}'
  ],
  theme: {
    extend: {
      colors: {
        // Standard semantic Tailwind aliases
        background: 'var(--color-bg)',
        foreground: 'var(--color-text)',
        card: {
          DEFAULT: 'var(--color-card)',
          subtle: 'var(--color-card-subtle)'
        },
        border: 'var(--color-border)',
        muted: 'var(--color-muted)',
        accent: {
          DEFAULT: 'var(--color-accent)',
          hover: 'var(--color-accent-hover)',
          contrast: 'var(--color-accent-contrast)'
        },
        // Tactical theme mappings
        tactical: {
          bg: 'var(--color-bg)',
          card: 'var(--color-card)',
          subtle: 'var(--color-card-subtle)',
          border: 'var(--color-border)',
          'border-glow': 'var(--color-border-glow)',
          text: 'var(--color-text)',
          muted: 'var(--color-muted)',
          accent: 'var(--color-accent)',
          'accent-hover': 'var(--color-accent-hover)',
          'accent-contrast': 'var(--color-accent-contrast)',
          'badge-bg': 'var(--color-badge-bg)',
          'badge-text': 'var(--color-badge-text)',
          danger: 'var(--color-danger)',
          warning: 'var(--color-warning)',
          success: 'var(--color-success)'
        },
        clearance: {
          1: '#0284c7', // Level 1 - Civilian (Sky Blue)
          2: '#06b6d4', // Level 2 - Operative (Cyan/Teal)
          3: '#f59e0b', // Level 3 - Specialist (Cyber Amber)
          4: '#22c55e'  // Level 4 - Architect (Phosphor Matrix Green)
        }
      },
      fontFamily: {
        mono: ['JetBrains Mono', 'Fira Code', 'ui-monospace', 'SFMono-Regular', 'Menlo', 'Monaco', 'Consolas', 'monospace'],
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif']
      },
      boxShadow: {
        'glow-accent': '0 0 16px -2px var(--color-border-glow)',
        'glow-danger': '0 0 16px -2px var(--color-danger)'
      },
      animation: {
        'clearance-upgrade': 'upgradePulse 1.2s ease-out infinite alternate',
        'scanlines': 'scanlines 8s linear infinite'
      },
      keyframes: {
        upgradePulse: {
          '0%': { transform: 'scale(1)', boxShadow: '0 0 0 0 var(--color-border-glow)' },
          '100%': { transform: 'scale(1.02)', boxShadow: '0 0 25px 8px var(--color-border-glow)' }
        }
      }
    }
  },
  plugins: []
} satisfies Config
