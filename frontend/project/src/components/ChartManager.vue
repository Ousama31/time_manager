<template>
  <section class="charts">
    <h2>Chart Manager</h2>

    <button @click="getWorkingTimes">Load Charts</button>

    <p v-if="message">{{ message }}</p>

    <div class="chart-grid" v-if="barData.labels.length">
      <div class="chart">
        <h3>Hours Worked</h3>
        <div class="chart-content">
          <Bar :data="barData" :options="chartOptions" />
        </div>
      </div>

      <div class="chart">
        <h3>Hours Over Time</h3>
        <div class="chart-content">
          <Line :data="lineData" :options="chartOptions" />
        </div>
      </div>

      <div class="chart">
        <h3>Work Sessions</h3>
        <div class="chart-content">
          <Pie :data="pieData" :options="chartOptions" />
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import axios from 'axios'
import { Bar, Line, Pie } from 'vue-chartjs'

import {
  Chart as ChartJS,
  BarElement,
  LineElement,
  PointElement,
  ArcElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend
} from 'chart.js'

ChartJS.register(
  BarElement,
  LineElement,
  PointElement,
  ArcElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend
)

export default {
  name: "ChartManager",

  components: {
    Bar,
    Line,
    Pie
  },

  props: ["userId"],

  data() {
    return {
      message: "",
      chartOptions: {
        responsive: true,
        maintainAspectRatio: false
      },
      barData: { labels: [], datasets: [] },
      lineData: { labels: [], datasets: [] },
      pieData: { labels: [], datasets: [] }
    }
  },

  watch: {
    userId() {
      this.message = ""
      this.resetCharts()
    }
  },

  methods: {
    resetCharts() {
      this.barData = { labels: [], datasets: [] }
      this.lineData = { labels: [], datasets: [] }
      this.pieData = { labels: [], datasets: [] }
    },

    getWorkingTimes() {
      if (!this.userId) {
        this.message = "Select a user first"
        return
      }

      axios
        .get(`/api/workingtime/${this.userId}`)
        .then((response) => {
          const workingTimes = response.data.data || []

          if (!workingTimes.length) {
            this.message = "No working times yet"
            this.resetCharts()
            return
          }

          const dates = workingTimes.map((item) =>
            new Date(item.start).toLocaleDateString()
          )

          const hours = workingTimes.map((item) => {
            const start = new Date(item.start)
            const end = new Date(item.end)
            return (end - start) / 3600000
          })

          this.message = ""

          this.barData = {
            labels: dates,
            datasets: [
              {
                label: "Hours Worked",
                data: hours,
                backgroundColor: "#4f8cff"
              }
            ]
          }

          this.lineData = {
            labels: dates,
            datasets: [
              {
                label: "Hours Worked",
                data: hours,
                borderColor: "#22c55e",
                backgroundColor: "#22c55e"
              }
            ]
          }

          this.pieData = {
            labels: workingTimes.map((_, index) => `Shift ${index + 1}`),
            datasets: [
              {
                data: hours,
                backgroundColor: ["#4f8cff", "#22c55e", "#f59e0b", "#ef4444"]
              }
            ]
          }
        })
        .catch((error) => {
          console.error(error)
          this.message = "Could not load charts"
        })
    }
  }
}
</script>

<style scoped>
.chart-grid {
  display: flex;
  gap: 20px;
  margin-top: 20px;
}

.chart {
  width: 350px;
  height: 320px;
  padding: 15px;
  border: 1px solid #ddd;
  border-radius: 10px;
}

.chart h3 {
  text-align: center;
  margin: 0 0 10px;
}

.chart-content {
  height: 250px;
}
</style>
