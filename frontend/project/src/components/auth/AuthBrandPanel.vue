<template>
  <aside class="auth-brand" aria-label="Time Manager">
    <div class="brand-lockup">
      <div class="brand-icon" aria-hidden="true">
        <svg viewBox="0 0 48 48" fill="none">
          <circle cx="24" cy="24" r="16" />
          <path d="M24 14v11l8 5" />
        </svg>
      </div>
      <span>Time Manager</span>
    </div>

    <div class="brand-message">
      <h2>Built for teams that <span>set the new standard</span></h2>
      <p>One focused workspace for time tracking, team visibility, and effortless attendance management.</p>
    </div>
  </aside>
</template>

<style scoped>
.auth-brand {
  position: relative;
  display: none;
  box-sizing: border-box;
  height: 100vh;
  height: 100dvh;
  min-height: 0;
  flex-direction: column;
  overflow: hidden;
  padding: clamp(42px, 6vw, 88px) clamp(38px, 6.2vw, 100px);
  color: #fff;
  background: #102c4b;
}

.auth-brand::before,
.auth-brand::after {
  display: none;
}

.brand-lockup,
.brand-message,
.brand-trust {
  position: relative;
  z-index: 1;
}

.brand-lockup {
  display: flex;
  align-items: center;
  gap: 20px;
  font-size: clamp(24px, 2.2vw, 36px);
  font-weight: 750;
  letter-spacing: -0.8px;
}

.brand-icon {
  display: grid;
  width: 76px;
  height: 76px;
  flex: 0 0 76px;
  place-items: center;
  border-radius: 22px;
  border: 1px solid rgb(147 199 255 / 22%);
  background: #17416a;
  box-shadow: 0 12px 28px rgb(0 0 0 / 12%);
}

.brand-icon svg {
  width: 42px;
  stroke: #a5d2ff;
  stroke-linecap: round;
  stroke-linejoin: round;
  stroke-width: 3;
}

.brand-message {
  width: min(100%, 760px);
  margin-block: auto;
}

.brand-message h2 {
  max-width: 18ch;
  margin: 30px 0 24px;
  color: #fff;
  font-size: clamp(50px, 5vw, 82px);
  font-weight: 760;
  letter-spacing: -0.055em;
  line-height: 1.04;
  text-wrap: balance;
}

.brand-message h2 span {
  color: #9bcfff;
}

.brand-message p {
  max-width: 500px;
  margin: 0;
  color: #c3d2e1;
  font-size: clamp(17px, 1.45vw, 22px);
  line-height: 1.65;
}

@media (min-width: 960px) {
  .auth-brand {
    display: flex;
    grid-column: 1;
    grid-row: 1;
  }
}

@media (min-width: 960px) and (max-height: 850px) {
  .auth-brand {
    padding: 30px clamp(32px, 4.5vw, 64px);
  }

  .brand-lockup {
    gap: 14px;
    font-size: 27px;
  }

  .brand-icon {
    width: 58px;
    height: 58px;
    flex-basis: 58px;
    border-radius: 17px;
  }

  .brand-icon svg {
    width: 32px;
  }

  .brand-message {
    margin-block: auto;
  }

  .brand-message h2 {
    max-width: 17ch;
    margin: 22px 0 14px;
    font-size: clamp(40px, 4.1vw, 62px);
  }

  .brand-message p {
    max-width: 430px;
    font-size: 16px;
    line-height: 1.55;
  }

}

@media (min-width: 960px) and (max-height: 650px) {
  .auth-brand {
    padding: 20px 32px;
  }

  .brand-lockup {
    font-size: 24px;
  }

  .brand-icon {
    width: 48px;
    height: 48px;
    flex-basis: 48px;
  }

  .brand-icon svg {
    width: 28px;
  }

  .brand-message {
    margin: 14px 0;
  }

  .brand-message h2 {
    margin: 16px 0 10px;
    font-size: clamp(32px, 3.4vw, 44px);
  }

  .brand-message p {
    font-size: 14px;
    line-height: 1.4;
  }

}
</style>
