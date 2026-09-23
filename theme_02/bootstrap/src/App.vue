<template>
  <div class="weather-app container">
    <!-- Top Search Card ("Où ?") -->
    <div class="card border-0 shadow-sm p-4 p-md-5 mb-4 top-card">
      <h1 class="text-center fw-bold mb-4 display-6">Où ?</h1>

      <!-- City selector -->
      <div class="row justify-content-center mb-4">
        <div class="col-12 col-md-11">
          <select
            v-model="selectedCity"
            @change="onCityChange"
            class="form-select form-select-lg city-select text-dark shadow-none"
          >
            <option v-for="cityName in availableCities" :key="cityName" :value="cityName">
              {{ cityName }}
            </option>
          </select>
        </div>
      </div>

      <!-- Navigation buttons -->
      <div class="d-flex justify-content-center gap-3 flex-wrap">
        <!-- Button: Météo actuelle -->
        <button
          type="button"
          class="btn btn-current px-4 py-2 fw-semibold"
          :class="{ 'btn-active-focus': isCurrentWeatherActive }"
          @click="navigateTo('currentWeather')"
        >
          Météo actuelle
        </button>

        <!-- Button: Prévision des températures maximales -->
        <button
          type="button"
          class="btn btn-forecast px-4 py-2 fw-semibold"
          :class="{ 'btn-active-focus': isForecastChartActive }"
          @click="navigateTo('forecastChart')"
        >
          Prévision des températures maximales
        </button>
      </div>
    </div>

    <!-- Active dynamic view (CurrentWeather or ForecastChart) -->
    <router-view :key="$route.fullPath" />
  </div>
</template>

<script>
export default {
  name: 'App',
  data() {
    return {
      selectedCity: 'Lyon',
      availableCities: [
        'Lyon',
        'Paris',
        'Marseille',
        'Bordeaux',
        'Lille',
        'Toulouse',
        'Nice',
        'Nantes',
        'Strasbourg',
        'Cotonou',
        'New York',
        'Tokyo',
        'Berlin',
        'Dubai'
      ]
    }
  },
  computed: {
    isCurrentWeatherActive() {
      return this.$route.name === 'currentWeather'
    },
    isForecastChartActive() {
      return this.$route.name === 'forecastChart'
    }
  },
  watch: {
    // Keep selected city synced with the URL parameter
    '$route.params.city': {
      immediate: true,
      handler(cityParam) {
        if (cityParam && this.selectedCity !== cityParam) {
          this.selectedCity = cityParam
        }
      }
    }
  },
  methods: {
    navigateTo(routeName) {
      this.$router.push({
        name: routeName,
        params: { city: this.selectedCity }
      })
    },
    onCityChange() {
      const currentRouteName = this.$route.name || 'forecastChart'
      this.$router.push({
        name: currentRouteName,
        params: { city: this.selectedCity }
      })
    }
  }
}
</script>

<style scoped>
.top-card {
  background-color: #eef1f6;
  border-radius: 12px;
}

.city-select {
  border-radius: 6px;
  border: 1px solid #ced4da;
  background-color: #ffffff;
  font-size: 1.05rem;
}

/* Button "Météo actuelle" */
.btn-current {
  background-color: #007bff;
  border-color: #007bff;
  color: #ffffff;
  border-radius: 4px;
}

.btn-current:hover {
  background-color: #0069d9;
  border-color: #0062cc;
  color: #ffffff;
}

/* Button "Prévision des températures maximales" */
.btn-forecast {
  background-color: #4a0072;
  border-color: #4a0072;
  color: #ffffff;
  border-radius: 4px;
}

.btn-forecast:hover {
  background-color: #380058;
  border-color: #380058;
  color: #ffffff;
}

/* Active focus ring matching the screenshot */
.btn-active-focus {
  outline: 2px dashed #304ffe;
  outline-offset: 2px;
}
</style>