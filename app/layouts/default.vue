<script setup lang="ts">
const { activeThemeClass, upgradeNotification, dismissUpgradeNotification } = useClearanceTheme()
const { clearanceLevel } = useUserProfile()

// Watch clearance level to ensure reactive theme updates
watch(
  () => clearanceLevel.value,
  () => {
    // clearance change triggers activeThemeClass computed automatically
  }
)

useHead({
  htmlAttrs: {
    class: computed(() => activeThemeClass.value)
  },
  bodyAttrs: {
    class: computed(() => `${activeThemeClass.value} min-h-screen bg-background text-foreground transition-colors duration-300`)
  }
})
</script>

<template>
  <div :class="activeThemeClass" class="min-h-screen bg-background text-foreground transition-colors duration-300 relative flex flex-col font-mono">
    <!-- Global Toast Container -->
    <ToastContainer />

    <!-- Clearance Upgrade UI Celebration Modal (agent.md Section 5.C) -->
    <Transition
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="transform -translate-y-6 opacity-0 scale-95"
      enter-to-class="transform translate-y-0 opacity-100 scale-100"
      leave-active-class="transition duration-200 ease-in"
      leave-from-class="transform translate-y-0 opacity-100 scale-100"
      leave-to-class="transform -translate-y-4 opacity-0 scale-95"
    >
      <div
        v-if="upgradeNotification.show"
        class="fixed top-6 left-1/2 -translate-x-1/2 z-[100] max-w-lg w-full px-4"
      >
        <div class="border-2 border-accent modal-surface text-foreground rounded-xl p-5 shadow-2xl animate-clearance-upgrade">
          <div class="flex items-start justify-between">
            <div class="flex items-center space-x-3">
              <span class="w-10 h-10 rounded-full bg-accent/20 border border-accent flex items-center justify-center text-xl shrink-0 font-bold">
                ⚡
              </span>
              <div>
                <span class="text-[11px] font-bold uppercase tracking-widest text-accent block">
                  [SECURITY CLEARANCE ELEVATED]
                </span>
                <h4 class="text-base font-bold text-foreground">
                  Clearance Upgraded: Level {{ upgradeNotification.toLevel }} {{ upgradeNotification.title }}
                </h4>
                <p class="text-xs text-muted mt-1 leading-relaxed">
                  Terminal UI aesthetic transformed. Classified archives for Level {{ upgradeNotification.toLevel }} are now decrypted and accessible.
                </p>
              </div>
            </div>
            <button
              class="text-xs text-muted hover:text-foreground ml-3 uppercase font-bold shrink-0"
              @click="dismissUpgradeNotification"
            >
              ✕
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- App Content Slot -->
    <slot />
  </div>
</template>
