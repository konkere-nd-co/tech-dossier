<script setup lang="ts">
export interface CatalogDossier {
  id: string
  title: string
  slug: string
  category: string
  required_clearance: number
  is_code_related: boolean
  briefing_summary: string
  has_field_test?: boolean
  field_test_id?: string | null
}

export type DossierCardVariant = 'hero' | 'tall' | 'wide' | 'standard'

interface Props {
  dossier: CatalogDossier
  userClearance?: number
  variant?: DossierCardVariant
}

const props = withDefaults(defineProps<Props>(), {
  userClearance: undefined,
  variant: 'standard'
})

const emit = defineEmits<{
  (e: 'select', dossier: CatalogDossier): void
  (e: 'take-test', dossier: CatalogDossier): void
}>()

const { clearanceLevel: globalClearance, getTopicClearance } = useUserProfile()

const effectiveClearance = computed(() => {
  if (props.userClearance !== undefined) return props.userClearance
  return getTopicClearance(props.dossier.category)
})

const isAccessible = computed(() => {
  return props.dossier.required_clearance <= effectiveClearance.value
})

// Check if this dossier is exactly one clearance level above current clearance
const isImmediateNextTier = computed(() => {
  return props.dossier.required_clearance === effectiveClearance.value + 1
})

const isClassifiedLocked = computed(() => {
  return props.dossier.required_clearance > effectiveClearance.value + 1
})

const handleClick = () => {
  if (isAccessible.value) {
    emit('select', props.dossier)
  } else if (isImmediateNextTier.value) {
    emit('take-test', props.dossier)
  }
}
</script>

<template>
  <div
    class="relative rounded-xl border transition-all duration-300 overflow-hidden flex flex-col justify-between h-full"
    :class="[
      isAccessible
        ? [
            'border-border bg-card hover:border-accent hover:shadow-glow-accent cursor-pointer group shadow-sm',
            variant === 'hero'
              ? 'p-6 sm:p-8 min-h-[360px] md:min-h-[420px]'
              : variant === 'tall'
                ? 'p-6 sm:p-7 min-h-[360px] md:min-h-[420px]'
                : variant === 'wide'
                  ? 'p-6 min-h-[200px]'
                  : 'p-5 sm:p-6 min-h-[200px]'
          ]
        : isImmediateNextTier
          ? 'border-accent/40 bg-card/90 hover:border-accent shadow-sm cursor-pointer group p-5 min-h-[200px]'
          : 'border-border/40 bg-card-subtle/30 opacity-70 cursor-not-allowed select-none p-5 min-h-[200px]'
    ]"
    @click="handleClick"
  >
    <!-- Top Accent Bar -->
    <div
      class="w-full transition-all duration-300"
      :class="[
        isAccessible && variant === 'hero'
          ? 'h-2 bg-accent shadow-glow-accent'
          : isAccessible && (variant === 'tall' || variant === 'wide')
            ? 'h-1.5 bg-accent/90 group-hover:bg-accent'
            : isAccessible
              ? 'h-1 bg-accent/80 group-hover:bg-accent'
              : isImmediateNextTier
                ? 'h-1 bg-accent/60 group-hover:bg-accent'
                : 'h-1 bg-border/40'
      ]"
    />

    <div class="flex-1 flex flex-col justify-between" :class="variant === 'hero' ? 'pt-5' : 'pt-3.5'">
      <div>
        <!-- Card Header -->
        <div class="flex items-center justify-between gap-2 mb-3">
          <div class="flex items-center space-x-2">
            <span
              v-if="isAccessible && (variant === 'hero' || variant === 'tall')"
              class="w-2.5 h-2.5 rounded-full bg-accent animate-pulse"
            />
            <span
              class="uppercase tracking-wider font-semibold text-muted"
              :class="variant === 'hero' ? 'text-xs' : 'text-[11px]'"
            >
              {{ dossier.category }}
            </span>
            <span
              v-if="isAccessible && variant === 'hero'"
              class="hidden sm:inline-block px-2 py-0.5 rounded text-[9px] font-extrabold uppercase tracking-widest bg-accent/20 text-accent border border-accent/40"
            >
              LEAD BRIEFING // 2×2
            </span>
            <span
              v-else-if="isAccessible && variant === 'tall'"
              class="hidden sm:inline-block px-1.5 py-0.5 rounded text-[9px] font-extrabold uppercase tracking-widest bg-card-subtle text-muted border border-border"
            >
              VERTICAL INTEL
            </span>
            <span
              v-else-if="isAccessible && variant === 'wide'"
              class="hidden sm:inline-block px-1.5 py-0.5 rounded text-[9px] font-extrabold uppercase tracking-widest bg-card-subtle text-muted border border-border"
            >
              WIDE INTEL
            </span>
          </div>

          <div class="flex items-center space-x-1.5">
            <span
              class="px-2.5 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider flex items-center space-x-1 select-none"
              :class="[
                isAccessible
                  ? 'bg-accent/15 text-accent border border-accent/40 font-extrabold'
                  : isImmediateNextTier
                    ? 'bg-warning/15 text-warning border border-warning/40'
                    : 'bg-danger/10 text-danger border border-danger/30'
              ]"
            >
              <svg
                v-if="!isAccessible"
                xmlns="http://www.w3.org/2000/svg"
                class="w-3 h-3 inline-block mr-0.5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
              <span>L{{ dossier.required_clearance }} {{ isAccessible ? 'Cleared' : isImmediateNextTier ? 'Assessment' : 'Classified' }}</span>
            </span>
          </div>
        </div>

        <!-- Dossier Title -->
        <h3
          class="font-black tracking-tight transition-colors"
          :class="[
            variant === 'hero'
              ? 'text-xl sm:text-2xl mb-3 leading-snug'
              : variant === 'tall'
                ? 'text-lg sm:text-xl mb-3 leading-snug'
                : variant === 'wide'
                  ? 'text-base sm:text-lg mb-2 leading-snug'
                  : 'text-base mb-2',
            isAccessible
              ? 'text-foreground group-hover:text-accent'
              : isImmediateNextTier
                ? 'text-foreground group-hover:text-accent'
                : 'text-muted'
          ]"
        >
          {{ dossier.title }}
        </h3>

        <!-- Summary & Special Callouts for Varied Heights -->
        <div :class="variant === 'hero' || variant === 'tall' ? 'mb-5' : 'mb-3'">
          <template v-if="isClassifiedLocked">
            <div class="space-y-1.5 py-1">
              <div class="h-3 bg-border/60 rounded w-full filter blur-[1.5px]" />
              <div class="h-3 bg-border/60 rounded w-5/6 filter blur-[1.5px]" />
              <div class="h-3 bg-border/60 rounded w-3/4 filter blur-[1.5px]" />
            </div>
            <p class="text-[11px] text-danger font-semibold mt-2 flex items-center space-x-1">
              <span>⚠️ Reach Level {{ dossier.required_clearance - 1 }} to Unlock Assessment</span>
            </p>
          </template>

          <template v-else-if="isImmediateNextTier">
            <p class="text-xs text-muted leading-relaxed line-clamp-2 mb-2">
              {{ dossier.briefing_summary }}
            </p>
            <div class="p-2.5 rounded-lg bg-accent/10 border border-accent/25 text-[11px] text-accent font-semibold flex items-center space-x-1.5">
              <span>⚡</span>
              <span>Field test protocol online. Elevate clearance to Level {{ dossier.required_clearance }}.</span>
            </div>
          </template>

          <template v-else-if="variant === 'hero'">
            <p class="text-sm sm:text-base text-muted leading-relaxed line-clamp-4 mb-4 font-normal">
              {{ dossier.briefing_summary }}
            </p>
            <div class="p-3 rounded-lg bg-accent/10 border border-accent/30 text-xs text-foreground flex items-start space-x-2.5">
              <span class="text-accent font-bold mt-0.5">◈</span>
              <div>
                <span class="text-accent font-bold uppercase tracking-wider block text-[10px] mb-0.5">OPERATIONAL OVERVIEW</span>
                <span class="text-xs text-muted leading-relaxed">Full technical briefing accessible. Study core architectural components before executing advancement field tests.</span>
              </div>
            </div>
          </template>

          <template v-else-if="variant === 'tall'">
            <p class="text-xs sm:text-sm text-muted leading-relaxed line-clamp-6 mb-4 font-normal">
              {{ dossier.briefing_summary }}
            </p>
            <div class="py-2 px-3 rounded bg-card-subtle border border-border/80 text-[11px] flex items-center justify-between text-muted">
              <span>SECURITY TELEMETRY</span>
              <span class="font-bold text-accent">ACCESS AUTHORIZED</span>
            </div>
          </template>

          <template v-else>
            <p
              class="text-muted leading-relaxed"
              :class="variant === 'wide' ? 'text-sm line-clamp-3' : 'text-xs line-clamp-3'"
            >
              {{ dossier.briefing_summary }}
            </p>
          </template>
        </div>
      </div>

      <!-- Card Footer -->
      <div
        class="border-t border-border/60 flex items-center justify-between text-xs"
        :class="variant === 'hero' || variant === 'tall' ? 'pt-4' : 'pt-3'"
      >
        <span class="text-[11px] text-muted flex items-center space-x-1">
          <span>{{ dossier.is_code_related ? '⚡ Technical System' : '📄 Operational Intel' }}</span>
        </span>

        <span
          v-if="isAccessible && (variant === 'hero' || variant === 'tall')"
          class="px-3 py-1.5 rounded-lg bg-accent text-accent-contrast font-extrabold uppercase tracking-wider text-[11px] group-hover:shadow-glow-accent group-hover:scale-105 transition-all flex items-center space-x-1.5 shadow-sm"
        >
          <span>Open Dossier</span>
          <span>→</span>
        </span>
        <span
          v-else-if="isAccessible"
          class="text-[11px] font-bold uppercase tracking-wider text-accent group-hover:translate-x-0.5 transition-transform flex items-center space-x-1"
        >
          <span>Open Dossier</span>
          <span>→</span>
        </span>
        <span
          v-else-if="isImmediateNextTier"
          class="text-[10px] uppercase font-bold tracking-wider text-accent group-hover:underline flex items-center space-x-1"
        >
          <span>Take Test →</span>
        </span>
        <span
          v-else
          class="text-[10px] uppercase font-bold tracking-widest text-muted/80"
        >
          [RESTRICTED]
        </span>
      </div>
    </div>
  </div>
</template>
