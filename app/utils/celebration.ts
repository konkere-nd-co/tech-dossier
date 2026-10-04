import confetti from 'canvas-confetti'

export const triggerConfetti = () => {
  if (!import.meta.client) return

  // Fire tactical celebratory burst
  confetti({
    particleCount: 80,
    spread: 60,
    origin: { y: 0.5 },
    colors: ['#0284c7', '#06b6d4', '#f59e0b', '#22c55e']
  })

  // Second burst for dramatic effect
  setTimeout(() => {
    confetti({
      particleCount: 50,
      angle: 60,
      spread: 55,
      origin: { x: 0 }
    })
    confetti({
      particleCount: 50,
      angle: 120,
      spread: 55,
      origin: { x: 1 }
    })
  }, 250)
}
