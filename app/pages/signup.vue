<script setup lang="ts">
import type { Database } from '~/types/database.types'

const supabase = useSupabaseClient<Database>()
const router = useRouter()
const { fetchProfile } = useUserProfile()
const { error: toastError, success: toastSuccess } = useToast()

const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const errorMessage = ref<string | null>(null)
const successMessage = ref<string | null>(null)
const isLoading = ref(false)

const handleSignUp = async () => {
  if (!email.value || !password.value) {
    const msg = 'Please provide both operative email and passphrase.'
    errorMessage.value = msg
    toastError(msg, 'INPUT REQUIRED')
    return
  }

  if (password.value !== confirmPassword.value) {
    const msg = 'Security passphrases do not match.'
    errorMessage.value = msg
    toastError(msg, 'MISMATCH ERROR')
    return
  }

  if (password.value.length < 6) {
    const msg = 'Security passphrase must be at least 6 characters in length.'
    errorMessage.value = msg
    toastError(msg, 'WEAK CIPHER')
    return
  }

  try {
    isLoading.value = true
    errorMessage.value = null
    successMessage.value = null

    const { data, error } = await supabase.auth.signUp({
      email: email.value,
      password: password.value
    })

    if (error) {
      errorMessage.value = error.message
      toastError(error.message, 'REGISTRATION FAILED')
      return
    }

    // If session was returned immediately (e.g., auto-confirm is enabled in Supabase)
    if (data.session) {
      const user = useSupabaseUser()
      user.value = data.session.user

      toastSuccess('Clearance Level 1 issued! Initializing terminal...', 'ENLISTMENT COMPLETE')
      await fetchProfile(data.session.user.id)
      return navigateTo('/')
    }

    // If session was not returned, attempt immediate authentication
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })

    if (!signInError && signInData?.session) {
      const user = useSupabaseUser()
      user.value = signInData.session.user

      toastSuccess('Clearance Level 1 issued! Initializing terminal...', 'ENLISTMENT COMPLETE')
      await fetchProfile(signInData.session.user.id)
      return navigateTo('/')
    }

    // If Supabase has email confirmation strictly enforced
    if (data.user) {
      const msg = 'Operative record created. Email confirmation is enabled in Supabase — please verify your email inbox to activate your terminal session, or disable "Confirm email" in Supabase Auth settings for instant entry.'
      successMessage.value = msg
      toastSuccess(msg, 'VERIFICATION DISPATCHED')
    }
  } catch (err: any) {
    const msg = err.message || 'An unexpected registration fault occurred.'
    errorMessage.value = msg
    toastError(msg, 'SIGNAL FAULT')
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
          <span class="w-2.5 h-2.5 rounded-full bg-accent" />
          <span class="text-xs uppercase tracking-widest text-muted font-bold">Clearance Enlistment</span>
        </div>
        <span class="text-[11px] px-2 py-0.5 rounded bg-border text-muted font-semibold tracking-wider uppercase">
          Tier: Civilian Observer
        </span>
      </div>

      <div class="mb-6">
        <h1 class="text-xl font-bold tracking-tight text-foreground mb-1">
          Request Clearance
        </h1>
        <p class="text-xs text-muted">
          Enlist your operative credentials to unlock foundational and classified archives.
        </p>
      </div>

      <!-- Alert / Success message -->
      <div
        v-if="successMessage"
        class="mb-6 p-3 rounded-lg border border-success/40 bg-success/10 text-success text-xs flex items-start space-x-2"
      >
        <span class="font-bold shrink-0">[ENLISTED]</span>
        <span>{{ successMessage }}</span>
      </div>

      <!-- Alert / Error message -->
      <div
        v-if="errorMessage"
        class="mb-6 p-3 rounded-lg border border-danger/40 bg-danger/10 text-danger text-xs flex items-start space-x-2"
      >
        <span class="font-bold shrink-0">[SIGNAL FAULT]</span>
        <span>{{ errorMessage }}</span>
      </div>

      <!-- Form -->
      <form class="space-y-4" @submit.prevent="handleSignUp">
        <div>
          <label class="block text-xs font-semibold text-muted uppercase tracking-wider mb-1.5">
            Operative Identifier (Email)
          </label>
          <input
            v-model="email"
            type="email"
            required
            autocomplete="email"
            placeholder="new-agent@tech-dossier.org"
            class="w-full px-3.5 py-2.5 bg-background border border-border rounded-lg text-sm text-foreground placeholder-muted/50 focus:outline-none focus:ring-2 focus:ring-accent/50 focus:border-accent transition"
          >
        </div>

        <div>
          <label class="block text-xs font-semibold text-muted uppercase tracking-wider mb-1.5">
            Create Passphrase
          </label>
          <input
            v-model="password"
            type="password"
            required
            autocomplete="new-password"
            placeholder="••••••••••••"
            class="w-full px-3.5 py-2.5 bg-background border border-border rounded-lg text-sm text-foreground placeholder-muted/50 focus:outline-none focus:ring-2 focus:ring-accent/50 focus:border-accent transition"
          >
        </div>

        <div>
          <label class="block text-xs font-semibold text-muted uppercase tracking-wider mb-1.5">
            Confirm Passphrase
          </label>
          <input
            v-model="confirmPassword"
            type="password"
            required
            autocomplete="new-password"
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
          <span>{{ isLoading ? 'Registering Operative...' : 'Issue Level 1 Clearance' }}</span>
        </button>
      </form>

      <!-- Footer / Switch to login -->
      <div class="mt-8 pt-4 border-t border-border text-center text-xs text-muted">
        <span>Already have an operative profile? </span>
        <NuxtLink to="/login" class="text-accent hover:underline font-semibold ml-1">
          Authenticate (Log In)
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
