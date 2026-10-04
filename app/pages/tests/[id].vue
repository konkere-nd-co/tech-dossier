<script setup lang="ts">
import type { Database } from '~/types/database.types'
import { triggerConfetti } from '~/utils/celebration'

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient<Database>()
const { user, profile, fetchProfile, applyTopicUpgrade } = useUserProfile()
const { triggerUpgradeCelebration } = useClearanceTheme()

const testId = computed(() => route.params.id as string)

interface FieldTestDetails {
  id: string
  dossier_id: string
  scenario_description: string
  test_type: string
  options?: string[]
  dossier_title: string
  dossier_category: string
  required_clearance: number
}

const { data: testData, status, error } = await useAsyncData(
  `field-test-${testId.value}`,
  async () => {
    const { data, error: rpcErr } = await supabase.rpc('get_field_test', {
      p_test_id: testId.value
    } as any)

    if (rpcErr) throw rpcErr
    return data as unknown as FieldTestDetails
  }
)

const selectedAnswer = ref<string>('')
const terminalInput = ref<string>('')
const isSubmitting = ref(false)
const errorMessage = ref<string | null>(null)
const isSuccess = ref(false)

const handleSubmit = async () => {
  if (!testData.value || !user.value) return

  const answerToSubmit = testData.value.test_type === 'multiple_choice'
    ? selectedAnswer.value
    : terminalInput.value

  if (!answerToSubmit) {
    errorMessage.value = 'Please select or provide an operational response.'
    return
  }

  isSubmitting.value = true
  errorMessage.value = null

  try {
    const prevLevel = profile.value?.clearance_level || 1
    const operativeId = user.value?.id || (await supabase.auth.getUser()).data.user?.id

    const payload: Record<string, any> = {
      p_test_id: testData.value.id,
      p_answer: answerToSubmit
    }
    if (operativeId) {
      payload.p_user_id = operativeId
    }

    const { data, error: submitErr } = await supabase.rpc('submit_field_test', payload as any)

    if (submitErr) throw submitErr

    const result = data as any

    if (!result.success) {
      errorMessage.value = result.message || 'Operational assessment failed.'
      return
    }

    // Success flow
    isSuccess.value = true
    triggerConfetti()

    if (result.category && result.new_topic_clearance) {
      applyTopicUpgrade(
        result.category,
        result.new_topic_clearance,
        result.new_clearance_level,
        result.new_intel_points,
        result.topic_clearances
      )
    } else if (profile.value) {
      profile.value = {
        ...profile.value,
        clearance_level: result.new_clearance_level,
        intel_points: result.new_intel_points
      }
    }
    await fetchProfile()
    triggerUpgradeCelebration(prevLevel, result.new_clearance_level)

    setTimeout(() => {
      router.push('/')
    }, 3000)
  } catch (err: any) {
    errorMessage.value = err.message || 'System fault occurred during test submission.'
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-background text-foreground font-mono flex flex-col transition-colors duration-300">
    <header class="border-b border-border bg-card/80 backdrop-blur sticky top-0 z-40">
      <div class="max-w-4xl mx-auto px-4 h-16 flex items-center justify-between">
        <NuxtLink
          to="/"
          class="flex items-center space-x-2 text-xs font-bold uppercase tracking-wider text-muted hover:text-accent transition"
        >
          <span>←</span>
          <span>Back to Briefing Room</span>
        </NuxtLink>

        <span class="text-xs font-bold uppercase tracking-wider text-accent">
          Field Assessment Protocol
        </span>
      </div>
    </header>

    <main class="flex-1 max-w-4xl w-full mx-auto px-4 py-8">
      <div v-if="status === 'pending'" class="py-24 text-center text-xs text-muted">
        Decrypting field assessment parameters...
      </div>

      <div v-else-if="error || !testData" class="border border-danger/40 bg-danger/10 rounded-xl p-8 text-center">
        <h3 class="text-danger font-bold text-sm uppercase tracking-wider mb-2">
          [ASSESSMENT PROTOCOL UNAVAILABLE]
        </h3>
        <p class="text-xs text-muted mb-4">
          The requested field test protocol could not be located in secure telemetry.
        </p>
        <NuxtLink to="/" class="px-4 py-2 bg-border text-xs uppercase font-bold rounded-lg text-foreground">
          Return to Dashboard
        </NuxtLink>
      </div>

      <div v-else-if="isSuccess" class="border-2 border-success bg-card rounded-xl p-10 text-center space-y-4 shadow-glow-accent">
        <div class="w-16 h-16 rounded-full bg-success/20 border-2 border-success text-success flex items-center justify-center mx-auto text-3xl font-bold">
          ✓
        </div>
        <h2 class="text-2xl font-extrabold text-foreground">
          Field Test Passed!
        </h2>
        <p class="text-xs text-muted max-w-md mx-auto leading-relaxed">
          Security clearance elevated. Telemetry synchronized. Redirecting to Briefing Room...
        </p>
      </div>

      <div v-else class="border border-border bg-card rounded-xl p-6 sm:p-8 space-y-6 shadow-sm">
        <div class="border-b border-border pb-4 flex flex-wrap items-center justify-between gap-3">
          <div>
            <span class="text-[10px] uppercase font-bold tracking-wider text-muted block mb-1">
              Assessment Subject: {{ testData.dossier_category }}
            </span>
            <h1 class="text-xl sm:text-2xl font-extrabold text-foreground">
              {{ testData.dossier_title }}
            </h1>
          </div>
          <span class="px-3 py-1 rounded bg-accent/15 border border-accent/40 text-accent text-xs font-bold uppercase tracking-wider">
            Required Clearance: Level {{ testData.required_clearance }}
          </span>
        </div>

        <div>
          <h3 class="text-xs font-bold uppercase tracking-wider text-muted mb-2">
            Assessment Scenario:
          </h3>
          <div class="p-5 rounded-lg bg-background border border-border text-sm leading-relaxed text-foreground">
            {{ testData.scenario_description }}
          </div>
        </div>

        <div v-if="errorMessage" class="p-4 rounded-lg border border-danger/40 bg-danger/10 text-danger text-xs flex items-start space-x-2">
          <span class="font-bold shrink-0">[FAILED]:</span>
          <span>{{ errorMessage }}</span>
        </div>

        <div v-if="testData.test_type === 'multiple_choice' && testData.options" class="space-y-3">
          <label class="block text-xs font-bold uppercase tracking-wider text-muted">
            Select Tactical Answer:
          </label>
          <label
            v-for="opt in testData.options"
            :key="opt"
            class="flex items-center space-x-3 p-3.5 rounded-lg border cursor-pointer transition select-none text-xs"
            :class="[
              selectedAnswer === opt
                ? 'border-accent bg-accent/10 text-foreground font-bold'
                : 'border-border bg-card-subtle text-muted hover:text-foreground hover:border-accent/40'
            ]"
          >
            <input
              v-model="selectedAnswer"
              type="radio"
              :value="opt"
              name="test-option"
              class="text-accent focus:ring-accent"
            >
            <span>{{ opt }}</span>
          </label>
        </div>

        <div v-else class="space-y-2">
          <label class="block text-xs font-bold uppercase tracking-wider text-muted">
            Execute Command:
          </label>
          <div class="flex items-center bg-background border border-border rounded-lg px-3 py-2 text-xs">
            <span class="text-accent font-bold mr-2">agent@tech-dossier:~$</span>
            <input
              v-model="terminalInput"
              type="text"
              placeholder="enter command..."
              class="bg-transparent flex-1 text-foreground focus:outline-none"
              @keyup.enter="handleSubmit"
            >
          </div>
        </div>

        <div class="pt-6 border-t border-border flex items-center justify-between">
          <span class="text-xs text-muted">Elevation: +100 Intel PTS</span>
          <button
            :disabled="isSubmitting || (!selectedAnswer && !terminalInput)"
            class="px-6 py-2.5 text-xs font-extrabold uppercase tracking-wider rounded-lg transition flex items-center space-x-2 select-none border"
            :class="[
              (!selectedAnswer && !terminalInput)
                ? 'bg-card border-border text-muted cursor-not-allowed opacity-80'
                : 'bg-accent hover:bg-accent-hover text-accent-contrast border-accent shadow-glow-accent cursor-pointer'
            ]"
            @click="handleSubmit"
          >
            <span v-if="isSubmitting" class="w-3.5 h-3.5 border-2 border-current border-t-transparent rounded-full animate-spin" />
            <span>
              {{ isSubmitting ? 'Verifying...' : (!selectedAnswer && !terminalInput ? 'Select Response to Submit' : 'Submit Assessment') }}
            </span>
          </button>
        </div>
      </div>
    </main>
  </div>
</template>
