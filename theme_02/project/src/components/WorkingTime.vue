<template>
  <section>
    <h2>Working Time</h2>

    <input v-model.number="workingTimeId" type="number" placeholder="Working Time ID" />
    <input v-model="start" placeholder="Start time" />
    <input v-model="end" placeholder="End time" />

    <button class="create-button" @click="createWorkingTime">Create</button>
    <button @click="updateWorkingTime">Update</button>
    <button class="delete-button"@click="deleteWorkingTime">Delete</button>
  </section>
</template>

<script>
import axios from 'axios'

export default {
  name: "WorkingTime",

  props: ["userId"],

  data() {
    return {
      workingTimeId: null,
      start: "",
      end: ""
    }
  },

  methods: {
    toIso(value) {
      return new Date(value).toISOString()
    },

    createWorkingTime() {
      if (!this.userId) {
        return
      }

      axios
        .post(`http://localhost:4000/api/workingtime/${this.userId}`, {
          workingtime: {
            start: this.toIso(this.start),
            end: this.toIso(this.end)
          }
        })
        .then((response) => {
          this.workingTimeId = response.data.data.id
        })
        .catch((error) => {
          console.error(error)
        })
    },

    updateWorkingTime() {
      axios
        .put(`http://localhost:4000/api/workingtime/${this.workingTimeId}`, {
          workingtime: {
            start: this.toIso(this.start),
            end: this.toIso(this.end)
          }
        })
        .catch((error) => {
          console.error(error)
        })
    },

    deleteWorkingTime() {
      axios
        .delete(`http://localhost:4000/api/workingtime/${this.workingTimeId}`)
        .then(() => {
          this.workingTimeId = null
          this.start = ""
          this.end = ""
        })
        .catch((error) => {
          console.error(error)
        })
    }
  }
}
</script>
