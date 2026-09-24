<script>
// Import the required components
import User from './components/User.vue'
import WorkingTimes from './components/WorkingTimes.vue'
import WorkingTime from './components/WorkingTime.vue'
import ClockManager from './components/ClockManager.vue'
import ChartManager from './components/ChartManager.vue'

export default {
  // Register the components
  components: {
    User,
    WorkingTimes,
    WorkingTime,
    ClockManager,
    ChartManager
  }
}
</script>

<template>
  <main>
    <!-- Display all required components -->
    <User />
    <ClockManager />
    <WorkingTimes />
    <WorkingTime />
    <ChartManager />
  </main>
</template>