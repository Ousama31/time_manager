<template>
    <section>
      <h2>User</h2>
  
      <!-- User information form -->
      <input v-model="username" placeholder="Username" />
      <input v-model="email" placeholder="Email" />
  
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
    
          // Create a new user in the backend
        createUser() {
        axios
            // Send the user data to the Phoenix API
            .post("http://localhost:4000/api/users", {
            user: {
                username: this.username,
                email: this.email
            }
            })

            // Run if the user was created successfully
            .then((response) => {
            console.log(response.data)

            // Save the ID of the new user
            this.userId = response.data.data.id
            })

            // Run if there is an error
            .catch((error) => {
            console.error(error)
            })
        },
    
          // Update the current user in the backend
        updateUser() {
        axios
            // Send the updated username and email
            .put(`http://localhost:4000/api/users/${this.userId}`, {
            user: {
                username: this.username,
                email: this.email
            }
            })

            // Run if the update succeeds
            .then((response) => {
            console.log(response.data)

            // Update the displayed values
            this.username = response.data.data.username
            this.email = response.data.data.email
            })

            // Run if there is an error
            .catch((error) => {
            console.error(error)
            })
        },
  
          // Delete the current user from the backend
        deleteUser() {
        axios
            // Send a DELETE request using the current user ID
            .delete(`http://localhost:4000/api/users/${this.userId}`)

            // Run if the user was deleted successfully
            .then(() => {
            // Clear the user data from the page
            this.username = ""
            this.email = ""
            })

            // Run if there is an error
            .catch((error) => {
            console.error(error)
            })
        }
    }
  }
  </script>