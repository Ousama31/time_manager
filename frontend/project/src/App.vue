<script>
import User from './components/User.vue'
import WorkingTimes from './components/WorkingTimes.vue'
import WorkingTime from './components/WorkingTime.vue'
import ClockManager from './components/ClockManager.vue'
import ChartManager from './components/ChartManager.vue'

export default {
  components: {
    User,
    WorkingTimes,
    WorkingTime,
    ClockManager,
    ChartManager
  },

  data() {
    return {
      currentUserId: null
    }
  },

  methods: {
    changeUser(userId) {
      this.currentUserId = userId
    }
  }
}
</script>

<template>
  <main>
    <User @userChanged="changeUser" />
    <ClockManager :userId="currentUserId" />
    <WorkingTimes :userId="currentUserId" />
    <WorkingTime :userId="currentUserId" />
    <ChartManager :userId="currentUserId" />
  </main>
</template>
