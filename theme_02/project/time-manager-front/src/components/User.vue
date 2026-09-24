<template>
  <div class="user-banner">
    <h1>Time Manager</h1>

    <!-- To see if a user is connected-->
    <p v-if="currentUser"> Connecté : {{ currentUser.username }} (Email: {{ currentUser.email }}) </p>
    <p v-else> Aucun utilisateur sélectionné </p>

    <!-- placeholder with v-model to get user id username and email -->
    <div>
      <input v-model="form.id" placeholder="ID (pour chercher/modifier)" />
      <input v-model="form.username" placeholder="Nom d'utilisateur" />
      <input v-model="form.email" placeholder="Email" />

      <!-- create button -->
      <button @click="createUser">Créer</button>
      <button @click="getUser">Chercher (ID)</button>
      <button @click="updateUser">Modifier (ID)</button>
      <button @click="deleteUser">Supprimer (ID)</button>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'User',
  data() {
    return {
      currentUser: null, // variable to contain actual user
      form: {
        id: '',
        username: '',
        email: ''
      }
    }
  },
  methods: {
/////////////// first method to create a user         CREATEUSER
    createUser() {
      const payload = { user: { username: this.form.username, email: this.form.email } }
      
      axios.post('http://localhost:4000/api/users', payload)
        .then(response => {
          this.currentUser = response.data.data
          alert("Utilisateur créé !")
        })
        .catch(error => alert("Erreur de création"))
    },

////////////// method to find a user                 GEATUSER
    getUser() {
      if (!this.form.id) return alert("Veuillez entrer un ID")
      
      axios.get(`http://localhost:4000/api/users/${this.form.id}`)
        .then(response => {
          this.currentUser = response.data.data
        })
        .catch(error => alert("Utilisateur introuvable"))
    },

///////////////  method to modify a user             UPDATEUSER
    updateUser() {
      if (!this.form.id) return alert("Veuillez entrer un ID")
      const payload = { user: { username: this.form.username, email: this.form.email } }

      axios.put(`http://localhost:4000/api/users/${this.form.id}`, payload)
        .then(response => {
          this.currentUser = response.data.data
          alert("Utilisateur modifié !")
        })
        .catch(error => alert("Erreur de modification"))
    },

    // 4. Supprimer un utilisateur[cite: 6]
    deleteUser() {
      if (!this.form.id) return alert("Veuillez entrer un ID")

      axios.delete(`http://localhost:4000/api/users/${this.form.id}`)
        .then(() => {
          this.currentUser = null // On vide l'affichage
          alert("Utilisateur supprimé !")
        })
        .catch(error => alert("Erreur de suppression"))
    }
  }
}
</script>

<style scoped>
.user-banner {
  background-color: #ff2323;
  padding: 15px;
  border-bottom: 2px solid #ccc;
}
input {
  margin-right: 5px;
}
button {
  margin-right: 5px;
  cursor: pointer;
}
</style>