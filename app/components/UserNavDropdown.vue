<script setup lang="ts">
const { user, profile, clearanceLevel, intelPoints, selectedTopics, isJackOfAllTrades, logout } = useUserProfile()
const { activeThemeClass, themeMeta, unlockedThemesCount } = useClearanceTheme()
const { info } = useToast()

const isOpen = ref(false)
const dropdownRef = ref<HTMLElement | null>(null)

const toggleDropdown = () => {
  isOpen.value = !isOpen.value
}

const closeDropdown = () => {
  isOpen.value = false
}

const handleSignOut = async () => {
  closeDropdown()
  info('Operative session terminated. Re-authenticate to access classified archives.', 'SESSION CLOSED')
  await logout()
}

// Click outside handler
const handleClickOutside = (e: MouseEvent) => {
  if (dropdownRef.value && !dropdownRef.value.contains(e.target as Node)) {
    closeDropdown()
  }
}

onMounted(() => {
  if (import.meta.client) {
    document.addEventListener('click', handleClickOutside)
  }
})

onUnmounted(() => {
  if (import.meta.client) {
    document.removeEventListener('click', handleClickOutside)
  }
})

const userInitial = computed(() => {
  const email = profile.value?.email || user.value?.email || 'A'
  return email.charAt(0).toUpperCase()
})
</script>

<template>
  <div ref="dropdownRef" class="relative inline-block text-left font-mono">
    <!-- Dropdown Trigger Button -->
    <button
      type="button"
      class="flex items-center space-x-2.5 p-1.5 rounded-lg border border-border bg-card hover:bg-card-subtle transition focus:outline-none focus:ring-2 focus:ring-accent/40"
      @click="toggleDropdown"
    >
      <!-- Avatar with Level Color Indicator -->
      <div class="w-7 h-7 rounded-md bg-accent text-white font-extrabold text-xs flex items-center justify-center shadow-sm">
        {{ userInitial }}
      </div>

      <!-- Truncated Email -->
      <div class="hidden sm:flex flex-col text-left">
        <span class="text-xs font-bold text-foreground leading-none truncate max-w-[130px]">
          {{ profile?.email?.split('@')[0] }}
        </span>
        <span class="text-[10px] text-accent font-semibold leading-tight">
          L{{ clearanceLevel }} {{ themeMeta.code }}
        </span>
      </div>

      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="w-3.5 h-3.5 text-muted transition-transform duration-200"
        :class="{ 'rotate-180': isOpen }"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>

    <!-- Dropdown Menu -->
    <Transition
      enter-active-class="transition duration-150 ease-out"
      enter-from-class="transform scale-95 opacity-0 -translate-y-1"
      enter-to-class="transform scale-100 opacity-100 translate-y-0"
      leave-active-class="transition duration-100 ease-in"
      leave-from-class="transform scale-100 opacity-100 translate-y-0"
      leave-to-class="transform scale-95 opacity-0 -translate-y-1"
    >
      <div
        v-if="isOpen"
        class="absolute right-0 mt-2 w-72 origin-top-right rounded-xl border border-border popover-surface shadow-2xl p-4 z-[70] divide-y divide-border/60"
        :class="activeThemeClass"
      >
        <!-- Operative Info Header -->
        <div class="pb-3 space-y-1">
          <div class="flex items-center justify-between">
            <span class="text-[10px] uppercase font-bold tracking-widest text-muted">
              Operative Profile
            </span>
            <span class="text-[10px] px-1.5 py-0.5 rounded bg-success/15 border border-success/30 text-success font-extrabold uppercase">
              Online
            </span>
          </div>
          <p class="text-xs font-bold text-foreground truncate">
            {{ profile?.email || user?.email }}
          </p>
          <p class="text-[11px] text-muted">
            ID: <span class="font-mono">{{ user?.id?.slice(0, 12) }}...</span>
          </p>
        </div>

        <!-- Clearance & Ranking Telemetry -->
        <div class="py-3 space-y-2 text-xs">
          <div class="flex items-center justify-between">
            <span class="text-muted text-[11px] uppercase tracking-wider">Rank / Tier:</span>
            <span class="font-bold text-accent">
              {{ themeMeta.name }}
            </span>
          </div>

          <div class="flex items-center justify-between">
            <span class="text-muted text-[11px] uppercase tracking-wider">Intel Capital:</span>
            <span class="font-bold text-foreground">
              {{ intelPoints }} PTS
            </span>
          </div>

          <div class="flex items-center justify-between">
            <span class="text-muted text-[11px] uppercase tracking-wider">Specialization:</span>
            <span class="font-bold text-foreground text-[11px] truncate max-w-[130px]" :title="isJackOfAllTrades ? 'Jack of All Trades' : selectedTopics.join(', ')">
              {{ isJackOfAllTrades ? 'Jack of All Trades' : `${selectedTopics.length} Domain(s)` }}
            </span>
          </div>

          <div class="flex items-center justify-between">
            <span class="text-muted text-[11px] uppercase tracking-wider">Clearance Status:</span>
            <span class="px-2 py-0.5 rounded bg-accent/15 text-accent text-[10px] font-bold uppercase tracking-wider">
              Level {{ clearanceLevel }} Authorized
            </span>
          </div>

          <div class="pt-1.5 border-t border-border/40">
            <div class="flex items-center justify-between">
              <span class="text-muted text-[11px] uppercase tracking-wider">Theme Vault:</span>
              <span class="font-bold text-accent text-[11px]">
                🎨 {{ unlockedThemesCount }}/4 Unlocked
              </span>
            </div>
            <p class="text-[10px] text-muted leading-tight mt-1">
              Rank up your clearance level to unlock more terminal themes.
            </p>
          </div>
        </div>

        <!-- Action / Sign Out -->
        <div class="pt-3">
          <button
            type="button"
            class="w-full py-2 px-3 rounded-lg border border-border hover:border-danger/40 bg-card-subtle hover:bg-danger/10 text-muted hover:text-danger text-xs font-bold uppercase tracking-wider transition flex items-center justify-center space-x-2"
            @click="handleSignOut"
          >
            <span>Sign Out Session</span>
            <span>→</span>
          </button>
        </div>
      </div>
    </Transition>
  </div>
</template>
