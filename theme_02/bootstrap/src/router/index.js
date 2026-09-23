// Import Vue Router
import { createRouter, createWebHashHistory } from 'vue-router'

// Import components
import CurrentWeather from '../components/CurrentWeather.vue'
import ForecastChart from '../components/ForecastChart.vue'

// Define application routes
const router = createRouter({
  // Use hash history to support URLs like /#/forecastChart/Lyon
  history: createWebHashHistory(),

  routes: [
    {
      path: '/',
      redirect: '/forecastChart/Lyon'
    },
    {
      path: '/currentWeather/:city',
      name: 'currentWeather',
      component: CurrentWeather
    },
    {
      path: '/forecastChart/:city',
      name: 'forecastChart',
      component: ForecastChart
    }
  ]
})

export default router