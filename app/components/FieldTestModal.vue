<script setup lang="ts">
import type { Database } from '~/types/database.types'
import { triggerConfetti } from '~/utils/celebration'

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

interface Props {
  modelValue: boolean
  testId?: string | null
  dossierTitle?: string
  requiredClearance?: number
}

const props = withDefaults(defineProps<Props>(), {
  testId: null,
  dossierTitle: '',
  requiredClearance: 2
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'success', payload: any): void
}>()

const supabase = useSupabaseClient<Database>()
const { user, profile, fetchProfile } = useUserProfile()
const { activeThemeClass, triggerUpgradeCelebration } = useClearanceTheme()

const isLoading = ref(true)
const isSubmitting = ref(false)
const testData = ref<FieldTestDetails | null>(null)
const selectedAnswer = ref<string>('')
const terminalInput = ref<string>('')
const errorMessage = ref<string | null>(null)
const successPayload = ref<any | null>(null)

// Load test details from RPC without exposing correct answer
const loadTestDetails = async () => {
  if (!props.testId) return

  isLoading.value = true
  errorMessage.value = null
  successPayload.value = null
  selectedAnswer.value = ''
  terminalInput.value = ''

  try {
    const { data, error } = await supabase.rpc('get_field_test', {
      p_test_id: props.testId
    } as any)

    if (error) throw error

    testData.value = data as unknown as FieldTestDetails
  } catch (err: any) {
    errorMessage.value = err.message || 'Failed to initialize assessment protocol.'
  } finally {
    isLoading.value = false
  }
}

watch(
  () => [props.modelValue, props.testId],
  ([isOpen, newTestId]) => {
    if (isOpen && newTestId) {
      loadTestDetails()
    }
  },
  { immediate: true }
)

const closeModal = () => {
  emit('update:modelValue', false)
  errorMessage.value = null
  successPayload.value = null
}

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
    if (operativeId && typeof operativeId === 'string' && operativeId !== 'undefined' && operativeId.trim() !== '') {
      payload.p_user_id = operativeId
    }

    const { data, error } = await supabase.rpc('submit_field_test', payload as any)

    if (error) throw error

    const result = data as any

    if (!result.success) {
      errorMessage.value = result.message || 'Operational assessment failed.'
      return
    }

    // Success flow!
    successPayload.value = result
    triggerConfetti()

    // Update global user state with topic clearances
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

    // Trigger visual elevation sequence
    triggerUpgradeCelebration(prevLevel, result.new_clearance_level)

    emit('success', result)

    // Close after short celebration
    setTimeout(() => {
      closeModal()
    }, 2800)
  } catch (err: any) {
    errorMessage.value = err.message || 'System fault occurred during test submission.'
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="modelValue"
        class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/90 backdrop-blur-md"
        :class="activeThemeClass"
        @click.self="closeModal"
      >
        <div class="w-full max-w-xl modal-surface border-2 border-accent rounded-xl shadow-2xl relative font-mono text-foreground flex flex-col max-h-[90vh] overflow-hidden">
          <!-- Modal Header (Pinned at top) -->
          <div class="p-5 sm:p-6 pb-4 border-b border-border flex items-center justify-between shrink-0">
            <div class="flex items-center space-x-2">
              <span class="w-3 h-3 rounded-full bg-accent animate-pulse" />
              <span class="text-xs uppercase tracking-widest font-extrabold text-accent">
                Field Test Assessment Protocol
              </span>
            </div>

            <button
              class="text-xs px-2.5 py-1 rounded text-muted hover:text-foreground hover:bg-card-subtle transition font-bold border border-transparent hover:border-border"
              @click="closeModal"
            >
              [ESC / CLOSE]
            </button>
          </div>

          <!-- Modal Scrollable Content Body -->
          <div class="p-5 sm:p-6 pt-4 flex-1 overflow-y-auto space-y-4">
            <!-- Loading State -->
            <div v-if="isLoading" class="py-12 text-center text-xs text-muted">
              <span class="inline-block w-5 h-5 border-2 border-accent border-t-transparent rounded-full animate-spin mb-3" />
              <p>Accessing encrypted assessment telemetry...</p>
            </div>

            <!-- Success State -->
            <div v-else-if="successPayload" class="py-8 text-center space-y-4">
              <div class="w-14 h-14 rounded-full bg-success/20 border-2 border-success text-success flex items-center justify-center mx-auto text-2xl font-bold shadow-glow-accent">
                ✓
              </div>
              <div>
                <span class="text-xs font-bold uppercase tracking-widest text-success block">
                  [ASSESSMENT VERIFIED // SECURITY CLEARED]
                </span>
                <h3 class="text-xl font-extrabold text-foreground mt-1">
                  {{ successPayload.category ? `${successPayload.category} Clearance Elevated: Level ${successPayload.new_topic_clearance || successPayload.new_clearance_level}` : `Clearance Elevated: Level ${successPayload.new_clearance_level}` }}
                </h3>
                <p class="text-xs text-muted mt-1">
                  +100 Intel Points Awarded. {{ successPayload.category ? `Your specialization in ${successPayload.category} has been upgraded.` : '' }} Classified dossier "{{ successPayload.dossier_title }}" is now accessible.
                </p>

                <!-- Theme Unlock Callout on Elevation -->
                <div class="mt-3 p-3 rounded-xl bg-accent/15 border border-accent/40 text-xs text-accent font-bold flex items-center justify-center space-x-2 shadow-sm">
                  <span>🎨</span>
                  <span>New Operational Aesthetic Unlocked! Check the Theme Vault to preview or activate your new theme.</span>
                </div>
              </div>
            </div>

            <!-- Active Test Content -->
            <div v-else-if="testData" class="space-y-4">
              <!-- Target Dossier Info -->
              <div class="p-3.5 rounded-lg bg-card-subtle border border-border flex items-center justify-between text-xs">
                <div>
                  <span class="text-[10px] uppercase font-bold tracking-wider text-muted block">
                    Target Dossier
                  </span>
                  <span class="font-bold text-foreground">
                    {{ testData.dossier_title }}
                  </span>
                </div>
                <span class="px-2 py-1 rounded bg-accent/15 border border-accent/40 text-accent text-[11px] font-bold uppercase tracking-wider">
                  Clearance L{{ testData.required_clearance }}
                </span>
              </div>

              <!-- Theme Unlock Incentive Callout -->
              <div class="px-3 py-2 rounded-lg bg-accent/10 border border-accent/30 flex items-center justify-between text-[11px] text-accent font-semibold">
                <span class="flex items-center space-x-1.5">
                  <span>🎨</span>
                  <span>Rank-Up Reward: Elevating your clearance unlocks new classified operational themes!</span>
                </span>
                <span class="font-extrabold shrink-0 uppercase tracking-wide">
                  L{{ testData.required_clearance }} Theme Unlocked on Pass
                </span>
              </div>

              <!-- Scenario Description -->
              <div>
                <h4 class="text-xs font-bold uppercase tracking-wider text-muted mb-1.5">
                  Tactical Scenario:
                </h4>
                <div class="p-4 rounded-lg bg-background border border-border text-sm leading-relaxed text-foreground">
                  {{ testData.scenario_description }}
                </div>
              </div>

              <!-- Error Banner -->
              <div
                v-if="errorMessage"
                class="p-3 rounded-lg border border-danger/40 bg-danger/10 text-danger text-xs flex items-start space-x-2"
              >
                <span class="font-bold shrink-0">[FAILED]:</span>
                <span>{{ errorMessage }}</span>
              </div>

              <!-- Form: Multiple Choice -->
              <div v-if="testData.test_type === 'multiple_choice' && testData.options" class="space-y-2 pt-1">
                <label class="block text-xs font-bold uppercase tracking-wider text-muted mb-2">
                  Select Operational Response:
                </label>

                <label
                  v-for="opt in testData.options"
                  :key="opt"
                  class="flex items-center space-x-3 p-3 rounded-lg border cursor-pointer transition select-none text-xs"
                  :class="[
                    selectedAnswer === opt
                      ? 'border-accent bg-accent/15 text-foreground font-bold shadow-sm ring-1 ring-accent/30'
                      : 'border-border bg-card-subtle text-muted hover:text-foreground hover:border-accent/40'
                  ]"
                >
                  <input
                    v-model="selectedAnswer"
                    type="radio"
                    :value="opt"
                    name="field-test-answer"
                    class="text-accent focus:ring-accent"
                  >
                  <span class="flex-1">{{ opt }}</span>
                </label>
              </div>

              <!-- Form: Terminal / Command Simulation -->
              <div v-else class="space-y-2 pt-1">
                <label class="block text-xs font-bold uppercase tracking-wider text-muted">
                  Execute Terminal Command:
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
            </div>
          </div>

          <!-- Sticky Action Footer - ALWAYS VISIBLE -->
          <div
            v-if="testData && !successPayload && !isLoading"
            class="p-4 sm:px-6 bg-card-subtle border-t border-border flex items-center justify-between shrink-0 text-xs gap-3"
          >
            <div class="flex items-center space-x-2 text-muted text-[11px]">
              <span class="w-2 h-2 rounded-full bg-accent animate-pulse" />
              <span class="hidden sm:inline">Elevation Reward:</span>
              <span class="font-bold text-accent">+100 Intel PTS</span>
            </div>

            <button
              :disabled="isSubmitting || (!selectedAnswer && !terminalInput)"
              class="px-5 py-2.5 text-xs font-extrabold uppercase tracking-wider rounded-lg transition flex items-center space-x-2 select-none border"
              :class="[
                (!selectedAnswer && !terminalInput)
                  ? 'bg-card border-border text-muted cursor-not-allowed opacity-80'
                  : 'bg-accent hover:bg-accent-hover text-accent-contrast border-accent shadow-glow-accent cursor-pointer'
              ]"
              @click="handleSubmit"
            >
              <span v-if="isSubmitting" class="w-3.5 h-3.5 border-2 border-current border-t-transparent rounded-full animate-spin" />
              <span>
                {{ isSubmitting ? 'Evaluating...' : (!selectedAnswer && !terminalInput ? 'Select Response to Submit' : 'Submit Verification') }}
              </span>
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
