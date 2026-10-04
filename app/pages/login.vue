<script setup lang="ts">
import type { Database } from '~/types/database.types'

const supabase = useSupabaseClient<Database>()
const router = useRouter()
const { fetchProfile } = useUserProfile()
const { error: toastError, success: toastSuccess } = useToast()

const email = ref('')
const password = ref('')
const errorMessage = ref<string | null>(null)
const isLoading = ref(false)

const handleLogin = async () => {
  if (!email.value || !password.value) {
    const msg = 'Please provide both operative email and authentication passphrase.'
    errorMessage.value = msg
    toastError(msg, 'INPUT REQUIRED')
    return
  }

  try {
    isLoading.value = true
    errorMessage.value = null

    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })

    if (error) {
      errorMessage.value = error.message
      toastError(error.message, 'AUTHENTICATION FAILED')
      return
    }

    if (data.session) {
      toastSuccess('Operative credentials verified. Establishing secure connection...', 'ACCESS GRANTED')
      await fetchProfile()
      await navigateTo('/')
    }
  } catch (err: any) {
    const msg = err.message || 'An unexpected authentication fault occurred.'
    errorMessage.value = msg
    toastError(msg, 'SIGNAL ERROR')
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center p-4 bg-background text-foreground font-mono">
    <div class="w-full max-w-md bg-card border border-border rounded-xl shadow-xl p-8 backdrop-blur-sm">
      <!-- Intelligence Badge / Header -->
      <div class="flex items-center justify-between border-b border-border pb-4 mb-6">
        <div class="flex items-center space-x-2">
          <span class="w-2.5 h-2.5 rounded-full bg-accent animate-pulse" />
          <span class="text-xs uppercase tracking-widest text-muted font-bold">Terminal Entry</span>
        </div>
        <span class="text-[11px] px-2 py-0.5 rounded bg-border text-muted font-semibold tracking-wider uppercase">
          Clearance: L1 Observer
        </span>
      </div>

      <div class="mb-6">
        <h1 class="text-xl font-bold tracking-tight text-foreground mb-1">
          Operative Login
        </h1>
        <p class="text-xs text-muted">
          Authenticate credentials to access verified intelligence dossiers.
        </p>
      </div>

      <!-- Alert / Error message -->
      <div
        v-if="errorMessage"
        class="mb-6 p-3 rounded-lg border border-danger/40 bg-danger/10 text-danger text-xs flex items-start space-x-2"
      >
        <span class="font-bold shrink-0">[ACCESS DENIED]</span>
        <span>{{ errorMessage }}</span>
      </div>

      <!-- Form -->
      <form class="space-y-4" @submit.prevent="handleLogin">
        <div>
          <label class="block text-xs font-semibold text-muted uppercase tracking-wider mb-1.5">
            Operative Identifier (Email)
          </label>
          <input
            v-model="email"
            type="email"
            required
            autocomplete="email"
            placeholder="agent@tech-dossier.org"
            class="w-full px-3.5 py-2.5 bg-background border border-border rounded-lg text-sm text-foreground placeholder-muted/50 focus:outline-none focus:ring-2 focus:ring-accent/50 focus:border-accent transition"
          >
        </div>

        <div>
          <label class="block text-xs font-semibold text-muted uppercase tracking-wider mb-1.5">
            Security Passphrase
          </label>
          <input
            v-model="password"
            type="password"
            required
            autocomplete="current-password"
            placeholder="••••••••••••"
            class="w-full px-3.5 py-2.5 bg-background border border-border rounded-lg text-sm text-foreground placeholder-muted/50 focus:outline-none focus:ring-2 focus:ring-accent/50 focus:border-accent transition"
          >
        </div>

        <button
          type="submit"
          :disabled="isLoading"
          class="w-full mt-2 py-2.5 px-4 bg-accent hover:bg-accent-hover text-accent-contrast text-xs uppercase tracking-wider font-extrabold rounded-lg shadow-glow-accent transition duration-150 flex items-center justify-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <span v-if="isLoading" class="w-3.5 h-3.5 border-2 border-current border-t-transparent rounded-full animate-spin" />
          <span>{{ isLoading ? 'Verifying Credentials...' : 'Authenticate & Enter' }}</span>
        </button>
      </form>

      <!-- Footer / Switch to signup -->
      <div class="mt-8 pt-4 border-t border-border text-center text-xs text-muted">
        <span>No operative credentials on record? </span>
        <NuxtLink to="/signup" class="text-accent hover:underline font-semibold ml-1">
          Request Clearance (Sign Up)
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
