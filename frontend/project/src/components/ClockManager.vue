<template>
  <section>
    <h2>Clock Manager</h2>

    <p>User ID: {{ userId || "none" }}</p>
    <p>
      Status:
      <strong>{{ clockIn ? "Clocked In" : "Clocked Out" }}</strong>
    </p>
    <p v-if="startDateTime">
      Start Time: <strong>{{ startDateTime }}</strong>
    </p>

    <button @click="refresh">Refresh Status</button>
    <button @click="clock">
      {{ clockIn ? "Clock Out" : "Clock In" }}
    </button>
  </section>
</template>

<script>
import axios from 'axios'

export default {
  name: "ClockManager",

  props: ["userId"],

  data() {
    return {
      startDateTime: null,
      clockIn: false
    }
  },

  watch: {
    userId: {
      immediate: true,
      handler() {
        this.refresh()
      }
    }
  },

  methods: {
    resetClock() {
      this.clockIn = false
      this.startDateTime = null
    },

    refresh() {
      if (!this.userId) {
        this.resetClock()
        return
      }

      axios
        .get(`/api/clocks/${this.userId}`)
        .then((response) => {
          const clockData = response.data.data

          if (clockData && clockData.status) {
            this.clockIn = true
            this.startDateTime = clockData.time
          } else {
            this.resetClock()
          }
        })
        .catch(() => {
          this.resetClock()
        })
    },

    clock() {
      if (!this.userId) {
        return
      }

      if (!this.clockIn) {
        axios
          .post(`/api/clocks/${this.userId}`)
          .then((response) => {
            this.clockIn = true
            this.startDateTime = response.data.data.time
          })
          .catch((error) => {
            console.error(error)
          })
        return
      }

      const startTime = this.startDateTime
      const endTime = new Date().toISOString()

      axios
        .post(`/api/clocks/${this.userId}`)
        .then(() => {
          return axios.post(`/api/workingtime/${this.userId}`, {
            workingtime: {
              start: startTime,
              end: endTime
            }
          })
        })
        .then(() => {
          this.resetClock()
        })
        .catch((error) => {
          console.error(error)
          this.resetClock()
        })
    }
  }
}
</script>
