<script setup lang="ts">
const { toasts, removeToast } = useToast()
</script>

<template>
  <div class="fixed bottom-6 right-6 z-[120] flex flex-col space-y-3 max-w-sm w-full pointer-events-none font-mono">
    <TransitionGroup
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="transform translate-y-4 opacity-0 scale-95"
      enter-to-class="transform translate-y-0 opacity-100 scale-100"
      leave-active-class="transition duration-200 ease-in"
      leave-from-class="transform translate-y-0 opacity-100 scale-100"
      leave-to-class="transform translate-y-2 opacity-0 scale-95"
    >
      <div
        v-for="toast in toasts"
        :key="toast.id"
        class="pointer-events-auto border rounded-xl p-4 shadow-xl backdrop-blur-md flex items-start justify-between gap-3"
        :class="[
          toast.type === 'error'
            ? 'border-danger/60 bg-danger/15 text-foreground shadow-glow-danger'
            : toast.type === 'success'
              ? 'border-success/60 bg-success/15 text-foreground shadow-glow-accent'
              : toast.type === 'warning'
                ? 'border-warning/60 bg-warning/15 text-foreground'
                : 'border-border bg-card/90 text-foreground'
        ]"
      >
        <div class="flex items-start space-x-2.5">
          <span class="text-sm font-bold shrink-0 mt-0.5">
            {{
              toast.type === 'error'
                ? '⛔'
                : toast.type === 'success'
                  ? '✓'
                  : toast.type === 'warning'
                    ? '⚠️'
                    : 'ℹ'
            }}
          </span>
          <div>
            <span
              v-if="toast.title"
              class="text-[10px] font-extrabold uppercase tracking-widest block mb-0.5"
              :class="[
                toast.type === 'error'
                  ? 'text-danger'
                  : toast.type === 'success'
                    ? 'text-success'
                    : toast.type === 'warning'
                      ? 'text-warning'
                      : 'text-accent'
              ]"
            >
              [{{ toast.title }}]
            </span>
            <p class="text-xs leading-relaxed text-foreground">
              {{ toast.message }}
            </p>
          </div>
        </div>

        <button
          class="text-xs text-muted hover:text-foreground shrink-0 font-bold ml-2"
          @click="removeToast(toast.id)"
        >
          ✕
        </button>
      </div>
    </TransitionGroup>
  </div>
</template>
