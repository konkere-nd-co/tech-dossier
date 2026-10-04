// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: false },

  modules: [
    '@nuxtjs/tailwindcss',
    '@nuxtjs/supabase'
  ],

  tailwindcss: {
    cssPath: ['~/assets/css/main.css', { injectPosition: 'first' }],
    configPath: 'tailwind.config.ts',
  },

  css: [
    '~/assets/css/main.css'
  ],

  supabase: {
    redirect: false
  },

  nitro: {
    preset: process.env.NITRO_PRESET || 'cloudflare-module'
  },

  runtimeConfig: {
    public: {
      supabase: {
        url: process.env.SUPABASE_URL || process.env.NUXT_PUBLIC_SUPABASE_URL,
        key: process.env.SUPABASE_KEY || process.env.NUXT_PUBLIC_SUPABASE_KEY
      },
      supabaseUrl: process.env.SUPABASE_URL || process.env.NUXT_PUBLIC_SUPABASE_URL,
      supabaseKey: process.env.SUPABASE_KEY || process.env.NUXT_PUBLIC_SUPABASE_KEY
    }
  }
})