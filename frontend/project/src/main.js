import './assets/main.css'
import './assets/styles/auth.css'

import { createApp } from 'vue'
import App from './App.vue'

import router from './router'
import './assets/styles/dashboard.css'

createApp(App)
  .use(router)
  .mount('#app')
