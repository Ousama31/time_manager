<template>
  <div class="login-page auth-page">
    <AuthBrandPanel />

    <div class="login-content">
      <div class="desktop-top-action">
        <span>New to Time Manager?</span>
        <router-link to="/sign_up">Create account</router-link>
      </div>

      <header class="login-hero"><h1>Welcome back</h1><p>Enter your details to continue to your workspace.</p></header>

      <main class="login-card">
        <div class="desktop-heading">
          <h1>Welcome back</h1>
          <p>Enter your details to continue to your workspace.</p>
        </div>

        <div class="auth-tabs" aria-label="Account access">
          <router-link to="/login" class="tab active" aria-current="page">Sign in</router-link>
          <router-link to="/sign_up" class="tab">Sign up</router-link>
        </div>

        <form class="login-form" @submit.prevent="signIn">
          <div class="form-group">
            <label for="login-username">Username</label>
            <div class="input-shell">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M20 21a8 8 0 0 0-16 0M12 13a5 5 0 1 0 0-10 5 5 0 0 0 0 10Z" />
              </svg>
              <input
                id="login-username"
                v-model="username"
                type="text"
                placeholder="Username"
                autocomplete="username"
                required
              />
            </div>
          </div>

          <div class="form-group">
            <label for="login-password">Password</label>
            <div class="input-shell">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <rect x="4" y="10" width="16" height="11" rx="2" />
                <path d="M8 10V7a4 4 0 1 1 8 0v3" />
                <path d="M12 14v3" />
              </svg>
              <input
                id="login-password"
                v-model="password"
                type="password"
                placeholder="Enter your password"
                autocomplete="current-password"
                required
              />
            </div>
          </div>

          <div v-if="error" class="error-badge" role="alert">{{ error }}</div>
          <button type="submit" class="login-submit">Sign in to Time Manager</button>
        </form>
      </main>

      <p class="login-footer">Secure time management for modern teams</p>
    </div>
  </div>
</template>

<script>
import api from '../../api';
import AuthBrandPanel from './AuthBrandPanel.vue';
import { hashPassword } from '../../utils/password';

export default {
  name: 'SignIn',
  components: { AuthBrandPanel },
  data() {
    return {
      username: '',
      password: '',
      error: ''
    };
  },
  methods: {
    async signIn() {
      try {
        const response = await api.post('/users/sign_in', {
          username: this.username,
          password: await hashPassword(this.password)
        });

        const data = response.data.data || response.data;
        const token = data.xsrf_token || data.xsrfToken || data.token;
        const userId = data.user_id || data.userId || data.user?.id;
        const role = data.role || data.user?.role || 'employee';

        if (token) {
          sessionStorage.setItem('xsrfToken', token);
          sessionStorage.setItem('userId', userId);
          sessionStorage.setItem('role', role);
          localStorage.setItem('xsrfToken', token);
          localStorage.setItem('userId', userId);
          localStorage.setItem('role', role);
          this.$router.push('/');
        } else {
          this.error = 'Token missing in response';
        }
      } catch (err) {
        this.error = (err.name === 'PasswordHashingError' && err.message) || err.response?.data?.error ||
          (err.response
            ? 'Sign in failed. Check your username and password.'
            : `Cannot reach the server at ${api.defaults.baseURL}. Check the API address and network connection.`);
      }
    }
  }
};
</script>
