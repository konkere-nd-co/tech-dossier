<script setup lang="ts">
import type { Database, Tables } from '~/types/database.types'

type Dossier = Tables<'dossiers'>

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient<Database>()
const { clearanceLevel, getTopicClearance } = useUserProfile()
const { render } = useMarkdown()
const { error: toastError } = useToast()

const slug = computed(() => route.params.slug as string)
const isEli5 = ref(false)

// Embedded Curated Analogies for ELI5 Briefings
const eli5Analogies: Record<string, string> = {
  'workspace-ecosystem': `# The Workspace Ecosystem (ELI5 Edition)

Imagine you are running a lemonade stand:
- **A Word Document** is your **secret recipe notebook** and advertising poster where you write down stories, ideas, and instructions for people to read.
- **A Spreadsheet** is your **cash register and inventory sheet** made of magic graph paper. Every time you sell a cup, it calculates your profit, subtracts lemons from your stock, and does the math for you without a calculator.

You don't need to know how to write code to build and run an entire organization with these tools!`,

  'how-internet-works': `# How the Internet Actually Works (ELI5 Edition)

Imagine the internet is a massive, lightning-fast **global postal service**:
- The "Cloud" isn't floating in the sky—it's just a warehouse full of computers in another city.
- When you type an address into your browser, you are putting a letter into an envelope.
- Tiny robot couriers carry your letter through **real glass tubes (fiber-optic cables)** buried under the streets and across the bottom of the ocean.
- The computer across the world reads your letter and immediately mails you back the pictures, videos, and words you requested!`,

  'security-101': `# Security 101 (ELI5 Edition)

Imagine your digital life is a **secret treehouse**:
- A **password** is the secret knock. If your secret knock is just "1-2-3-4" or "password", anyone can walk right in!
- A **password manager** is a robotic locksmith that makes a completely unbreakable, unique 30-letter lock for every single door you own.
- **Two-Factor Authentication (2FA)** is like having both a key AND a guard dog who texts your walkie-talkie to ask: *"Did you just try to open this door?"*`,

  'web-architecture': `# Web Architecture (ELI5 Edition)

Think of any website like building a **house**:
- **HTML** is the **wooden frame, walls, and foundation**. It decides where the rooms, windows, and doors are placed.
- **CSS** is the **interior decorator, paint, wallpaper, and landscaping**. It makes the house look stunning, colorful, and inviting.
- **JavaScript** is the **electricity, plumbing, and smart garage door**. It allows you to flip switches, turn on faucets, and make the house react when you interact with it!`,

  'what-is-an-api': `# What is an API? (ELI5 Edition)

An API is like a **friendly waiter at a restaurant**:
- **You (The Client/App)** are sitting at the dining table looking at the menu.
- **The Kitchen (The Database/Server)** is where the chefs store ingredients and cook the meals.
- You can't just walk into the kitchen and touch the stoves yourself.
- Instead, you tell the **waiter (The API)**: *"Please bring me a burger."*
- The waiter takes your order to the kitchen, gets the cooked burger, and delivers it safely back to your table!`,

  'databases-explained': `# Databases Explained (ELI5 Edition)

If APIs are the waiters, where do they store the ingredients?
- A **Relational Database (SQL)** is like a **super-strict filing cabinet with labeled folders**. Every record gets an exact category and strict rules. If you try to put a shoe in a folder labeled "Birth Dates", it won't let you!
- A **Document Database (NoSQL)** is like a **toy chest**. You can throw in toy cars, stuffed bears, or drawings all together in one flexible box without filling out paperwork first.`,

  'design-literacy': `# Design Literacy (ELI5 Edition)

Why do some rooms feel peaceful while others feel chaotic?
- **Whitespace (Breathing Room):** Imagine a bedroom crammed with 50 chairs and 200 boxes. You can barely walk. Good design clears out the clutter so the few things that matter have room to breathe.
- **Typography (Readable Lettering):** Good fonts are like someone speaking in a calm, clear voice rather than shouting in messy scribble. When design is great, you don't notice it—you just feel comfortable and focused.`,

  'ai-and-llms': `# AI & LLMs (ELI5 Edition)

Imagine the **ultimate predictive autocomplete**:
- When you type *"Once upon a..."* on your phone, it suggests *"time"*.
- AI models like ChatGPT don't have human feelings or consciousness. Instead, they have read trillions of pages from the internet and learned the statistical pattern of how words follow each other.
- When you ask a question, the AI calculates: *"Given everything this human said, what is mathematically the most helpful sequence of words to come next?"*`,

  'iot-hardware': `# The Internet of Things (ELI5 Edition)

Think of IoT as giving a computer **eyes, ears, and hands in the physical world**:
- Regular software only lives inside a computer screen.
- An **IoT device** (like a smart thermostat or robotic vacuum) connects a computer chip to real-world sensors (thermometers, cameras) and motors (wheels, valves).
- Now software can feel that your living room is cold and physically turn on the heater before you even arrive home!`,

  'browser-wars': `# The Browser Wars (ELI5 Edition)

Imagine two rival toy companies making railroad tracks:
- In the 1990s, Netscape and Microsoft both wanted you to use their tracks.
- Company A built tracks that were 4 inches wide. Company B built tracks that were 5 inches wide.
- Trains built for Company A would derail on Company B's tracks!
- The "Browser Wars" forced everyone to agree on standard open specifications so that one website would work on every device without breaking.`
}

// Fetch single dossier via useAsyncData
const { data: dossier, error, status } = await useAsyncData(
  `dossier-${slug.value}`,
  async () => {
    const { data, error: fetchErr } = await supabase
      .from('dossiers')
      .select('*')
      .eq('slug', slug.value)
      .maybeSingle()

    if (fetchErr) throw fetchErr
    return data as Dossier | null
  }
)

// Clearance Guard: Check if user has sufficient clearance in this topic
const checkClearanceAccess = () => {
  if (dossier.value) {
    const topicLevel = getTopicClearance(dossier.value.category)
    if (dossier.value.required_clearance > topicLevel) {
      toastError(
        `Clearance Level ${dossier.value.required_clearance} in "${dossier.value.category}" required. Access denied.`,
        'ACCESS RESTRICTED'
      )
      router.replace({
        path: '/',
        query: {
          denied: 'true',
          slug: slug.value,
          required: dossier.value.required_clearance.toString()
        }
      })
    }
  }
}

onMounted(() => {
  checkClearanceAccess()
})

watch(
  [() => dossier.value, () => clearanceLevel.value],
  () => {
    checkClearanceAccess()
  }
)

// Active content markdown based on ELI5 toggle state
const activeContent = computed(() => {
  if (!dossier.value) return ''
  if (isEli5.value && eli5Analogies[slug.value]) {
    return eli5Analogies[slug.value]
  }
  return dossier.value.content_markdown
})

const renderedHtml = computed(() => {
  return render(activeContent.value)
})
</script>

<template>
  <div class="min-h-screen bg-background text-foreground font-mono flex flex-col transition-colors duration-300">
    <!-- Header Navigation with Integrated ClearanceBar -->
    <header class="border-b border-border bg-card/85 backdrop-blur sticky top-0 z-40">
      <div class="max-w-5xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between gap-4">
        <!-- Back to Briefing Room -->
        <NuxtLink
          to="/"
          class="flex items-center space-x-2 text-xs font-bold uppercase tracking-wider text-muted hover:text-accent transition shrink-0"
        >
          <span>←</span>
          <span class="hidden sm:inline">Back to Briefing Room</span>
          <span class="sm:hidden">Back</span>
        </NuxtLink>

        <!-- Header Integrated ClearanceBar (Desktop & Tablet) -->
        <div class="hidden sm:flex flex-1 max-w-xs lg:max-w-sm mx-4 items-center">
          <ClearanceBar
            :active-topic="dossier?.category"
            is-compact
          />
        </div>

        <!-- Session Management Dropdown -->
        <div class="shrink-0">
          <UserNavDropdown />
        </div>
      </div>
    </header>

    <!-- Main Dossier Content -->
    <main class="flex-1 max-w-5xl w-full mx-auto px-4 sm:px-6 py-8">
      <!-- Loading Skeleton State -->
      <div v-if="status === 'pending'">
        <DossierDetailSkeleton />
      </div>

      <!-- Not Found State -->
      <div
        v-else-if="!dossier || error"
        class="border border-danger/40 bg-danger/10 rounded-xl p-8 text-center"
      >
        <div class="text-danger font-bold text-sm uppercase tracking-wider mb-2">
          [ARCHIVE ERROR: RECORD NOT FOUND OR RESTRICTED]
        </div>
        <p class="text-xs text-muted mb-4 leading-relaxed">
          The requested intelligence dossier does not exist, or you lack the required security clearance to decrypt its records.
        </p>
        <NuxtLink
          to="/"
          class="inline-block px-4 py-2 bg-border hover:bg-border/70 text-foreground text-xs uppercase font-bold rounded-lg transition"
        >
          Return to Dashboard
        </NuxtLink>
      </div>

      <!-- Dossier View -->
      <article v-else class="space-y-6">
        <!-- Dossier Top Classification Banner -->
        <div class="border border-border rounded-xl p-6 bg-card shadow-sm">
          <div class="flex flex-wrap items-center justify-between gap-3 border-b border-border/60 pb-4 mb-4">
            <div class="flex items-center space-x-2 text-xs">
              <span class="px-2.5 py-0.5 rounded text-[11px] font-bold uppercase tracking-wider bg-accent/15 text-accent border border-accent/30">
                {{ dossier.category }}
              </span>
              <span class="text-border">|</span>
              <span class="text-muted text-[11px] uppercase tracking-wider font-semibold">
                {{ dossier.is_code_related ? '⚡ Technical Architecture' : '📄 Operational Practice' }}
              </span>
            </div>

            <span class="text-xs px-2.5 py-1 rounded bg-card-subtle text-accent border border-border font-bold uppercase tracking-wider">
              Required Clearance: Level {{ dossier.required_clearance }}
            </span>
          </div>

          <h1 class="text-2xl sm:text-3xl font-extrabold text-foreground tracking-tight mb-3">
            {{ dossier.title }}
          </h1>

          <p class="text-sm text-muted leading-relaxed max-w-3xl">
            {{ dossier.briefing_summary }}
          </p>
        </div>

        <!-- Mode Toggle & Reading Panel -->
        <div class="border border-border rounded-xl p-6 sm:p-8 bg-card shadow-sm">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between pb-6 mb-6 border-b border-border gap-4">
            <div class="flex items-center space-x-2 text-xs text-muted">
              <span class="w-2 h-2 rounded-full bg-accent" />
              <span class="uppercase tracking-wider font-bold">
                {{ isEli5 ? 'Simplified Analogy Active' : 'Standard Technical Dossier' }}
              </span>
            </div>

            <!-- Eli5 Toggle Component -->
            <Eli5Toggle v-model="isEli5" label="Intel Presentation" />
          </div>

          <!-- ELI5 Notice Banner if toggled -->
          <div
            v-if="isEli5"
            class="mb-6 p-4 rounded-lg border border-accent/40 bg-accent/10 text-foreground text-xs flex items-start space-x-3"
          >
            <span class="text-base leading-none">💡</span>
            <div>
              <span class="font-bold text-accent uppercase tracking-wider block mb-0.5">
                ELI5 Analogy Mode Engaged
              </span>
              <span class="text-muted leading-relaxed">
                Technical jargon has been converted into tangible, everyday metaphors for intuitive comprehension.
              </span>
            </div>
          </div>

          <!-- Markdown Content Body -->
          <div
            class="markdown-body"
            v-html="renderedHtml"
          />

          <!-- Dossier Footer Action -->
          <div class="mt-12 pt-6 border-t border-border flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-muted">
            <span>Dossier ID: {{ dossier.id.slice(0, 8) }}...</span>
            <NuxtLink
              to="/"
              class="px-4 py-2 rounded-lg border border-border hover:border-accent text-foreground font-bold uppercase tracking-wider transition hover:bg-card-subtle"
            >
              ← Back to Briefing Room
            </NuxtLink>
          </div>
        </div>
      </article>
    </main>
  </div>
</template>
