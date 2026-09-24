<template>
    <section>
      <h2>Working Times</h2>
  
      <!-- Load working times for the current user -->
      <button @click="getWorkingTimes">
        Get Working Times
      </button>
  
      <!-- Display each working time -->
      <div v-for="workingTime in workingTimes" :key="workingTime.id">
        <p>
          Start: {{ workingTime.start }}
          <br />
          End: {{ workingTime.end }}
        </p>
      </div>
    </section>
  </template>
  
  <script>
  // Import Axios
  import axios from 'axios'
  
  export default {
    name: "WorkingTimes",
  
    // Component data
    data() {
      return {
        userId: 1,
        workingTimes: []
      }
    },
  
    methods: {
      // Get all working times for one user(calls theme_01 API)
      getWorkingTimes() {
        axios
          // Call the Phoenix API
          .get(`http://localhost:4000/api/workingtime/${this.userId}`)
  
          // Save the returned working times
          .then((response) => {
            console.log(response.data)
            this.workingTimes = response.data.data
          })
  
          // Show errors in the console
          .catch((error) => {
            console.error(error)
          })
      }
    }
  }
  </script>