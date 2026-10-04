export default defineNuxtRouteMiddleware(async () => {
  const user = useSupabaseUser()
  const supabase = useSupabaseClient()

  let currentUser = user.value
  if (!currentUser) {
    const { data } = await supabase.auth.getSession()
    if (data?.session?.user) {
      currentUser = data.session.user
      user.value = currentUser
    }
  }

  if (!currentUser) {
    return navigateTo('/login')
  }
})
