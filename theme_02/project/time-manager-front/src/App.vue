<template>
  <div id="app">
    <User />
    <hr /> <!-- ----------------------------------------------------- -->
    <!-- ----------------------------- -->
    <router-view />
  </div>
</template>

<script>
import User from './components/User.vue'
export default {
  name: 'App',
  components: {
    User
  }
}
</script>

<style>
body {
  font-family: sans-serif;
  margin: 10px;
}
</style>
