<template>
    <section>
      <h2>User</h2>
  
      <!-- User information -->
      <p>Username: {{ username }}</p>
      <p>Email: {{ email }}</p>
  
      <!-- User actions -->
      <button @click="getUser">Get User</button>
      <button @click="createUser">Create User</button>
      <button @click="updateUser">Update User</button>
      <button @click="deleteUser">Delete User</button>
    </section>
  </template>
  
  <script>
  // Import Axios
  import axios from 'axios'
  
  export default {
    name: "User",
  
    // User data
    data() {
      return {
        userId: 1,
        username: "",
        email: ""
      }
    },
  
    methods: {
      // Get one user from the backend
      getUser() {
        axios
          .get(`http://localhost:4000/api/users/${this.userId}`)
          .then((response) => {
            this.username = response.data.data.username
            this.email = response.data.data.email
          })
          .catch((error) => {
            console.error(error)
          })
      },
  
      // Create user
      createUser() {
        console.log("Create user")
      },
  
      // Update user
      updateUser() {
        console.log("Update user")
      },
  
      // Delete user
      deleteUser() {
        console.log("Delete user")
      }
    }
  }
  </script>