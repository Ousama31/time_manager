<template>
  <div class="signup-page auth-page">
    <AuthBrandPanel />

    <div class="signup-content">
      <div class="desktop-top-action">
        <span>Already have an account?</span>
        <router-link to="/login">Login</router-link>
      </div>

      <header class="signup-hero"><h1>Create your account</h1><p>Enter your details to set up your workspace.</p></header>

      <main class="signup-card">
        <div class="desktop-heading">
          <h1>Create your account</h1>
          <p>Enter your details to set up your workspace.</p>
        </div>

        <div class="auth-tabs" aria-label="Account access">
          <router-link to="/login" class="tab">Login</router-link>
          <router-link to="/sign_up" class="tab active" aria-current="page">Sign up</router-link>
        </div>

        <form class="signup-form" @submit.prevent="signUp">
          <div class="form-group">
            <label for="signup-full-name">Full name</label>
            <div class="input-shell">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M20 21a8 8 0 0 0-16 0M12 13a5 5 0 1 0 0-10 5 5 0 0 0 0 10Z" />
              </svg>
              <input id="signup-full-name" v-model="full_name" type="text" placeholder="Your full name" autocomplete="name" required />
            </div>
          </div>

          <div class="form-group">
            <label for="signup-username">Username</label>
            <div class="input-shell">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M20 21a8 8 0 0 0-16 0M12 13a5 5 0 1 0 0-10 5 5 0 0 0 0 10Z" />
              </svg>
              <input id="signup-username" v-model="username" type="text" placeholder="Username" autocomplete="username" required />
            </div>
          </div>

          <div class="form-group">
            <label for="signup-email">Email address</label>
            <div class="input-shell">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <rect x="3" y="5" width="18" height="14" rx="2" />
                <path d="m4 7 8 6 8-6" />
              </svg>
              <input id="signup-email" v-model="email" type="email" placeholder="you@example.com" autocomplete="email" required />
            </div>
          </div>

          <div class="form-group">
            <label for="signup-password">Password</label>
            <div class="input-shell">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <rect x="4" y="10" width="16" height="11" rx="2" />
                <path d="M8 10V7a4 4 0 1 1 8 0v3M12 14v3" />
              </svg>
              <input id="signup-password" v-model="password" type="password" placeholder="Create a password" autocomplete="new-password" required />
            </div>
          </div>

          <div v-if="error" class="error-badge" role="alert">{{ error }}</div>
          <button type="submit" class="signup-submit">Create account</button>
        </form>
      </main>

      <p class="signup-footer">Secure time management for modern teams</p>
    </div>
  </div>
</template>

<script>
import api from '../../api';
import AuthBrandPanel from './AuthBrandPanel.vue';
import { hashPassword } from '../../utils/password';

export default {
  name: 'SignUp',
  components: { AuthBrandPanel },
  data() {
    return {
      username: '',
      full_name: '',
      email: '',
      password: '',
      error: ''
    };
  },
  methods: {
    async signUp() {
      try {
        await api.post('/users/sign_up', {
          user: {
            username: this.username,
            email: this.email,
            full_name: this.full_name,
            password: await hashPassword(this.password)
          }
        });
        this.$router.push('/login');
      } catch (err) {
        this.error = err.response?.data?.error ||
          (err.name === 'PasswordHashingError' ? err.message : 'Registration failed');
      }
    }
  }
};
</script>
