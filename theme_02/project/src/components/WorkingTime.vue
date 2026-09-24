<template>
    <section>
      <h2>Working Time</h2>
  
      <!-- Working time form -->
      <input v-model="start" placeholder="Start: 2026-09-24 09:00:00" />
      <input v-model="end" placeholder="End: 2026-09-24 17:00:00" />
  
      <!-- Working time actions -->
      <button @click="createWorkingTime">Create Working Time</button>
      <button @click="updateWorkingTime">Update Working Time</button>
      <button @click="deleteWorkingTime">Delete Working Time</button>
    </section>
  </template>
  
  <script>
  // Import Axios
  import axios from 'axios'
  
  export default {
    name: "WorkingTime",
  
    // Working time data
    data() {
      return {
        userId: 1,
        workingTimeId: 1,
        start: "",
        end: ""
      }
    },
  
    methods: {
      // Create a new working time
      createWorkingTime() {
        axios
          // Send the working time to the backend
          .post(`http://localhost:4000/api/workingtime/${this.userId}`, {
            workingtime: {
              start: this.start,
              end: this.end
            }
          })
  
          // Save the new working time ID
          .then((response) => {
            console.log(response.data)
            this.workingTimeId = response.data.data.id
          })
  
          // Show errors
          .catch((error) => {
            console.error(error)
          })
      },
  
      // Update an existing working time
      updateWorkingTime() {
        axios
          // Send updated start and end values
          .put(`http://localhost:4000/api/workingtime/${this.workingTimeId}`, {
            workingtime: {
              start: this.start,
              end: this.end
            }
          })
  
          // Show the updated result
          .then((response) => {
            console.log(response.data)
          })
  
          // Show errors
          .catch((error) => {
            console.error(error)
          })
      },
  
      // Delete a working time
      deleteWorkingTime() {
        axios
          // Delete the working time by ID
          .delete(`http://localhost:4000/api/workingtime/${this.workingTimeId}`)
  
          // Clear the form after deletion
          .then(() => {
            this.start = ""
            this.end = ""
          })
  
          // Show errors
          .catch((error) => {
            console.error(error)
          })
      }
    }
  }
  </script>