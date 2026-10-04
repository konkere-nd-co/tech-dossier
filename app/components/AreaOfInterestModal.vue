<script setup lang="ts">
import {
  ALL_TOPICS,
  TOPIC_METADATA,
  type TopicCategory
} from '~/composables/useUserProfile'

interface Props {
  isOpen: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'updated', topics: string[]): void
}>()

const {
  selectedTopics,
  isJackOfAllTrades,
  getTopicClearance,
  getTopicPoints,
  updateInterests
} = useUserProfile()

const { success: toastSuccess } = useToast()

// Local selection draft state
const draftTopics = ref<string[]>([])
const isSaving = ref(false)

const tierTitles: Record<number, string> = {
  1: 'Civilian Observer',
  2: 'Field Operative',
  3: 'System Specialist',
  4: 'Black-Ops Architect'
}

// Sync draft with current selected topics when modal opens
watch(
  () => props.isOpen,
  (open) => {
    if (open) {
      if (isJackOfAllTrades.value) {
        draftTopics.value = ['ALL']
      } else {
        draftTopics.value = [...selectedTopics.value]
      }
    }
  },
  { immediate: true }
)

const isAllSelected = computed(() => {
  return draftTopics.value.includes('ALL') || draftTopics.value.length === ALL_TOPICS.length
})

const selectAll = () => {
  draftTopics.value = ['ALL']
}

const clearAll = () => {
  draftTopics.value = []
}

const toggleTopic = (topic: string) => {
  if (isAllSelected.value) {
    // If currently all selected, clicking one switches to just that topic
    draftTopics.value = [topic]
    return
  }

  const index = draftTopics.value.indexOf(topic)
  if (index > -1) {
    draftTopics.value.splice(index, 1)
  } else {
    draftTopics.value.push(topic)
  }

  if (draftTopics.value.length === ALL_TOPICS.length) {
    draftTopics.value = ['ALL']
  }
}

const isTopicDraftSelected = (topic: string) => {
  if (isAllSelected.value) return true
  return draftTopics.value.includes(topic)
}

const selectOnlyTopic = (topic: string) => {
  draftTopics.value = [topic]
}

const handleSave = async () => {
  isSaving.value = true
  try {
    const finalSelection = draftTopics.value.length === 0 || isAllSelected.value ? ['ALL'] : draftTopics.value
    await updateInterests(finalSelection)

    if (finalSelection.includes('ALL')) {
      toastSuccess('Specialization set to Jack of All Trades (Full Spectrum).', 'DIRECTIVE UPDATED')
    } else {
      toastSuccess(`Specialization set to ${finalSelection.length} focus area(s).`, 'DIRECTIVE UPDATED')
    }

    emit('updated', finalSelection)
    emit('close')
  } finally {
    isSaving.value = false
  }
}
</script>

<template>
  <Transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="opacity-0"
    enter-to-class="opacity-100"
    leave-active-class="transition duration-150 ease-in"
    leave-from-class="opacity-100"
    leave-to-class="opacity-0"
  >
    <div
      v-if="isOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md overflow-y-auto"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="modal-surface w-full max-w-3xl rounded-2xl border-2 border-border shadow-2xl p-6 sm:p-8 my-8 relative flex flex-col max-h-[90vh]"
      >
        <!-- Modal Header -->
        <div class="flex items-start justify-between border-b border-border pb-4 mb-4 shrink-0">
          <div>
            <div class="flex items-center space-x-2 text-xs font-bold text-accent uppercase tracking-wider mb-1">
              <span class="w-2 h-2 rounded-full bg-accent animate-ping" />
              <span>TACTICAL SPECIALIZATION PROTOCOL // DIRECTIVE 01</span>
            </div>
            <h2 class="text-xl sm:text-2xl font-extrabold text-foreground tracking-tight">
              Select Areas of Operational Focus
            </h2>
            <p class="text-xs text-muted mt-1 leading-relaxed">
              Tailor your clearance tracks. Filter incoming intelligence to your specialized disciplines or choose <strong>Jack of All Trades</strong> for full-spectrum access.
            </p>
          </div>

          <button
            class="text-muted hover:text-foreground text-sm font-bold p-1 rounded hover:bg-card-subtle transition ml-4"
            aria-label="Close modal"
            @click="emit('close')"
          >
            ✕
          </button>
        </div>

        <!-- Quick Mode Presets -->
        <div class="flex flex-wrap items-center justify-between gap-3 mb-4 shrink-0 bg-card-subtle p-3 rounded-xl border border-border">
          <div class="flex items-center space-x-2">
            <span class="text-xs font-bold uppercase tracking-wider text-muted">Specialization Mode:</span>
            <span
              v-if="isAllSelected"
              class="px-2 py-0.5 rounded text-[11px] font-extrabold bg-accent text-accent-contrast shadow-sm"
            >
              ⚡ Jack of All Trades (All 9 Areas)
            </span>
            <span
              v-else-if="draftTopics.length === 1"
              class="px-2 py-0.5 rounded text-[11px] font-extrabold bg-card border border-accent text-accent"
            >
              Single Domain Focus: {{ draftTopics[0] }}
            </span>
            <span
              v-else
              class="px-2 py-0.5 rounded text-[11px] font-extrabold bg-card border border-border text-foreground"
            >
              Cross-Disciplinary Group ({{ draftTopics.length }} Selected)
            </span>
          </div>

          <div class="flex items-center space-x-2 text-xs">
            <button
              type="button"
              class="px-3 py-1.5 rounded-lg border font-bold uppercase text-[11px] transition shadow-sm"
              :class="isAllSelected ? 'bg-accent text-accent-contrast border-accent' : 'bg-card hover:bg-card-subtle text-foreground border-border'"
              @click="selectAll"
            >
              ⚡ Jack of All Trades
            </button>
            <button
              v-if="!isAllSelected && draftTopics.length > 0"
              type="button"
              class="px-3 py-1.5 rounded-lg border border-border bg-card hover:bg-card-subtle text-muted hover:text-foreground font-semibold uppercase text-[11px] transition"
              @click="clearAll"
            >
              Clear Selection
            </button>
          </div>
        </div>

        <!-- Scrollable Topic Selection Grid -->
        <div class="overflow-y-auto pr-1 flex-1 space-y-2.5">
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            <div
              v-for="topic in ALL_TOPICS"
              :key="topic"
              class="group relative border-2 rounded-xl p-3.5 transition cursor-pointer select-none flex flex-col justify-between"
              :class="[
                isTopicDraftSelected(topic)
                  ? 'border-accent bg-accent/10 shadow-glow-accent'
                  : 'border-border bg-card hover:border-muted hover:bg-card-subtle'
              ]"
              @click="toggleTopic(topic)"
            >
              <div>
                <!-- Topic Card Header -->
                <div class="flex items-center justify-between gap-2 mb-2">
                  <div class="flex items-center space-x-2">
                    <span class="text-xl leading-none">{{ TOPIC_METADATA[topic]?.icon || '📁' }}</span>
                    <span class="font-extrabold text-sm text-foreground group-hover:text-accent transition">
                      {{ topic }}
                    </span>
                  </div>

                  <!-- Checkbox Indicator -->
                  <div
                    class="w-5 h-5 rounded border flex items-center justify-center text-xs font-black transition shrink-0"
                    :class="[
                      isTopicDraftSelected(topic)
                        ? 'bg-accent text-accent-contrast border-accent'
                        : 'border-muted bg-card-subtle text-transparent'
                    ]"
                  >
                    ✓
                  </div>
                </div>

                <!-- Topic Description -->
                <p class="text-[11px] text-muted leading-snug mb-3">
                  {{ TOPIC_METADATA[topic]?.description }}
                </p>
              </div>

              <!-- Tailored Topic Clearance Footer -->
              <div class="pt-2 border-t border-border/80 flex items-center justify-between text-[10px]">
                <div class="flex items-center space-x-1">
                  <span class="text-muted uppercase font-bold">Clearance:</span>
                  <span class="font-extrabold text-accent">
                    Level {{ getTopicClearance(topic) }}
                  </span>
                </div>
                <span class="text-muted">
                  {{ tierTitles[getTopicClearance(topic)] }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Modal Footer Actions -->
        <div class="pt-4 mt-4 border-t border-border flex flex-col sm:flex-row items-center justify-between gap-3 shrink-0">
          <div class="text-xs text-muted">
            <span v-if="isAllSelected">
              Incoming intelligence will encompass <strong>all technology domains</strong>.
            </span>
            <span v-else-if="draftTopics.length > 0">
              Only dossiers within <strong>{{ draftTopics.join(', ') }}</strong> will populate the briefing room.
            </span>
            <span v-else class="text-danger font-semibold">
              Select at least 1 focus area or click "Jack of All Trades".
            </span>
          </div>

          <div class="flex items-center space-x-3 w-full sm:w-auto">
            <button
              type="button"
              class="flex-1 sm:flex-none px-4 py-2 rounded-xl border border-border bg-card hover:bg-card-subtle text-foreground text-xs font-bold uppercase tracking-wider transition"
              @click="emit('close')"
            >
              Cancel
            </button>
            <button
              type="button"
              :disabled="draftTopics.length === 0 && !isAllSelected || isSaving"
              class="flex-1 sm:flex-none px-6 py-2 rounded-xl text-xs font-extrabold uppercase tracking-wider transition shadow-glow-accent bg-accent text-accent-contrast disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
              @click="handleSave"
            >
              {{ isSaving ? 'Establishing Directives...' : 'Lock In Directive' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>
