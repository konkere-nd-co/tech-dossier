<script setup lang="ts">
import {
  THEME_DEFINITIONS,
  type ClearanceThemeClass,
  type ThemeDefinition
} from '~/composables/useClearanceTheme'

interface Props {
  isOpen: boolean
}

defineProps<Props>()

const emit = defineEmits<{
  (e: 'close'): void
}>()

const {
  activeThemeClass,
  manualThemeOverride,
  unlockedThemesCount,
  isThemeUnlocked,
  setManualTheme
} = useClearanceTheme()

const { clearanceLevel } = useUserProfile()
const { success: toastSuccess, info: toastInfo } = useToast()

const selectTheme = (theme: ThemeDefinition) => {
  if (!isThemeUnlocked(theme.level)) return

  setManualTheme(theme.themeClass)
  toastSuccess(`Operational aesthetic switched to ${theme.name}.`, 'AESTHETIC ACTIVATED')
}

const resetToAuto = () => {
  setManualTheme(null)
  toastInfo('Operational aesthetic restored to automatic clearance tracking.', 'AUTO THEME ENGAGED')
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
              <span>THEME VAULT // CLASSIFIED OPERATIONAL AESTHETICS</span>
            </div>
            <h2 class="text-xl sm:text-2xl font-extrabold text-foreground tracking-tight">
              Rank Up To Unlock New Themes
            </h2>
            <p class="text-xs text-muted mt-1 leading-relaxed">
              Every time you elevate your clearance level through Field Tests, you unlock a new visual aesthetic. Higher clearance tiers grant access to classified console & cyber-terminal themes.
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

        <!-- Unlock Progress Bar Callout -->
        <div class="mb-5 p-4 rounded-xl bg-card-subtle border border-border shrink-0 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div class="space-y-1">
            <div class="flex items-center space-x-2 text-xs font-bold">
              <span class="text-muted uppercase tracking-wider">Aesthetic Access:</span>
              <span class="text-accent font-extrabold">
                {{ unlockedThemesCount }} of 4 Themes Unlocked
              </span>
            </div>
            <p class="text-[11px] text-muted">
              Current Clearance: <strong class="text-foreground">Level {{ clearanceLevel }}</strong>.
              <span v-if="unlockedThemesCount < 4">
                Reach <strong class="text-accent">Level {{ unlockedThemesCount + 1 }}</strong> to unlock the next classified aesthetic!
              </span>
              <span v-else class="text-success font-semibold">
                All classified operational themes unlocked!
              </span>
            </p>
          </div>

          <!-- Mini Progress Track -->
          <div class="w-full sm:w-48 bg-border h-2.5 rounded-full overflow-hidden shrink-0">
            <div
              class="h-full bg-accent shadow-glow-accent transition-all duration-500"
              :style="{ width: `${(unlockedThemesCount / 4) * 100}%` }"
            />
          </div>
        </div>

        <!-- Theme Cards Grid -->
        <div class="overflow-y-auto pr-1 flex-1 space-y-3.5">
          <div
            v-for="theme in THEME_DEFINITIONS"
            :key="theme.level"
            class="border-2 rounded-xl p-4 sm:p-5 transition flex flex-col sm:flex-row sm:items-center justify-between gap-4"
            :class="[
              isThemeUnlocked(theme.level)
                ? activeThemeClass === theme.themeClass
                  ? 'border-accent bg-accent/10 shadow-glow-accent'
                  : 'border-border bg-card hover:border-accent/60 hover:bg-card-subtle cursor-pointer'
                : 'border-border/40 bg-card-subtle/40 opacity-70 cursor-not-allowed select-none'
            ]"
            @click="isThemeUnlocked(theme.level) ? selectTheme(theme) : null"
          >
            <!-- Left Info & Swatch -->
            <div class="space-y-2 flex-1">
              <div class="flex items-center space-x-2.5">
                <!-- Theme Palette Color Swatches -->
                <div class="flex items-center space-x-1.5 p-1 rounded-lg border border-border/80 bg-background/80">
                  <span
                    class="w-4 h-4 rounded-full border border-black/20 shadow-sm"
                    :style="{ backgroundColor: theme.previewBg }"
                    title="Background"
                  />
                  <span
                    class="w-4 h-4 rounded-full border border-black/20 shadow-sm"
                    :style="{ backgroundColor: theme.previewCard }"
                    title="Card Surface"
                  />
                  <span
                    class="w-4 h-4 rounded-full border border-black/20 shadow-sm"
                    :style="{ backgroundColor: theme.previewAccent }"
                    title="Accent Glow"
                  />
                </div>

                <div class="flex items-center space-x-2">
                  <span class="text-sm font-extrabold text-foreground">
                    {{ theme.name }}
                  </span>
                  <span
                    class="px-2 py-0.5 rounded text-[10px] font-extrabold uppercase tracking-wider"
                    :class="[
                      isThemeUnlocked(theme.level)
                        ? 'bg-accent/20 text-accent border border-accent/40'
                        : 'bg-muted/20 text-muted border border-border'
                    ]"
                  >
                    {{ isThemeUnlocked(theme.level) ? 'UNLOCKED' : `LEVEL ${theme.level} REQUIRED` }}
                  </span>
                </div>
              </div>

              <p class="text-xs text-muted leading-relaxed">
                {{ theme.desc }}
              </p>

              <!-- Unlock requirement if locked -->
              <div v-if="!isThemeUnlocked(theme.level)" class="text-[11px] text-danger font-semibold flex items-center space-x-1 pt-1">
                <span>🔒</span>
                <span>Pass Level {{ theme.level }} Field Tests to elevate your rank and unlock this theme.</span>
              </div>
            </div>

            <!-- Right: Activation Button -->
            <div class="shrink-0 flex items-center space-x-2">
              <template v-if="isThemeUnlocked(theme.level)">
                <span
                  v-if="activeThemeClass === theme.themeClass"
                  class="px-3 py-1.5 rounded-lg bg-accent text-accent-contrast text-xs font-black uppercase tracking-wider shadow-sm flex items-center space-x-1"
                >
                  <span>✓</span>
                  <span>Active</span>
                </span>
                <button
                  v-else
                  type="button"
                  class="px-3 py-1.5 rounded-lg border border-border bg-card hover:bg-card-subtle text-foreground text-xs font-bold uppercase tracking-wider transition"
                  @click.stop="selectTheme(theme)"
                >
                  Activate
                </button>
              </template>
              <div
                v-else
                class="px-3 py-1.5 rounded-lg bg-card-subtle border border-border text-[11px] font-mono text-muted uppercase font-bold"
              >
                Locked
              </div>
            </div>
          </div>
        </div>

        <!-- Modal Footer Actions -->
        <div class="pt-4 mt-4 border-t border-border flex flex-col sm:flex-row items-center justify-between gap-3 shrink-0">
          <div class="text-xs text-muted">
            <span v-if="manualThemeOverride">
              Currently using a custom preview theme.
              <button
                type="button"
                class="text-accent hover:underline font-bold ml-1"
                @click="resetToAuto"
              >
                [Reset to Auto Clearance Tracking]
              </button>
            </span>
            <span v-else>
              Themes automatically adapt as your clearance level increases.
            </span>
          </div>

          <button
            type="button"
            class="w-full sm:w-auto px-5 py-2 rounded-xl text-xs font-extrabold uppercase tracking-wider transition bg-card border border-border hover:bg-card-subtle text-foreground cursor-pointer"
            @click="emit('close')"
          >
            Close Vault
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>
