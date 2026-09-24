<template>
  <section>
    <h2>Clock Manager</h2>

    <p>User ID: {{ userId }}</p>
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

  data() {
    return {
      userId: 1,
      startDateTime: null,
      clockIn: false
    }
  },

  mounted() {
    this.refresh()
  },

  methods: {
    formatDate(date) {
      return date.getFullYear() + "-" +
        String(date.getMonth() + 1).padStart(2, '0') + "-" +
        String(date.getDate()).padStart(2, '0') + " " +
        String(date.getHours()).padStart(2, '0') + ":" +
        String(date.getMinutes()).padStart(2, '0') + ":" +
        String(date.getSeconds()).padStart(2, '0')
    },

    refresh() {
      axios
        .get(`http://localhost:4000/api/clocks/${this.userId}`)
        .then((response) => {
          const clockData = response.data.data || response.data
          if (clockData && clockData.status) {
            this.clockIn = clockData.status
            this.startDateTime = clockData.time
          } else {
            this.clockIn = false
            this.startDateTime = null
          }
        })
        .catch((error) => console.error("Error refreshing clock:", error))
    },

    clock() {
  const now = new Date()
  const nowFormatted = this.formatDate(now)

  if (!this.clockIn) {
    // --- CLOCK IN ---
    axios
      .post(`http://localhost:4000/api/clocks/${this.userId}`, {
        clock: {
          time: nowFormatted,
          status: true
        }
      })
      .then((response) => {
        console.log("Clocked in:", response.data)
        this.clockIn = true
        this.startDateTime = nowFormatted
      })
      .catch((error) => console.error("Error clocking in:", error))

  } else {
    // --- CLOCK OUT ---
    const startTime = this.startDateTime || nowFormatted
    const endTime = nowFormatted

    // Step A: Update Clock status to false
    axios
      .post(`http://localhost:4000/api/clocks/${this.userId}`, {
        clock: {
          time: endTime,
          status: false
        }
      })
      .then(() => {
        // Step B: Post to Workingtime using the "workingtime" key expected by your Phoenix controller
        return axios.post(`http://localhost:4000/api/workingtime/${this.userId}`, {
          workingtime: {
            start: startTime,
            end: endTime
          }
        })
      })
      .then((response) => {
        console.log("Working time recorded successfully:", response.data)
        this.clockIn = false
        this.startDateTime = null
      })
      .catch((error) => {
        console.error("Error creating working time:", error)
        // Reset UI so user isn't stuck
        this.clockIn = false
        this.startDateTime = null
      })
  }
}
  }
}
</script>