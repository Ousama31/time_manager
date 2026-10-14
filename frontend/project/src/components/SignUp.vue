<template>
  <div class="signup-page">
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
import api from '../api';
import AuthBrandPanel from './AuthBrandPanel.vue';

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
            password: this.password
          }
        });
        this.$router.push('/login');
      } catch (err) {
        this.error = err.response?.data?.error || 'Registration failed';
      }
    }
  }
};
</script>

<style scoped>
.signup-page {
  --accent: #173f65;
  position: fixed;
  z-index: 20;
  inset: 0;
  height: 100vh;
  height: 100dvh;
  overflow-x: hidden;
  overflow-y: auto;
  background: var(--app-background);
  color: var(--app-text);
  font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  padding-left: env(safe-area-inset-left);
  padding-right: env(safe-area-inset-right);
  padding-bottom: env(safe-area-inset-bottom);
}

.signup-content {
  display: grid;
  min-height: 100dvh;
  grid-template-rows: minmax(130px, 22vh) 1fr auto;
}

.signup-hero {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  gap: 7px;
  overflow: hidden;
  box-sizing: border-box;
  width: 100%;
  height: auto;
  min-height: 0;
  padding: max(24px, env(safe-area-inset-top)) clamp(24px, 6vw, 64px) 20px;
  color: #fff;
  background: #102c4b;
}

.signup-hero h1 { margin: 0; color: #fff; font-size: clamp(25px, 6.8vw, 34px); font-weight: 740; letter-spacing: -.8px; line-height: 1.12; }
.signup-hero > p { max-width: 430px; margin: 6px 0 0; color: #c3d2e1; font-size: 12px; line-height: 1.45; }

.desktop-top-action,
.desktop-heading {
  display: none;
}

.signup-card {
  position: relative;
  align-self: center;
  width: min(528px, calc(100% - 48px));
  margin: 0 auto;
  padding: 36px;
  border-radius: 40px;
  border: 1px solid #e3ebe5;
  background: var(--app-surface);
  box-shadow: 0 18px 55px rgb(39 74 52 / 10%);
}

.auth-tabs {
  display: flex;
  gap: 6px;
  padding: 6px;
  border-radius: 21px;
  background: #f0f4f1;
}

.tab {
  display: grid;
  min-height: 70px;
  flex: 1;
  place-items: center;
  border-radius: 17px;
  color: #77847b;
  font-size: 22px;
  font-weight: 650;
  text-decoration: none;
}

.tab.active {
  background: #fff;
  box-shadow: 0 3px 14px rgb(39 74 52 / 9%);
  color: var(--accent);
}

.signup-form {
  display: grid;
  gap: 23px;
  margin-top: 34px;
}

.form-group {
  display: grid;
  gap: 12px;
}

.form-group label {
  color: #303a33;
  font-size: 20px;
  font-weight: 650;
}

.input-shell {
  display: flex;
  min-height: 78px;
  align-items: center;
  gap: 16px;
  padding: 0 22px;
  border: 1px solid #dce5de;
  border-radius: 21px;
  background: #fafcfb;
  transition: border-color 150ms ease, box-shadow 150ms ease;
}

.input-shell:focus-within {
  border-color: var(--accent);
  box-shadow: 0 0 0 4px rgb(23 63 101 / 12%);
}

.input-shell svg {
  width: 26px;
  height: 26px;
  flex: 0 0 26px;
  fill: none;
  stroke: #89958d;
  stroke-linecap: round;
  stroke-linejoin: round;
  stroke-width: 2;
}

.input-shell input {
  width: 100%;
  min-width: 0;
  margin: 0;
  padding: 0;
  border: 0;
  outline: 0;
  background: transparent;
  box-shadow: none;
  color: #263129;
  font: inherit;
  font-size: 21px;
}

.input-shell input:focus {
  border: 0;
  outline: 0;
}

.input-shell input::placeholder {
  color: #89958d;
  opacity: 1;
}

.signup-submit {
  min-height: 84px;
  margin: 0;
  border: 0;
  border-radius: 23px;
  background: linear-gradient(100deg, #173f65, #285b86);
  box-shadow: 0 14px 30px rgb(23 63 101 / 18%);
  color: #fff;
  font-size: 22px;
  font-weight: 700;
}

.signup-submit:hover {
  background: linear-gradient(100deg, #123553, #214b70);
  opacity: 1;
}

.error-badge {
  margin-top: -8px;
  color: #b8443f;
  font-size: 15px;
}

.signup-footer {
  margin: 32px 20px max(28px, env(safe-area-inset-bottom));
  color: #78857c;
  font-size: 18px;
  text-align: center;
}

@media (max-width: 480px) {
  .signup-hero {
    height: auto;
    min-height: 0;
    max-height: none;
    padding: max(20px, env(safe-area-inset-top)) 24px 18px;
  }

  .signup-card {
    width: calc(100% - 28px);
    margin-top: 0;
    padding: 16px 18px 18px;
    border-radius: 32px;
    border-color: #e7eaf0;
    box-shadow: 0 18px 48px rgb(16 44 75 / 11%);
  }

  .tab {
    min-height: 48px;
    font-size: 18px;
  }

  .signup-form {
    gap: 12px;
    margin-top: 16px;
  }

  .form-group label {
    font-size: 16px;
  }

  .form-group {
    gap: 6px;
  }

  .input-shell {
    min-height: 50px;
    gap: 11px;
    padding: 0 14px;
    border-radius: 16px;
  }

  .input-shell input {
    font-size: 15px;
  }

  .signup-submit {
    min-height: 54px;
    border-radius: 17px;
    font-size: 17px;
  }

  .signup-footer {
    margin-top: 10px;
    font-size: 12px;
  }
}

@media (min-width: 960px) {
  .signup-page {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    overflow: hidden;
    background: var(--app-background);
  }

  .signup-content {
    grid-column: 2;
    grid-row: 1;
    position: relative;
    display: flex;
    height: 100vh;
    height: 100dvh;
    min-height: 0;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    padding: 100px clamp(24px, 2.4vw, 44px) 32px;
  }

  .desktop-top-action {
    position: absolute;
    top: 42px;
    right: clamp(24px, 2.4vw, 44px);
    display: flex;
    align-items: center;
    gap: 16px;
    color: #738078;
    font-size: 17px;
  }

  .desktop-top-action a {
    padding: 12px 20px;
    border: 1px solid var(--accent);
    border-radius: 13px;
    color: #fff;
    background: var(--accent);
    font-weight: 650;
    text-decoration: none;
    transition: background-color 150ms ease, border-color 150ms ease;
  }

  .desktop-top-action a:hover {
    border-color: #102f4b;
    background: #102f4b;
  }

  .desktop-heading {
    display: block;
    width: 100%;
    margin-bottom: 28px;
  }

  .desktop-heading h1 {
    margin: 0 0 18px;
    color: #202923;
    font-size: clamp(38px, 4vw, 58px);
    letter-spacing: -1.7px;
  }

  .desktop-heading p {
    margin: 0;
    color: #768279;
    font-size: 21px;
    line-height: 1.55;
  }

  .signup-hero {
    display: none;
  }

  .desktop-top-action { display: none; }

  .signup-card {
    box-sizing: border-box;
    width: min(100%, 520px);
    margin: 0;
    padding: clamp(28px, 3vw, 46px);
    border: 1px solid #e3ebe5;
    border-radius: 28px;
    background: var(--app-surface);
    box-shadow: 0 24px 70px rgb(39 74 52 / 10%), 0 0 45px rgb(33 135 90 / 7%);
  }

  .signup-form {
    gap: 18px;
    margin-top: 22px;
  }

  .form-group {
    gap: 10px;
  }

  .form-group label {
    font-size: 17px;
  }

  .input-shell {
    min-height: 65px;
    border-radius: 15px;
  }

  .input-shell input {
    font-size: 18px;
  }

  .signup-submit {
    min-height: 72px;
    border-radius: 17px;
    font-size: 20px;
  }
}

@media (min-width: 960px) and (max-height: 850px) {
  .signup-content {
    padding-top: 78px;
    padding-bottom: 18px;
  }

  .signup-card {
    padding: 20px;
  }

  .desktop-heading {
    margin-bottom: 14px;
  }

  .desktop-heading h1 {
    margin-bottom: 8px;
    font-size: clamp(30px, 3.1vw, 40px);
  }

  .desktop-heading p {
    font-size: 15px;
  }

  .signup-form {
    gap: 10px;
  }

  .form-group {
    gap: 6px;
  }

  .form-group label {
    font-size: 14px;
  }

  .input-shell {
    min-height: 52px;
  }

  .signup-submit {
    min-height: 56px;
  }
}

@media (min-width: 960px) and (max-height: 650px) {
  .signup-content {
    padding: 54px 26px 10px;
  }

  .signup-card {
    padding: 14px 18px;
  }

  .desktop-heading h1 {
    font-size: 28px;
  }

  .desktop-heading p {
    font-size: 14px;
  }

  .form-group label {
    font-size: 13px;
  }

  .input-shell {
    min-height: 45px;
  }

  .signup-submit {
    min-height: 48px;
    font-size: 17px;
  }
}

@media (max-height: 620px) and (max-width: 480px) {
  .signup-hero {
    height: 17vh;
    min-height: 82px;
  }

  .signup-card {
    padding-top: 12px;
    padding-bottom: 12px;
  }

  .signup-form {
    gap: 8px;
    margin-top: 10px;
  }

  .form-group label {
    font-size: 14px;
  }

  .input-shell {
    min-height: 42px;
  }

  .signup-submit {
    min-height: 46px;
  }

  .signup-footer {
    margin-top: 6px;
  }
}

</style>
