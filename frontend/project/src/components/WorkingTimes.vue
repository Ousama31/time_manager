<template>
  <section>
    <h2>Working Times</h2>

    <button @click="getWorkingTimes">Get Working Times</button>

    <div v-for="workingTime in workingTimes" :key="workingTime.id">
      <p>
        ID: {{ workingTime.id }}
        <br />
        Start: {{ workingTime.start }}
        <br />
        End: {{ workingTime.end }}
      </p>
    </div>
  </section>
</template>

<script>
import axios from 'axios'

export default {
  name: "WorkingTimes",

  props: ["userId"],

  data() {
    return {
      workingTimes: []
    }
  },

  watch: {
    userId() {
      this.workingTimes = []
    }
  },

  methods: {
    getWorkingTimes() {
      if (!this.userId) {
        return
      }

      axios
        .get(`/api/workingtime/${this.userId}`)
        .then((response) => {
          this.workingTimes = response.data.data
        })
        .catch((error) => {
          console.error(error)
        })
    }
  }
}
</script>
