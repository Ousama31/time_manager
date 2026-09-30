<template>
  <section>
    <h2>Working Time</h2>

    <input v-model.number="workingTimeId" type="number" placeholder="Working Time ID" />
    <input v-model="start" placeholder="Start time" />
    <input v-model="end" placeholder="End time" />

    <button class="create-button" @click="createWorkingTime">Create</button>
    <button @click="updateWorkingTime">Update</button>
    <button class="delete-button" @click="deleteWorkingTime">Delete</button>
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

    workingTimeParams() {
      return {
        workingtime: {
          start: this.toIso(this.start),
          end: this.toIso(this.end)
        }
      }
    },

    createWorkingTime() {
      if (!this.userId) {
        return
      }

      axios
        .post(
          `/api/workingtime/${this.userId}`,
          this.workingTimeParams()
        )
        .then((response) => {
          this.workingTimeId = response.data.data.id
        })
        .catch((error) => {
          console.error(error)
        })
    },

    updateWorkingTime() {
      axios
        .put(
          `/api/workingtime/${this.workingTimeId}`,
          this.workingTimeParams()
        )
        .catch((error) => {
          console.error(error)
        })
    },

    deleteWorkingTime() {
      axios
        .delete(`/api/workingtime/${this.workingTimeId}`)
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
