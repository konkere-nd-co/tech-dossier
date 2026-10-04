export default defineNuxtRouteMiddleware(async (to) => {
  const user = useSupabaseUser()
  const supabase = useSupabaseClient()

  const publicRoutes = ['/login', '/signup']
  const isPublicRoute = publicRoutes.includes(to.path)

  let currentUser = user.value
  if (!currentUser) {
    const { data } = await supabase.auth.getSession()
    if (data?.session?.user) {
      currentUser = data.session.user
      user.value = currentUser
    }
  }

  if (!currentUser && !isPublicRoute) {
    return navigateTo('/login')
  }

  if (currentUser && isPublicRoute) {
    return navigateTo('/')
  }
})
