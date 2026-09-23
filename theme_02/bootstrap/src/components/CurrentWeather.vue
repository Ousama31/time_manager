<template>
    <div>
      <h2>Current Weather</h2>
  
      <!-- Select a city -->
      <select v-model="city">
        <option v-for="town in cities" :key="town" :value="town">
          {{ town }}
        </option>
      </select>
  
      <!-- Refresh the weather -->
      <button v-on:click="refreshCurrentWeather">
        Search
      </button>
  
      <!-- Display weather data -->
      <p>City: {{ city }}</p>
      <p>Temperature: {{ temperature }}°C</p>
      <p>Date: {{ date }}</p>
    </div>
  </template>
  
  <script>
  export default {
    name: "CurrentWeather",
  
    // Component data
    data() {
      return {
        // Get the city from the URL
        city: this.$route.params.city,
        cities: ["Paris", "New York", "Tokyo", "Berlin", "Dubai"],
        temperature: 20,
        date: new Date().toLocaleDateString()
      }
    },
  
    methods: {
      // Generate a random temperature
      refreshCurrentWeather() {
        // Update the route and refresh the temperature
        this.$router.push(`/currentWeather/${this.city}`)
        // Generate a random temperature
        this.temperature = Math.floor(Math.random() * 30)
      }
    }
  }
  </script>