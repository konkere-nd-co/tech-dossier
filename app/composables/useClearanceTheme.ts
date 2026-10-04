export type ClearanceThemeClass = 'theme-lvl-1' | 'theme-lvl-2' | 'theme-lvl-3' | 'theme-lvl-4'

export interface ThemeDefinition {
  level: number
  themeClass: ClearanceThemeClass
  code: string
  name: string
  desc: string
  previewBg: string
  previewCard: string
  previewAccent: string
  previewText: string
}

export const THEME_DEFINITIONS: ThemeDefinition[] = [
  {
    level: 1,
    themeClass: 'theme-lvl-1',
    code: 'L1',
    name: 'Level 1: Civilian Observer',
    desc: 'Clean, bright, standard web briefing style with crisp slate borders and cerulean blue accents.',
    previewBg: '#f8fafc',
    previewCard: '#ffffff',
    previewAccent: '#0284c7',
    previewText: '#0f172a'
  },
  {
    level: 2,
    themeClass: 'theme-lvl-2',
    code: 'L2',
    name: 'Level 2: Field Operative',
    desc: 'Console dark mode with slate grays and subtle cold cyan telemetry.',
    previewBg: '#0b1120',
    previewCard: '#0f172a',
    previewAccent: '#38bdf8',
    previewText: '#f1f5f9'
  },
  {
    level: 3,
    themeClass: 'theme-lvl-3',
    code: 'L3',
    name: 'Level 3: System Specialist',
    desc: 'Cyber-tactical dark mode with deep obsidian tones and high-contrast neon amber accents.',
    previewBg: '#09090b',
    previewCard: '#121216',
    previewAccent: '#f59e0b',
    previewText: '#fafafa'
  },
  {
    level: 4,
    themeClass: 'theme-lvl-4',
    code: 'L4',
    name: 'Level 4: Black-Ops Architect',
    desc: 'Full CRT terminal aesthetic with pure black matrix background and glowing phosphor green text.',
    previewBg: '#000000',
    previewCard: '#040a04',
    previewAccent: '#22c55e',
    previewText: '#4ade80'
  }
]

export const useClearanceTheme = () => {
  const { clearanceLevel } = useUserProfile()
  
  // Allow manual preview override or strictly bind to user clearance
  const manualThemeOverride = useState<ClearanceThemeClass | null>('manual-theme-override', () => null)
  
  // Upgrade celebration state
  const upgradeNotification = useState<{
    show: boolean
    fromLevel: number
    toLevel: number
    title: string
  }>('upgrade-notification', () => ({
    show: false,
    fromLevel: 1,
    toLevel: 1,
    title: ''
  }))

  const activeThemeClass = computed<ClearanceThemeClass>(() => {
    if (manualThemeOverride.value) {
      return manualThemeOverride.value
    }

    const level = clearanceLevel.value || 1
    if (level === 1) return 'theme-lvl-1'
    if (level === 2) return 'theme-lvl-2'
    if (level === 3) return 'theme-lvl-3'
    return 'theme-lvl-4'
  })

  const themeMeta = computed(() => {
    const found = THEME_DEFINITIONS.find(t => t.themeClass === activeThemeClass.value)
    if (found) {
      return {
        code: found.code,
        name: found.name,
        desc: found.desc
      }
    }
    return {
      code: 'L1',
      name: 'Level 1: Civilian Observer',
      desc: 'Clean, bright, standard web briefing style'
    }
  })

  const unlockedThemesCount = computed(() => {
    return Math.min(4, Math.max(1, clearanceLevel.value || 1))
  })

  const isThemeUnlocked = (level: number) => {
    return (clearanceLevel.value || 1) >= level
  }

  // Apply to document element
  const applyThemeToDom = (newTheme: string) => {
    if (import.meta.client) {
      const root = document.documentElement
      const body = document.body
      const themes = [
        'theme-lvl-1',
        'theme-lvl-2',
        'theme-lvl-3',
        'theme-lvl-4',
        'theme-standard',
        'theme-dev-console',
        'theme-tactical-dark',
        'theme-terminal'
      ]
      
      themes.forEach(t => {
        root.classList.remove(t)
        body?.classList.remove(t)
      })

      root.classList.add(newTheme)
      body?.classList.add(newTheme)
    }
  }

  if (import.meta.client) {
    watch(
      activeThemeClass,
      (newTheme) => {
        applyThemeToDom(newTheme)
      },
      { immediate: true }
    )
  }

  const triggerUpgradeCelebration = (fromLevel: number, toLevel: number) => {
    const titles: Record<number, string> = {
      1: 'Civilian Observer',
      2: 'Field Operative',
      3: 'System Specialist',
      4: 'Black-Ops Architect'
    }

    upgradeNotification.value = {
      show: true,
      fromLevel,
      toLevel,
      title: titles[toLevel] || `Classified Tier ${toLevel}`
    }

    setTimeout(() => {
      upgradeNotification.value.show = false
    }, 4500)
  }

  return {
    activeThemeClass,
    themeMeta,
    manualThemeOverride,
    upgradeNotification,
    unlockedThemesCount,
    isThemeUnlocked,
    setManualTheme: (theme: ClearanceThemeClass | null) => {
      manualThemeOverride.value = theme
    },
    triggerUpgradeCelebration,
    dismissUpgradeNotification: () => {
      upgradeNotification.value.show = false
    }
  }
}
