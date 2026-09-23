<template>
  <div class="forecast-card card border-0 shadow-sm p-4 p-md-5 mb-4">
    <!-- Title -->
    <h2 class="text-center fw-bold mb-4 mb-md-5 text-dark">
      Températures maximales des 5 prochains jours à {{ city }}
    </h2>

    <!-- Loading state -->
    <div v-if="loading" class="text-center py-4">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Chargement...</span>
      </div>
      <p class="text-muted mt-2">Chargement des prévisions météo...</p>
    </div>

    <!-- Error state -->
    <div v-else-if="errorMessage" class="alert alert-danger text-center" role="alert">
      {{ errorMessage }}
    </div>

    <!-- Dynamic 5-day forecast display -->
    <div v-else class="forecast-list">
      <div
        v-for="(day, index) in forecastDays"
        :key="index"
        class="forecast-row d-flex align-items-center mb-3"
      >
        <!-- Date (DD/MM/YYYY) -->
        <span class="date-label fw-bold text-dark text-end me-3">
          {{ day.date }}
        </span>

        <!-- Bootstrap Striped Progress Bar -->
        <div class="progress flex-grow-1 progress-container">
          <div
            class="progress-bar progress-bar-striped bg-primary"
            role="progressbar"
            :style="{ width: day.barWidth + '%' }"
            :aria-valuenow="day.maxTemp"
            aria-valuemin="0"
            aria-valuemax="50"
          ></div>
        </div>

        <!-- Temperature in °C -->
        <span class="temp-label fw-bold ms-3">
          {{ day.maxTemp }}°C
        </span>
      </div>

      <!-- Caption -->
      <p class="text-center text-muted small mt-4 mb-0">
        Prévisions des températures maximales en °C à {{ city }}
      </p>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'ForecastChart',
  data() {
    return {
      city: this.$route.params.city || 'Lyon',
      forecastDays: [],
      loading: false,
      errorMessage: null,
      apiKey: 'f2d2b1718ff807b36f899c38adfc8d55'
    }
  },
  watch: {
    // Watch for route param change when user switches city
    '$route.params.city': {
      immediate: true,
      handler(newCity) {
        if (newCity) {
          this.city = newCity
          this.fetchForecast()
        }
      }
    }
  },
  methods: {
    fetchForecast() {
      if (!this.city) return

      this.loading = true
      this.errorMessage = null

      const requestUrl = `https://api.openweathermap.org/data/2.5/forecast?q=${this.city}&units=metric&appid=${this.apiKey}`

      axios
        .get(requestUrl)
        .then((response) => {
          this.processForecastData(response.data)
          this.loading = false
        })
        .catch((error) => {
          console.error('Erreur API Forecast:', error)
          this.errorMessage = `Impossible de récupérer les prévisions pour "${this.city}".`
          this.loading = false
        })
    },

    processForecastData(data) {
      if (!data || !data.list) return

      // Group forecast timestamps by date (YYYY-MM-DD)
      const dailyMap = {}

      data.list.forEach((entry) => {
        // Entry dt_txt is "YYYY-MM-DD HH:mm:ss"
        const dateKey = entry.dt_txt.split(' ')[0]
        const temp = entry.main.temp_max

        if (!dailyMap[dateKey]) {
          dailyMap[dateKey] = {
            rawDate: dateKey,
            maxTemp: temp
          }
        } else {
          if (temp > dailyMap[dateKey].maxTemp) {
            dailyMap[dateKey].maxTemp = temp
          }
        }
      })

      // Take 5 days
      let days = Object.values(dailyMap).slice(0, 5)

      // In the mockup image, dates are shown in reverse chronological order (day 5 to day 1)
      days.reverse()

      // Calculate bar width (proportional scale up to 35-40°C)
      const maxScale = 35

      this.forecastDays = days.map((item) => {
        const [year, month, day] = item.rawDate.split('-')
        const formattedDate = `${day}/${month}/${year}`
        const tempRounded = Number(item.maxTemp.toFixed(1))

        // Ensure width is proportional and visible (between 10% and 95%)
        let width = Math.round((tempRounded / maxScale) * 100)
        if (width < 10) width = 10
        if (width > 95) width = 95

        return {
          date: formattedDate,
          maxTemp: tempRounded,
          barWidth: width
        }
      })
    }
  }
}
</script>

<style scoped>
.forecast-card {
  background-color: #eef1f6;
  border-radius: 12px;
}

.date-label {
  min-width: 95px;
  font-size: 0.95rem;
}

.progress-container {
  height: 20px;
  background-color: #dbe2ea;
  border-radius: 4px;
}

.progress-bar {
  background-color: #0b3df2 !important;
}

.temp-label {
  min-width: 65px;
  color: #0b3df2;
  font-size: 0.95rem;
}
</style>
