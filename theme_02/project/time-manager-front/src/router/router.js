import{createRouter, createWebHistory} from 'vue-router'

//import all routes from component, but User w'll be global in all routes
import WorkingTimes from '../components/WorkingTimes.vue'
import WorkingTime from '../components/WorkingTime.vue'
import ClockManager from '../components/ClockManager.vue'
import ChartManager from '../components/ChartManager.vue'

const router = createRouter({ history: createWebHistory(import.meta.env.BASE_URL),
    routes: [
    {
      path: '/workingTimes/:userID',
      name: 'workingTimes',
      component: WorkingTimes
    },
    {
      path: '/workingTime/:userid',
      name: 'createWorkingTime',
      component: WorkingTime
    },
    {
      path: '/workingTime/:userid/:workingtimeid',
      name: 'manageWorkingTime',
      component: WorkingTime
    },
    {
      path: '/clock/:userid',
      name: 'clockManager',
      component: ClockManager
    },
    {
      path: '/chartManager/:userid',
      name: 'chartManager',
      component: ChartManager
    }
  ]
})
export default router