<template>
  <div class="weather-card card border-0 shadow-sm p-4 p-md-5 mb-4">
    <!-- Title -->
    <h2 class="text-center fw-bold mb-4 text-dark">
      Météo actuelle à {{ city }}
    </h2>

    <!-- Loading state -->
    <div v-if="loading" class="text-center py-4">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Chargement...</span>
      </div>
      <p class="text-muted mt-2">Récupération des données météo...</p>
    </div>

    <!-- Error state -->
    <div v-else-if="errorMessage" class="alert alert-danger text-center" role="alert">
      {{ errorMessage }}
    </div>

    <!-- Weather content -->
    <div v-else class="text-center">
      <div class="display-3 fw-bold text-primary mb-2">
        {{ temperature }}°C
      </div>
      <p class="text-secondary fs-5 mb-1">
        Conditions : <strong>{{ weatherDescription }}</strong>
      </p>
      <p class="text-muted small">
        Mise à jour le {{ date }}
      </p>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'CurrentWeather',

  data() {
    return {
      city: this.$route.params.city || 'Lyon',
      cities: ['Lyon', 'Paris', 'Marseille', 'Bordeaux', 'Lille', 'Nice', 'Strasbourg', 'Cotonou', 'New York', 'Tokyo', 'Berlin', 'Dubai'],
      temperature: 20,
      weatherDescription: 'Ensoleillé',
      date: new Date().toLocaleDateString('fr-FR'),
      loading: false,
      errorMessage: null,
      apiKey: 'f2d2b1718ff807b36f899c38adfc8d55'
    }
  },

  watch: {
    '$route.params.city': {
      immediate: true,
      handler(newCity) {
        if (newCity) {
          this.city = newCity
          this.fetchCurrentWeather()
        }
      }
    }
  },

  methods: {
    fetchCurrentWeather() {
      if (!this.city) return

      this.loading = true
      this.errorMessage = null

      const requestUrl = `https://api.openweathermap.org/data/2.5/weather?q=${this.city}&units=metric&appid=${this.apiKey}&lang=fr`

      axios
        .get(requestUrl)
        .then((response) => {
          this.temperature = Math.round(response.data.main.temp * 10) / 10
          if (response.data.weather && response.data.weather.length > 0) {
            this.weatherDescription = response.data.weather[0].description
          }
          this.loading = false
        })
        .catch((error) => {
          console.error('API Error:', error)
          this.errorMessage = `Impossible de récupérer la météo pour "${this.city}".`
          this.loading = false
        })
    },

    // Teammate's method maintained for compatibility
    refreshCurrentWeather() {
      this.$router.push(`/currentWeather/${this.city}`)
      this.fetchCurrentWeather()
    }
  }
}
</script>

<style scoped>
.weather-card {
  background-color: #eef1f6;
  border-radius: 12px;
}
</style>