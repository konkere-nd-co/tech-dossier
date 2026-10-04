export default defineNuxtRouteMiddleware((to) => {
  const user = useSupabaseUser()

  const publicRoutes = ['/login', '/signup']
  const isPublicRoute = publicRoutes.includes(to.path)

  if (!user.value && !isPublicRoute) {
    return navigateTo('/login')
  }

  if (user.value && isPublicRoute) {
    return navigateTo('/')
  }
})
