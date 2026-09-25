<template>
  <section>
    <h2>User</h2>

    <input v-model.number="userId" type="number" placeholder="User ID" />
    <input v-model="username" placeholder="Username" />
    <input v-model="email" placeholder="Email" />

    <button @click="getUser">Get User</button>
    <button class="create-button"  @click="createUser">Create User</button>
    <button @click="updateUser">Update User</button>
    <button class="delete-button" @click="deleteUser">Delete User</button>
  </section>
</template>

<script>
import axios from 'axios'

export default {
  name: "User",

  data() {
    return {
      userId: null,
      username: "",
      email: ""
    }
  },

  methods: {
    getUser() {
      axios
        .get(`http://localhost:4000/api/users/${this.userId}`)
        .then((response) => {
          this.username = response.data.data.username
          this.email = response.data.data.email
          this.$emit("userChanged", this.userId)
        })
        .catch((error) => {
          console.error(error)
        })
    },

    createUser() {
      axios
        .post("http://localhost:4000/api/users", {
          user: {
            username: this.username,
            email: this.email
          }
        })
        .then((response) => {
          this.userId = response.data.data.id
          this.$emit("userChanged", this.userId)
        })
        .catch((error) => {
          console.error(error)
        })
    },

    updateUser() {
      axios
        .put(`http://localhost:4000/api/users/${this.userId}`, {
          user: {
            username: this.username,
            email: this.email
          }
        })
        .then((response) => {
          this.username = response.data.data.username
          this.email = response.data.data.email
        })
        .catch((error) => {
          console.error(error)
        })
    },

    deleteUser() {
      axios
        .delete(`http://localhost:4000/api/users/${this.userId}`)
        .then(() => {
          this.userId = null
          this.username = ""
          this.email = ""
          this.$emit("userChanged", null)
        })
        .catch((error) => {
          console.error(error)
        })
    }
  }
}
</script>
