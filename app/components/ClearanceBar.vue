<script setup lang="ts">
interface Props {
  clearanceLevel?: number
  intelPoints?: number
  pointsPerTier?: number
  isCompact?: boolean
  activeTopic?: string
}

const props = withDefaults(defineProps<Props>(), {
  clearanceLevel: undefined,
  intelPoints: undefined,
  pointsPerTier: 100,
  isCompact: false,
  activeTopic: undefined
})

const {
  clearanceLevel: globalLevel,
  intelPoints: globalPoints,
  selectedTopics,
  isJackOfAllTrades,
  getTopicClearance,
  getTopicPoints
} = useUserProfile()

const currentTopic = computed(() => {
  if (props.activeTopic && props.activeTopic !== 'ALL') return props.activeTopic
  if (!isJackOfAllTrades.value && selectedTopics.value.length === 1) {
    return selectedTopics.value[0]
  }
  return undefined
})

const currentLevel = computed(() => {
  if (props.clearanceLevel !== undefined) return props.clearanceLevel
  if (currentTopic.value) {
    return getTopicClearance(currentTopic.value)
  }
  return globalLevel.value
})

const currentPoints = computed(() => {
  if (props.intelPoints !== undefined) return props.intelPoints
  if (currentTopic.value) {
    return getTopicPoints(currentTopic.value)
  }
  return globalPoints.value
})

const tierTitles: Record<number, string> = {
  1: 'Civilian Observer',
  2: 'Field Operative',
  3: 'System Specialist',
  4: 'Black-Ops Architect'
}

const currentTierName = computed(() => {
  const title = tierTitles[currentLevel.value] || 'Special Operative'
  if (currentTopic.value) {
    return `${currentTopic.value} • L${currentLevel.value}: ${title}`
  }
  if (!isJackOfAllTrades.value && selectedTopics.value.length > 1) {
    return `Specialist (${selectedTopics.value.length} Areas) • L${currentLevel.value}: ${title}`
  }
  return `Jack of All Trades • L${currentLevel.value}: ${title}`
})

const nextTierName = computed(() => {
  if (currentLevel.value >= 4) return 'Maximum Clearance Reached'
  const next = currentLevel.value + 1
  return `L${next} ${tierTitles[next] || 'Classified'}`
})

const themeUnlocks: Record<number, string> = {
  2: 'Cyan Console Theme',
  3: 'Cyber Amber Theme',
  4: 'CRT Matrix Green Theme'
}

const nextThemeUnlock = computed(() => {
  if (currentLevel.value >= 4) return null
  return themeUnlocks[currentLevel.value + 1] || null
})

// Calculate progress percentage inside current tier
const pointsInCurrentTier = computed(() => {
  return currentPoints.value % props.pointsPerTier
})

const progressPercent = computed(() => {
  if (currentLevel.value >= 4) return 100
  return Math.min(100, Math.max(0, Math.round((pointsInCurrentTier.value / props.pointsPerTier) * 100)))
})
</script>

<template>
  <!-- Integrated Header Compact Mode -->
  <div v-if="isCompact" class="w-full font-mono select-none">
    <div class="flex items-center justify-between text-[11px] mb-1.5 leading-none gap-2">
      <!-- Current Tier with Pulse Dot & Topic Indicator -->
      <div class="flex items-center space-x-1.5 shrink-0 max-w-[55%] truncate">
        <span class="w-2 h-2 rounded-full bg-accent animate-pulse shrink-0" />
        <span class="font-extrabold text-foreground tracking-tight truncate" :title="currentTierName">
          {{ currentTierName }}
        </span>
      </div>

      <!-- Telemetry Points & Next Tier Target (with Theme Unlock Notice) -->
      <div
        class="flex items-center space-x-2 text-[10px] text-muted truncate"
        :title="nextThemeUnlock ? `Rank up to Level ${currentLevel + 1} to unlock the ${nextThemeUnlock}!` : 'Maximum theme access reached'"
      >
        <span class="font-bold text-accent">{{ pointsInCurrentTier }}/{{ pointsPerTier }} PTS</span>
        <span class="opacity-40">•</span>
        <span class="font-semibold text-foreground truncate">
          {{ currentLevel >= 4 ? 'MAX' : `${progressPercent}% → ${nextTierName}` }}
        </span>
        <span
          v-if="nextThemeUnlock"
          class="hidden lg:inline-block text-[9px] px-1.5 py-0.5 rounded bg-accent/15 text-accent border border-accent/30 font-bold"
        >
          🎨 Unlocks Theme
        </span>
      </div>
    </div>

    <!-- Progress Track & Fill -->
    <div class="w-full bg-border/80 h-2 rounded-full overflow-hidden relative shadow-inner">
      <div
        class="h-full bg-accent transition-all duration-500 ease-out shadow-glow-accent relative"
        :style="{ width: `${progressPercent}%` }"
      >
        <span class="absolute right-0 top-0 bottom-0 w-1 bg-white opacity-80" />
      </div>
    </div>
  </div>

  <!-- Standalone Card Mode -->
  <div v-else class="border border-border bg-card rounded-xl p-4 shadow-sm backdrop-blur">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-2">
      <!-- Current Tier Title -->
      <div class="flex items-center space-x-2">
        <span class="w-2.5 h-2.5 rounded-full bg-accent animate-pulse" />
        <span class="text-xs uppercase tracking-wider font-bold text-foreground">
          {{ currentTierName }}
        </span>
      </div>

      <!-- Point Counter / Telemetry -->
      <div class="flex items-center space-x-2 text-[11px] text-muted">
        <span>Intel Progress:</span>
        <span class="font-bold text-accent">
          {{ pointsInCurrentTier }} / {{ pointsPerTier }} PTS
        </span>
        <span class="text-border">|</span>
        <span class="text-foreground font-semibold">Total: {{ currentPoints }} PTS</span>
      </div>
    </div>

    <!-- Progress Track & Fill -->
    <div class="w-full bg-card-subtle h-2.5 rounded-full overflow-hidden border border-border/80 relative">
      <div
        class="h-full bg-accent transition-all duration-500 ease-out shadow-glow-accent relative"
        :style="{ width: `${progressPercent}%` }"
      >
        <!-- Light ping line at the head of the bar -->
        <span class="absolute right-0 top-0 bottom-0 w-1 bg-white opacity-75" />
      </div>
    </div>

    <!-- Target Tier Footer -->
    <div class="mt-2 flex items-center justify-between text-[10px] uppercase tracking-wider text-muted">
      <span>{{ progressPercent }}% Cleared</span>
      <span class="flex items-center space-x-1.5">
        <span>Target: {{ nextTierName }}</span>
        <span v-if="nextThemeUnlock" class="text-accent font-bold">
          (+ Unlocks {{ nextThemeUnlock }})
        </span>
      </span>
    </div>
  </div>
</template>
