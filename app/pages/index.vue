<script setup lang="ts">
import type { Database } from '~/types/database.types'
import type { CatalogDossier, DossierCardVariant } from '~/components/DossierCard.vue'
import { ALL_TOPICS } from '~/composables/useUserProfile'

const route = useRoute()
const supabase = useSupabaseClient<Database>()
const {
  clearanceLevel,
  intelPoints,
  selectedTopics,
  isJackOfAllTrades,
  getTopicClearance,
  getTopicPoints,
  updateInterests
} = useUserProfile()

const {
  themeMeta,
  unlockedThemesCount
} = useClearanceTheme()

const { error: toastError, warning: toastWarning, success: toastSuccess } = useToast()

const selectedCategory = ref<string>('ALL')

// Area of Interest Selection Modal State
const isInterestModalOpen = ref(false)

// Theme Vault Modal State
const isThemeVaultOpen = ref(false)

// Field Test Modal State
const isFieldTestOpen = ref(false)
const activeTestId = ref<string | null>(null)
const activeDossierTitle = ref<string>('')
const activeRequiredClearance = ref<number>(2)

// Access Denied Banner state
const accessDeniedNotice = computed(() => {
  if (route.query.denied === 'true') {
    return {
      slug: (route.query.slug as string) || 'unknown',
      required: (route.query.required as string) || 'higher'
    }
  }
  return null
})

// Trigger toast when access is denied
onMounted(() => {
  if (route.query.denied === 'true') {
    toastError(
      `Clearance Level ${route.query.required || 2} required to decrypt dossier "${route.query.slug}". Access denied.`,
      'ACCESS RESTRICTED'
    )
  }
})

const dismissDeniedNotice = () => {
  navigateTo({ path: '/', query: {} }, { replace: true })
}

// Fetch all dossiers via secure get_dossier_catalog RPC
const { data: catalogData, status, error: catalogError, refresh: refreshCatalog } = await useAsyncData(
  'dossier-catalog',
  async () => {
    const { data, error } = await supabase.rpc('get_dossier_catalog' as any)
    if (error) {
      const { data: fallbackData } = await supabase
        .from('dossiers')
        .select('*')
        .order('required_clearance', { ascending: true })
      return (fallbackData || []) as CatalogDossier[]
    }
    return (data || []) as unknown as CatalogDossier[]
  }
)

const dossiers = computed(() => catalogData.value || [])

// 1. Filter dossiers by active Area of Interest directives
const interestDossiers = computed(() => {
  if (isJackOfAllTrades.value) {
    return dossiers.value
  }
  return dossiers.value.filter(d => selectedTopics.value.includes(d.category))
})

// 2. Sub-categories available within the active interests
const availableCategories = computed(() => {
  const cats = new Set(interestDossiers.value.map(d => d.category))
  return ['ALL', ...Array.from(cats)]
})

// Keep selectedCategory valid within active interests
watch(availableCategories, (newCats) => {
  if (!newCats.includes(selectedCategory.value)) {
    selectedCategory.value = 'ALL'
  }
})

// 3. Final filtered dossiers for the view
const filteredDossiers = computed(() => {
  if (selectedCategory.value === 'ALL') return interestDossiers.value
  return interestDossiers.value.filter(d => d.category === selectedCategory.value)
})

// Active topic context for the header ClearanceBar
const activeFocusedTopic = computed(() => {
  if (selectedCategory.value !== 'ALL') {
    return selectedCategory.value
  }
  if (!isJackOfAllTrades.value && selectedTopics.value.length === 1) {
    return selectedTopics.value[0]
  }
  return undefined
})

const handleSelectDossier = (dossier: CatalogDossier) => {
  navigateTo(`/dossiers/${dossier.slug}`)
}

// Open Field Test Modal when clicking a tier-transition card
const handleTakeTest = (dossier: CatalogDossier) => {
  if (dossier.field_test_id) {
    activeTestId.value = dossier.field_test_id
    activeDossierTitle.value = dossier.title
    activeRequiredClearance.value = dossier.required_clearance
    isFieldTestOpen.value = true
  } else {
    toastWarning(
      `Assessment protocol for "${dossier.title}" is currently classified.`,
      'PROTOCOL PENDING'
    )
  }
}

const handleTestSuccess = async () => {
  await refreshCatalog()
}

const handleInterestsUpdated = async () => {
  await refreshCatalog()
}

const switchToJackOfAllTrades = async () => {
  await updateInterests(['ALL'])
  toastSuccess('Operational focus set to Jack of All Trades (All 9 Domains).', 'FOCUS UPDATED')
}

// Calculate irregular bento grid variant for cleared cards based on topic clearance
const getCardVariant = (dossier: CatalogDossier): DossierCardVariant => {
  const topicClearance = getTopicClearance(dossier.category)
  const isCleared = dossier.required_clearance <= topicClearance
  if (!isCleared) return 'standard'

  // Find index among cleared dossiers in current filtered view
  const clearedDossiers = filteredDossiers.value.filter(
    d => d.required_clearance <= getTopicClearance(d.category)
  )
  const clearedIndex = clearedDossiers.findIndex(d => d.id === dossier.id)

  const pattern: DossierCardVariant[] = ['hero', 'tall', 'wide', 'standard', 'tall', 'wide']
  return pattern[clearedIndex % pattern.length] || 'standard'
}

const getCardGridSpan = (dossier: CatalogDossier) => {
  const variant = getCardVariant(dossier)
  switch (variant) {
    case 'hero':
      return 'col-span-1 md:col-span-2 lg:col-span-2 md:row-span-2 lg:row-span-2'
    case 'tall':
      return 'col-span-1 md:col-span-1 md:row-span-2 lg:row-span-2'
    case 'wide':
      return 'col-span-1 md:col-span-2 lg:col-span-2 md:row-span-1'
    default:
      return 'col-span-1 md:col-span-1 md:row-span-1'
  }
}
</script>

<template>
  <div class="min-h-screen bg-background text-foreground font-mono flex flex-col transition-colors duration-300">
    <!-- News Ticker / Daily Intelligence Dispatch -->
    <aside class="border-b border-border bg-card/60 backdrop-blur px-4 py-2 text-xs flex items-center justify-between overflow-x-auto whitespace-nowrap">
      <div class="flex items-center space-x-2">
        <span class="inline-block px-1.5 py-0.5 rounded bg-danger/20 text-danger border border-danger/30 text-[10px] font-extrabold uppercase animate-pulse">
          FLASH INTEL
        </span>
        <span class="text-muted">Simulated Global IT Outage: Critical Infrastructure Impact →</span>
        <NuxtLink to="/dossiers/how-internet-works" class="text-accent hover:underline font-bold">
          Read "How the Internet Actually Works" Dossier
        </NuxtLink>
      </div>
      <div class="hidden md:flex items-center space-x-3 text-[11px] text-muted pl-4">
        <span>ENCRYPTION: AES-256</span>
        <span>•</span>
        <span>TOPIC-BASED CLEARANCE ENGINE ACTIVE</span>
      </div>
    </aside>

    <!-- Top Tactical Navigation Bar with UserNavDropdown & Integrated ClearanceBar -->
    <header class="border-b border-border bg-card/85 backdrop-blur sticky top-0 z-40">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
        <!-- Central Briefing Room Brand -->
        <div class="flex items-center space-x-3 shrink-0">
          <span class="w-3 h-3 rounded-full bg-accent animate-pulse" />
          <span class="font-extrabold text-base tracking-tight text-foreground">The Tech Dossier</span>
          <span class="hidden lg:inline-block text-[11px] px-2 py-0.5 rounded bg-border text-muted uppercase font-semibold">
            Central Briefing Room
          </span>
        </div>

        <!-- Integrated Header ClearanceBar (Desktop & Tablet) -->
        <div class="hidden md:flex flex-1 max-w-md lg:max-w-lg mx-2 items-center">
          <ClearanceBar
            :active-topic="activeFocusedTopic"
            is-compact
          />
        </div>

        <!-- Session Management Dropdown -->
        <div class="flex items-center space-x-4 shrink-0">
          <UserNavDropdown />
        </div>
      </div>

      <!-- Integrated Header ClearanceBar (Mobile Bar) -->
      <div class="md:hidden border-t border-border/60 px-4 py-2 bg-card-subtle/80 backdrop-blur">
        <ClearanceBar
          :active-topic="activeFocusedTopic"
          is-compact
        />
      </div>
    </header>

    <!-- Main Briefing Content -->
    <main class="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      <!-- Access Denied Alert Banner -->
      <div
        v-if="accessDeniedNotice"
        class="border border-danger/60 bg-danger/15 rounded-xl p-4 flex items-start justify-between shadow-glow-danger"
      >
        <div class="flex items-start space-x-3 text-xs text-danger">
          <span class="text-lg leading-none shrink-0 font-bold">⛔</span>
          <div>
            <span class="font-bold uppercase tracking-wider block mb-1">
              [ACCESS DENIED // SECURITY FAULT]
            </span>
            <span class="text-foreground">
              Dossier <strong class="text-danger">"{{ accessDeniedNotice.slug }}"</strong> requires
              <strong class="text-danger">Clearance Level {{ accessDeniedNotice.required }}</strong>.
              Your current topic credentials restrict unauthorized decryption. Complete the prerequisite field test below to elevate clearance.
            </span>
          </div>
        </div>
        <button
          class="text-xs text-muted hover:text-foreground ml-4 uppercase font-bold shrink-0"
          @click="dismissDeniedNotice"
        >
          [Dismiss]
        </button>
      </div>

      <!-- Area of Interest / Operational Focus Directive Bar -->
      <section class="border-2 border-accent/40 bg-card rounded-2xl p-4 sm:p-5 shadow-sm backdrop-blur relative overflow-hidden">
        <div class="absolute right-0 top-0 bottom-0 w-32 bg-accent/5 pointer-events-none blur-2xl" />

        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <!-- Left: Focus Status -->
          <div class="space-y-1">
            <div class="flex items-center space-x-2 text-[11px] font-bold uppercase tracking-wider text-accent">
              <span class="w-2 h-2 rounded-full bg-accent animate-ping" />
              <span>ACTIVE OPERATIONAL DIRECTIVE // AREA OF INTEREST</span>
            </div>

            <div class="flex flex-wrap items-center gap-2 pt-0.5">
              <template v-if="isJackOfAllTrades">
                <span class="text-base sm:text-lg font-black text-foreground">
                  ⚡ Jack of All Trades
                </span>
                <span class="text-xs px-2.5 py-0.5 rounded-full bg-accent/15 text-accent border border-accent/30 font-bold">
                  All 9 Domains Active
                </span>
              </template>
              <template v-else-if="selectedTopics.length === 1">
                <span class="text-base sm:text-lg font-black text-foreground">
                  🎯 Focus Domain: {{ selectedTopics[0] }}
                </span>
                <span class="text-xs px-2.5 py-0.5 rounded-full bg-accent text-accent-contrast font-black">
                  Level {{ getTopicClearance(selectedTopics[0]) }} Clearance
                </span>
              </template>
              <template v-else>
                <span class="text-base sm:text-lg font-black text-foreground">
                  🎛️ Tactical Focus Group:
                </span>
                <div class="flex flex-wrap items-center gap-1.5">
                  <span
                    v-for="topic in selectedTopics"
                    :key="topic"
                    class="text-[11px] px-2 py-0.5 rounded bg-card-subtle border border-border text-foreground font-semibold"
                  >
                    {{ topic }} (L{{ getTopicClearance(topic) }})
                  </span>
                </div>
              </template>
            </div>

            <p class="text-xs text-muted">
              Incoming intelligence and field tests are filtered to your selected areas of operational focus.
            </p>
          </div>

          <!-- Right: Action Buttons -->
          <div class="flex items-center space-x-2 shrink-0">
            <button
              v-if="!isJackOfAllTrades"
              type="button"
              class="px-3.5 py-2 rounded-xl border border-border bg-card-subtle hover:bg-card text-xs font-bold uppercase tracking-wider transition text-muted hover:text-foreground"
              @click="switchToJackOfAllTrades"
            >
              ⚡ Jack of All Trades
            </button>
            <button
              type="button"
              class="px-4 py-2 rounded-xl text-xs font-extrabold uppercase tracking-wider transition shadow-glow-accent bg-accent text-accent-contrast flex items-center space-x-1.5 cursor-pointer"
              @click="isInterestModalOpen = true"
            >
              <span>⚙️</span>
              <span>Change Specialization Focus</span>
            </button>
          </div>
        </div>
      </section>

      <!-- Operational Status Bar with Classified Theme Unlock Roadmap -->
      <section class="border border-border rounded-xl p-4 bg-card/70 space-y-3 text-xs">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <div class="flex flex-wrap items-center gap-2">
            <span class="text-muted uppercase tracking-wider font-semibold">Active Operational Aesthetic:</span>
            <span class="px-2.5 py-1 rounded bg-card-subtle font-extrabold text-accent border border-border">
              {{ themeMeta.name }}
            </span>
            <button
              type="button"
              class="px-2.5 py-1 rounded-lg bg-accent/15 hover:bg-accent/25 border border-accent/40 text-accent font-extrabold text-[11px] transition flex items-center space-x-1.5 cursor-pointer shadow-sm"
              @click="isThemeVaultOpen = true"
            >
              <span>🎨 Theme Vault: {{ unlockedThemesCount }}/4 Unlocked</span>
              <span>→</span>
            </button>
          </div>

          <div class="flex items-center space-x-2 text-muted text-[11px]">
            <span class="w-2 h-2 rounded-full bg-success animate-ping" />
            <span>Security Engine: Topic-Based RLS & PostgreSQL RPC Enforced</span>
          </div>
        </div>

        <!-- Clearance Progression Theme Unlock Notification Banner -->
        <div class="pt-2.5 border-t border-border/60 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-[11px]">
          <div class="flex items-center space-x-2 text-muted">
            <span class="text-accent font-extrabold uppercase tracking-wide">💡 Clearance Reward:</span>
            <span>
              Elevating your clearance level unlocks classified operational UI themes!
              <strong class="text-foreground">Level 2</strong> unlocks Cold Cyan Console,
              <strong class="text-foreground">Level 3</strong> unlocks Cyber Amber, and
              <strong class="text-foreground">Level 4</strong> unlocks Phosphor Matrix.
            </span>
          </div>
          <button
            type="button"
            class="text-accent hover:underline font-extrabold uppercase shrink-0 text-left sm:text-right cursor-pointer"
            @click="isThemeVaultOpen = true"
          >
            [View Theme Vault Roadmap →]
          </button>
        </div>
      </section>

      <!-- Active Missions & Classified Archive Grid -->
      <section>
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
          <div>
            <h2 class="text-base font-bold text-foreground tracking-tight uppercase">
              Mission Archives & Intel Briefs
            </h2>
            <p class="text-xs text-muted">
              Showing dossiers tailored to your selected area of operations. Complete topic field tests to advance clearance.
            </p>
          </div>

          <!-- Category Filter Pills -->
          <div class="flex flex-wrap items-center gap-2">
            <button
              v-for="cat in availableCategories"
              :key="cat"
              class="px-3 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wider transition border flex items-center space-x-1.5 select-none shadow-sm cursor-pointer"
              :class="[
                selectedCategory === cat
                  ? 'bg-accent text-accent-contrast border-accent ring-2 ring-accent/40 shadow-glow-accent font-extrabold'
                  : 'bg-card text-muted border-border hover:text-foreground hover:bg-card-subtle'
              ]"
              @click="selectedCategory = cat"
            >
              <span
                v-if="selectedCategory === cat"
                class="w-1.5 h-1.5 rounded-full bg-accent-contrast inline-block"
              />
              <span>{{ cat }}</span>
              <span
                v-if="cat !== 'ALL'"
                class="text-[10px] opacity-80"
              >
                (L{{ getTopicClearance(cat) }})
              </span>
            </button>
            <button
              type="button"
              class="px-2.5 py-1.5 rounded-lg text-xs font-bold text-accent hover:bg-card-subtle border border-accent/40 transition flex items-center space-x-1"
              title="Add or remove areas of interest"
              @click="isInterestModalOpen = true"
            >
              <span>+</span>
              <span class="hidden sm:inline">Modify Focus</span>
            </button>
          </div>
        </div>

        <!-- Skeleton Loading State -->
        <div v-if="status === 'pending'" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          <DossierCardSkeleton v-for="n in 6" :key="n" />
        </div>

        <div v-else-if="catalogError" class="py-16 text-center text-xs text-danger">
          Error querying dossier database: {{ catalogError.message }}
        </div>

        <!-- Empty state if selected focus has no dossiers -->
        <div
          v-else-if="filteredDossiers.length === 0"
          class="border border-border rounded-xl p-12 text-center space-y-3 bg-card/50"
        >
          <div class="text-2xl">📁</div>
          <h3 class="font-extrabold text-foreground text-sm uppercase tracking-wider">
            No Active Briefs for Current Focus
          </h3>
          <p class="text-xs text-muted max-w-md mx-auto">
            No dossiers are registered under the current filter. Expand your operational areas or select Jack of All Trades.
          </p>
          <button
            type="button"
            class="px-4 py-2 rounded-xl text-xs font-bold bg-accent text-accent-contrast uppercase shadow-glow-accent"
            @click="isInterestModalOpen = true"
          >
            Adjust Focus Areas
          </button>
        </div>

        <!-- DossierCard Component Responsive Irregular CSS Bento Grid (varying width and height) -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 grid-flow-dense">
          <DossierCard
            v-for="dossier in filteredDossiers"
            :key="dossier.id"
            :dossier="dossier"
            :user-clearance="getTopicClearance(dossier.category)"
            :variant="getCardVariant(dossier)"
            :class="getCardGridSpan(dossier)"
            @select="handleSelectDossier"
            @take-test="handleTakeTest"
          />
        </div>
      </section>
    </main>

    <!-- Area of Interest Tactical Selection Modal -->
    <AreaOfInterestModal
      :is-open="isInterestModalOpen"
      @close="isInterestModalOpen = false"
      @updated="handleInterestsUpdated"
    />

    <!-- Field Test Assessment Modal -->
    <FieldTestModal
      v-model="isFieldTestOpen"
      :test-id="activeTestId"
      :dossier-title="activeDossierTitle"
      :required-clearance="activeRequiredClearance"
      @success="handleTestSuccess"
    />

    <!-- Classified Theme Vault Modal -->
    <ThemeVaultModal
      :is-open="isThemeVaultOpen"
      @close="isThemeVaultOpen = false"
    />
  </div>
</template>
