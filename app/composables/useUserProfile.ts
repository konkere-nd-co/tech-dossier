import type { Database, Tables } from '~/types/database.types'

export type UserProfile = Tables<'users'>

export interface TopicClearanceRecord {
  level: number
  points: number
}

export type TopicClearances = Record<string, TopicClearanceRecord>

export const ALL_TOPICS = [
  'Internet Basics',
  'Security',
  'Workspace Ops',
  'Web Architecture',
  'System Architecture',
  'Design',
  'Artificial Intelligence',
  'Hardware & IoT',
  'Tech History'
] as const

export type TopicCategory = typeof ALL_TOPICS[number]

export const TOPIC_METADATA: Record<string, { icon: string; description: string }> = {
  'Internet Basics': {
    icon: '🌐',
    description: 'Foundational networking, DNS, IP routing, and the global physical web pipeline.'
  },
  'Security': {
    icon: '🛡️',
    description: 'Defensive postures, cryptography, authentication vectors, and threat surface elimination.'
  },
  'Workspace Ops': {
    icon: '⚡',
    description: 'Operational productivity stacks, document workflows, and structured business tooling.'
  },
  'Web Architecture': {
    icon: '🧱',
    description: 'HTML structure, cascading visual systems, JavaScript runtime, and client rendering.'
  },
  'System Architecture': {
    icon: '🔌',
    description: 'APIs, service contracts, data persistence (SQL/NoSQL), and distributed systems.'
  },
  'Design': {
    icon: '📐',
    description: 'Strategic whitespace, typographic hierarchy, visual rhythm, and cognitive accessibility.'
  },
  'Artificial Intelligence': {
    icon: '🧠',
    description: 'Statistical token generation, LLMs, neural networks, and transformer attention logic.'
  },
  'Hardware & IoT': {
    icon: '📡',
    description: 'Microcontrollers, embedded sensor telemetry, Edge IoT firmware, and hardware protocols.'
  },
  'Tech History': {
    icon: '📜',
    description: 'Epochal architectural paradigms, browser wars, and technological turning points.'
  }
}

export const useUserProfile = () => {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()

  const profile = useState<UserProfile | null>('user-profile', () => null)
  const isLoading = useState<boolean>('user-profile-loading', () => false)
  const profileError = useState<string | null>('user-profile-error', () => null)

  const clearanceLevel = computed(() => profile.value?.clearance_level ?? 1)
  const intelPoints = computed(() => profile.value?.intel_points ?? 0)

  const selectedTopics = computed<string[]>(() => {
    const topics = profile.value?.selected_topics
    if (!topics || topics.length === 0) return ['ALL']
    return topics
  })

  const isJackOfAllTrades = computed<boolean>(() => {
    return selectedTopics.value.includes('ALL') || selectedTopics.value.length === ALL_TOPICS.length
  })

  const topicClearances = computed<TopicClearances>(() => {
    return (profile.value?.topic_clearances as TopicClearances) || {}
  })

  const getTopicClearance = (category: string): number => {
    const clearances = topicClearances.value
    if (clearances && clearances[category]?.level) {
      return clearances[category].level
    }
    return profile.value?.clearance_level ?? 1
  }

  const getTopicPoints = (category: string): number => {
    const clearances = topicClearances.value
    if (clearances && clearances[category]?.points !== undefined) {
      return clearances[category].points
    }
    return 0
  }

  const fetchProfile = async () => {
    if (!user.value) {
      profile.value = null
      return null
    }

    try {
      isLoading.value = true
      profileError.value = null

      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.value.id)
        .maybeSingle()

      if (error) {
        profileError.value = error.message
        return null
      }

      if (data) {
        profile.value = data
      } else {
        profile.value = {
          id: user.value.id,
          email: user.value.email || '',
          clearance_level: 1,
          intel_points: 0,
          selected_topics: ['ALL'],
          topic_clearances: {},
          created_at: new Date().toISOString()
        }
      }

      return profile.value
    } catch (err: any) {
      profileError.value = err.message || 'Failed to fetch user profile'
      return null
    } finally {
      isLoading.value = false
    }
  }

  const updateInterests = async (topics: string[]) => {
    const normalized = topics.length === 0 || topics.includes('ALL') ? ['ALL'] : topics

    // Optimistically update local profile
    if (profile.value) {
      profile.value = {
        ...profile.value,
        selected_topics: normalized
      }
    }

    if (user.value) {
      const { error } = await supabase.rpc('update_user_interests', {
        p_selected_topics: normalized
      })
      if (error) {
        await supabase
          .from('users')
          .update({ selected_topics: normalized })
          .eq('id', user.value.id)
      }
    }
  }

  const applyTopicUpgrade = (category: string, newTopicLevel: number, overallClearance: number, newTotalPoints: number, updatedClearances?: TopicClearances) => {
    if (!profile.value) return

    const newTopicClearances: TopicClearances = updatedClearances || {
      ...topicClearances.value,
      [category]: {
        level: newTopicLevel,
        points: (topicClearances.value[category]?.points || 0) + 100
      }
    }

    profile.value = {
      ...profile.value,
      clearance_level: Math.max(profile.value.clearance_level, overallClearance, newTopicLevel),
      intel_points: newTotalPoints,
      topic_clearances: newTopicClearances as any
    }
  }

  const logout = async () => {
    await supabase.auth.signOut()
    profile.value = null
    navigateTo('/login')
  }

  // React to user session changes
  watch(
    () => user.value,
    (newUser) => {
      if (newUser) {
        fetchProfile()
      } else {
        profile.value = null
      }
    },
    { immediate: true }
  )

  return {
    user,
    profile,
    clearanceLevel,
    intelPoints,
    selectedTopics,
    isJackOfAllTrades,
    topicClearances,
    getTopicClearance,
    getTopicPoints,
    updateInterests,
    applyTopicUpgrade,
    isLoading,
    profileError,
    fetchProfile,
    logout
  }
}
