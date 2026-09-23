// Import Vue Router
import { createRouter, createWebHistory } from 'vue-router'

// Import the weather component
import CurrentWeather from '../components/CurrentWeather.vue'

// Define application routes
const router = createRouter({
  history: createWebHistory(),

  routes: [
    {
      path: '/currentWeather/:city',
      name: 'currentWeather',
      component: CurrentWeather
    }
  ]
})

export default router