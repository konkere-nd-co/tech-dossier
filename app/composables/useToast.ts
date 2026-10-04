export interface ToastItem {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  title?: string
  message: string
  duration?: number
}

export const useToast = () => {
  const toasts = useState<ToastItem[]>('app-toasts', () => [])

  const removeToast = (id: string) => {
    toasts.value = toasts.value.filter(t => t.id !== id)
  }

  const addToast = (toast: Omit<ToastItem, 'id'>) => {
    const id = Math.random().toString(36).substring(2, 9)
    const duration = toast.duration ?? 4000

    const newToast: ToastItem = {
      ...toast,
      id
    }

    toasts.value.push(newToast)

    if (duration > 0 && import.meta.client) {
      setTimeout(() => {
        removeToast(id)
      }, duration)
    }

    return id
  }

  const success = (message: string, title = 'SUCCESS') => {
    return addToast({ type: 'success', title, message })
  }

  const error = (message: string, title = 'SECURITY FAULT') => {
    return addToast({ type: 'error', title, message })
  }

  const warning = (message: string, title = 'RESTRICTED') => {
    return addToast({ type: 'warning', title, message })
  }

  const info = (message: string, title = 'DISPATCH') => {
    return addToast({ type: 'info', title, message })
  }

  return {
    toasts,
    addToast,
    removeToast,
    success,
    error,
    warning,
    info
  }
}
