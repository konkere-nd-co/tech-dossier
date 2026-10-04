<script setup lang="ts">
interface Props {
  modelValue?: boolean
  label?: string
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: false,
  label: 'Briefing Mode'
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'toggle', value: boolean): void
}>()

const handleToggle = () => {
  const nextValue = !props.modelValue
  emit('update:modelValue', nextValue)
  emit('toggle', nextValue)
}
</script>

<template>
  <div class="inline-flex items-center space-x-3 select-none">
    <!-- Optional Label -->
    <span v-if="label" class="text-xs uppercase tracking-wider font-bold text-tactical-muted">
      {{ label }}:
    </span>

    <!-- Tactile Toggle Control -->
    <button
      type="button"
      role="switch"
      :aria-checked="modelValue"
      class="relative inline-flex items-center p-0.5 rounded-lg border border-tactical-border bg-tactical-subtle cursor-pointer transition-colors focus:outline-none focus:ring-2 focus:ring-tactical-accent/40"
      @click="handleToggle"
    >
      <!-- Technical Mode Pill -->
      <span
        class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-md transition-all duration-200 flex items-center space-x-1.5"
        :class="[
          !modelValue
            ? 'bg-tactical-card text-tactical-accent shadow-sm border border-tactical-border'
            : 'text-tactical-muted hover:text-tactical-text'
        ]"
      >
        <span class="w-1.5 h-1.5 rounded-full" :class="!modelValue ? 'bg-tactical-accent' : 'bg-transparent'" />
        <span>Technical</span>
      </span>

      <!-- ELI5 Mode Pill -->
      <span
        class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-md transition-all duration-200 flex items-center space-x-1.5"
        :class="[
          modelValue
            ? 'bg-tactical-accent text-white shadow-glow-accent'
            : 'text-tactical-muted hover:text-tactical-text'
        ]"
      >
        <span class="w-1.5 h-1.5 rounded-full" :class="modelValue ? 'bg-white' : 'bg-transparent'" />
        <span>ELI5 Analogy</span>
      </span>
    </button>
  </div>
</template>
