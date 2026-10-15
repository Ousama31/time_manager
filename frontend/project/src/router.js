import { createRouter, createWebHistory } from 'vue-router';

import Home from './components/employee/Home.vue';
import AdminDashboard from './components/admin/AdminDashboard.vue';
import ManagerDashboard from './components/manager/ManagerDashboard.vue';
import SignIn from './components/auth/SignIn.vue';
import SignUp from './components/auth/SignUp.vue';

const routes = [
  { path: '/', component: Home, meta: { requiresAuth: true } },
  { path: '/manager', component: ManagerDashboard, meta: { requiresAuth: true } },
  { path: '/admin', component: AdminDashboard, meta: { requiresAuth: true } },
  { path: '/login', component: SignIn },
  { path: '/sign_in', redirect: '/login' },
  { path: '/sign_up', component: SignUp }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

router.beforeEach((to, from, next) => {
  const token = sessionStorage.getItem('xsrfToken') || localStorage.getItem('xsrfToken')
  const role = sessionStorage.getItem('role') || localStorage.getItem('role') || 'employee'
  const roleHome = { employee: '/', manager: '/manager', admin: '/admin' }

  if (to.meta.requiresAuth && !token) {
    next('/login')
  } else if (to.meta.requiresAuth && to.path !== roleHome[role]) {
    next(roleHome[role] || '/')
  } else {
    next()
  }
});

export default router;
