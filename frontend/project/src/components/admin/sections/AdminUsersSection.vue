<template>
        <section class="users-panel dashboard-surface" aria-labelledby="users-heading">
          <div class="panel-heading">
            <div><h2 id="users-heading">All users <span class="count-pill">{{ filteredUsers.length }}</span></h2><p>View and manage your workspace members.</p></div>
          </div>
          <div class="table-toolbar">
            <label class="search-box"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="10.8" cy="10.8" r="6.8"/><path d="m16 16 4.5 4.5"/></svg><input :value="searchQuery" @input="emitModel('searchQuery', $event.target.value)" type="search" placeholder="Search by name or email…" aria-label="Search users" /></label>
            <label class="filter-select"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 6h16M7 12h10m-7 6h4"/></svg><select :value="statusFilter" @change="emitModel('statusFilter', $event.target.value)" aria-label="Filter by status"><option value="All">All statuses</option><option value="Active">Active</option><option value="Inactive">Inactive</option></select><svg class="select-chevron" viewBox="0 0 24 24" aria-hidden="true"><path d="m7 10 5 5 5-5"/></svg></label>
            <button class="filter-role" :class="{ selected: roleFilter !== 'All' }" @click="emitModel('roleFilter', roleFilter === 'All' ? 'Manager' : roleFilter === 'Manager' ? 'Employee' : 'All')"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 6h16M7 12h10m-7 6h4"/></svg><span>{{ roleFilter === 'All' ? 'All roles' : roleFilter }}</span><svg class="select-chevron" viewBox="0 0 24 24" aria-hidden="true"><path d="m7 10 5 5 5-5"/></svg></button>
          </div>

          <div class="table-scroll">
            <table class="users-table">
              <thead><tr><th scope="col" class="user-column">USER <button aria-label="Sort users">↕</button></th><th scope="col">ROLE</th><th scope="col">STATUS</th><th scope="col">JOINED DATE <button aria-label="Sort by joined date">↕</button></th><th scope="col" class="actions-heading">ACTION</th></tr></thead>
              <tbody>
                <tr v-for="user in filteredUsers" :key="user.email">
                  <td class="user-cell"><button type="button" class="user-stats-trigger" :aria-label="`View statistics for ${user.name}`" @click="openStatistics(user)"><InitialAvatar :tone="user.avatarTone" :initials="user.initials" /><span class="user-identity"><strong>{{ user.name }}</strong><small>{{ user.email }}</small></span></button></td>
                  <td data-label="Role"><span class="role-badge" :class="roleClass(user.role)"><svg v-if="user.role === 'Admin'" viewBox="0 0 24 24" aria-hidden="true"><path d="m5 18 1.2-8 4.1 3.4L12 6l1.7 7.4 4.1-3.4L19 18H5ZM5 21h14"/></svg><svg v-else-if="user.role === 'Manager'" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3.5 19 6v5.5c0 4.2-2.9 7.5-7 9-4.1-1.5-7-4.8-7-9V6l7-2.5Z"/><path d="m9 12 2 2 4-4"/></svg><svg v-else viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="3.5"/><path d="M5 20a7 7 0 0 1 14 0"/></svg>{{ user.role }}</span></td>
                  <td data-label="Status"><span class="status-badge" :class="user.status === 'Active' ? 'status-active' : 'status-inactive'"><i></i>{{ user.status }}</span></td>
                  <td class="joined-cell" data-label="Joined">{{ user.joined }}</td>
                  <td class="action-cell" data-label="Actions"><div class="action-buttons"><button class="manage-button" :disabled="user.actionBusy" @click="openRoleEditor(user)">Edit role</button><button class="user-action-button" :class="user.status === 'Active' ? 'suspend-button' : 'activate-button'" :disabled="user.actionBusy || isCurrentUser(user)" :title="isCurrentUser(user) ? 'You cannot change your own administrator account status' : user.status === 'Active' ? 'Suspend this account' : 'Activate this account'" @click="toggleUserStatus(user)">{{ user.actionBusy ? 'Saving…' : user.status === 'Active' ? 'Suspend' : 'Activate' }}</button><button class="user-action-button delete-button" :disabled="user.actionBusy || isCurrentUser(user)" :title="isCurrentUser(user) ? 'You cannot delete your own administrator account' : 'Delete this account'" @click="deleteUser(user)">{{ user.actionBusy ? 'Saving…' : 'Delete' }}</button></div></td>
                </tr>
                <tr v-if="loadingUsers"><td colspan="5" class="empty-row">Loading users…</td></tr>
                <tr v-else-if="filteredUsers.length === 0"><td colspan="5" class="empty-row">{{ searchQuery || statusFilter !== 'All' || roleFilter !== 'All' ? 'No users match your filters.' : 'No users to display yet.' }}</td></tr>
              </tbody>
            </table>
          </div>
        </section>
</template>

<script>
import InitialAvatar from '../../shared/InitialAvatar.vue'
export default {
  name: 'AdminUsersSection',
  components: { InitialAvatar },
  props: {
    filteredUsers: { type: Array, required: true },
    loadingUsers: { type: Boolean, required: true },
    searchQuery: { type: String, required: true },
    statusFilter: { type: String, required: true },
    roleFilter: { type: String, required: true },
    userId: { type: [String, Number], default: '' }
  },
  methods: {
    emitModel(name, value) { this.$emit(`update:${name}`, value) },
    openStatistics(user) { this.$emit('open-statistics', user) },
    openRoleEditor(user) { this.$emit('open-role-editor', user) },
    toggleUserStatus(user) { this.$emit('toggle-user-status', user) },
    deleteUser(user) { this.$emit('delete-user', user) },
    isCurrentUser(user) { return String(user.id) === String(this.userId) },
    roleClass(role) { return { Admin: 'role-admin', Manager: 'role-manager', Employee: 'role-member' }[role] || 'role-member' }
  }
}
</script>

<style>
.admin-dashboard .users-panel { overflow: hidden; border: 1px solid #e6eaf0; border-radius: 11px; background: #fff; box-shadow: 0 3px 12px rgb(22 34 52 / 3%); }
.admin-dashboard .panel-heading { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 19px 20px 15px; }
.admin-dashboard .panel-heading h2 { display: flex; align-items: center; gap: 8px; margin: 0; color: #273243; font-size: 14px; font-weight: 700; }
.admin-dashboard .panel-heading p { margin: 5px 0 0; color: #8a95a4; font-size: 10px; }
.admin-dashboard .table-toolbar { display: flex; align-items: center; gap: 8px; padding: 0 20px 13px; }
.admin-dashboard .search-box, .admin-dashboard .filter-select, .admin-dashboard .filter-role { display: flex; min-height: 33px; align-items: center; gap: 8px; border: 1px solid #e4e8ee; border-radius: 7px; color: #7b8798; background: #fff; }
.admin-dashboard .search-box { width: min(100%, 290px); padding: 0 9px; }
.admin-dashboard .search-box:focus-within { border-color: #8992e7; box-shadow: 0 0 0 3px rgb(70 87 216 / 9%); }
.admin-dashboard .search-box svg, .admin-dashboard .filter-select > svg:first-child, .admin-dashboard .filter-role > svg:first-child { width: 15px; flex: 0 0 15px; fill: none; stroke: #929cad; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.7; }
.admin-dashboard .search-box input { width: 100%; min-width: 0; border: 0; outline: 0; color: #354153; background: transparent; font: inherit; font-size: 10px; }
.admin-dashboard .search-box input::placeholder { color: #a1a9b5; }
.admin-dashboard .filter-select, .admin-dashboard .filter-role { position: relative; min-width: 120px; padding: 0 9px; }
.admin-dashboard .filter-select select { width: 100%; appearance: none; border: 0; outline: 0; color: #566274; background: transparent; font: inherit; font-size: 10px; cursor: pointer; }
.admin-dashboard .select-chevron { width: 13px; flex: 0 0 13px; fill: none; stroke: #959eac; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.8; pointer-events: none; }
.admin-dashboard .filter-role { min-width: 103px; justify-content: space-between; font: inherit; font-size: 10px; cursor: pointer; transition: background .16s ease; }
.admin-dashboard .filter-role:hover, .admin-dashboard .filter-role.selected { background: #f8f9ff; }
.admin-dashboard .table-scroll { width: 100%; overflow-x: auto; }
.admin-dashboard .users-table { width: 100%; border-collapse: collapse; text-align: left; white-space: nowrap; }
.admin-dashboard .users-table thead { background: #fafbfc; }
.admin-dashboard .users-table th { height: 34px; padding: 0 13px; border-top: 1px solid #eef0f4; border-bottom: 1px solid #eef0f4; color: #8994a3; font-size: 8px; font-weight: 750; letter-spacing: .75px; }
.admin-dashboard .users-table th:first-child, .admin-dashboard .users-table td:first-child { padding-left: 20px; }
.admin-dashboard .users-table th button { margin-left: 4px; border: 0; color: #a9b0bd; background: none; font: inherit; cursor: pointer; }
.admin-dashboard .user-column { width: 39%; }
.admin-dashboard .users-table td { height: 58px; padding: 0 13px; border-bottom: 1px solid #eff1f5; color: #556172; font-size: 10px; }
.admin-dashboard .users-table tbody tr:last-child td { border-bottom: 0; }
.admin-dashboard .users-table tbody tr { transition: background .14s ease; }
.admin-dashboard .users-table tbody tr:hover { background: #fbfcfe; }
.admin-dashboard .user-cell { display: flex; align-items: center; gap: 10px; }
.admin-dashboard .joined-cell { color: #697587 !important; }
.admin-dashboard .actions-heading { width: 235px; text-align: right; padding-right: 20px !important; }
.admin-dashboard .action-cell { padding-right: 20px !important; }
.admin-dashboard .action-buttons { display: flex; align-items: center; justify-content: flex-end; gap: 5px; }
.admin-dashboard .manage-button { min-height: 27px; padding: 0 9px; border: 1px solid #e1e5ec; border-radius: 6px; color: #4e5a6b; background: #fff; font: inherit; font-size: 9px; font-weight: 620; cursor: pointer; transition: color .15s ease, border .15s ease, background .15s ease; }
.admin-dashboard .manage-button:hover, .admin-dashboard .manage-button:focus-visible { border-color: #c9cef4; color: #4657d8; background: #f8f8ff; outline: none; }
.admin-dashboard .user-action-button { min-height: 27px; padding: 0 8px; border: 1px solid transparent; border-radius: 6px; font: inherit; font-size: 9px; font-weight: 680; cursor: pointer; transition: background .15s ease, border .15s ease, opacity .15s ease; }
.admin-dashboard .user-action-button:disabled, .admin-dashboard .manage-button:disabled { cursor: not-allowed; opacity: .52; }
.admin-dashboard .delete-button { border-color: #f3c9c8; color: #b42323; background: #fff1f0; }
.admin-dashboard .delete-button:hover:not(:disabled) { border-color: #e7aaa8; background: #ffe2df; }
.admin-dashboard .empty-row { height: 90px !important; color: #8994a3 !important; text-align: center; }
.admin-dashboard .panel-heading { padding: 20px 20px 16px; }
.admin-dashboard .panel-heading h2 { color: var(--app-text); font-size: 16px; }
.admin-dashboard .panel-heading p, .admin-dashboard .teams-heading p:last-child { color: var(--app-muted); font-size: 12px; }
.admin-dashboard .table-toolbar { padding-bottom: 15px; }
.admin-dashboard .search-box, .admin-dashboard .filter-select, .admin-dashboard .filter-role { min-height: 38px; border-color: var(--app-border); border-radius: 8px; }
.admin-dashboard .search-box input, .admin-dashboard .filter-select select, .admin-dashboard .filter-role { font-size: 12px; }
.admin-dashboard .search-box:focus-within { border-color: var(--app-accent); box-shadow: 0 0 0 3px rgb(22 132 248 / 12%); }
.admin-dashboard .filter-role:hover, .admin-dashboard .filter-role.selected { background: var(--app-accent-soft); }
.admin-dashboard .users-table thead { background: #f7f9f8; }
.admin-dashboard .users-table th { height: 40px; border-color: var(--app-border); font-size: 10px; }
.admin-dashboard .users-table td { height: 64px; font-size: 12px; }
.admin-dashboard .manage-button, .admin-dashboard .user-action-button { min-height: 32px; font-size: 10px; }
  .admin-dashboard .users-table th, .admin-dashboard .users-table td { padding-right: 9px; padding-left: 9px; }
  .admin-dashboard .users-table th:first-child, .admin-dashboard .users-table td:first-child { padding-left: 14px; }
  .admin-dashboard .actions-heading, .admin-dashboard .action-cell { padding-right: 14px !important; }
  .admin-dashboard .table-toolbar { flex-wrap: wrap; padding-right: 13px; padding-left: 13px; }
  .admin-dashboard .search-box { flex: 1 1 100%; width: 100%; }
  .admin-dashboard .panel-heading { padding-right: 13px; padding-left: 13px; }
  .admin-dashboard .table-scroll { overflow: visible; padding: 0 10px 10px; }
  .admin-dashboard .users-table { display: block; width: 100%; min-width: 0; white-space: normal; }
  .admin-dashboard .users-table thead { display: none; }
  .admin-dashboard .users-table tbody { display: grid; gap: 8px; }
  .admin-dashboard .users-table tbody tr {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    row-gap: 3px;
    column-gap: 12px;
    padding: 10px 14px;
    border: 1px solid var(--app-border);
    border-radius: 11px;
    background: var(--app-surface);
    box-shadow: 0 1px 4px rgb(27 41 61 / 3%);
  }
  .admin-dashboard .users-table tbody tr:hover { background: var(--app-surface); }
  .admin-dashboard .users-table td {
    display: block !important;
    height: auto !important;
    min-height: 0 !important;
    padding: 0 !important;
    margin: 0 !important;
    border: 0 !important;
    font-size: 11px;
  }
  .admin-dashboard .users-table td:first-child { grid-column: 1; grid-row: 1; min-width: 0; align-self: center; }
  .admin-dashboard .users-table td:nth-child(3) { grid-column: 2; grid-row: 1; justify-self: end; align-self: center; }
  .admin-dashboard .users-table td:nth-child(3)::before { display: none; }
  .admin-dashboard .users-table .joined-cell { grid-column: 1; grid-row: 2; font-size: 11px; color: var(--app-muted); line-height: 1.2; margin: 2px 0 0 !important; }
  .admin-dashboard .users-table .joined-cell::before { content: 'Joined '; color: var(--app-muted); font-size: 11px; }
  .admin-dashboard .users-table td:nth-child(2) { grid-column: 1; grid-row: 3; justify-self: start; align-self: center; margin: 2px 0 0 !important; }
  .admin-dashboard .users-table td:nth-child(2)::before { display: none; }
  .admin-dashboard .users-table .action-cell { grid-column: 2; grid-row: 2 / span 2; justify-self: end; align-self: center; padding: 0 !important; }
  .admin-dashboard .action-buttons { display: flex; align-items: center; gap: 5px; }
  .admin-dashboard .manage-button, .admin-dashboard .user-action-button { min-width: 0; min-height: 28px !important; padding: 0 8px !important; border-radius: 6px; font-size: 11px; }
  .admin-dashboard .users-table tbody tr:has(.empty-row) { display: block; }
  .admin-dashboard .users-table .empty-row { display: block; padding: 22px 8px !important; }
  .admin-dashboard .filter-select, .admin-dashboard .filter-role { flex: 1; min-width: 0; }
  .admin-dashboard .panel-heading h2 { font-size: 13px; }
.admin-dashboard .panel-heading { padding-top: 21px; }
.admin-dashboard .panel-heading h2 { font-size: 16px; }
.admin-dashboard .panel-heading p { font-size: 12px; }
.admin-dashboard .search-box, .admin-dashboard .filter-select, .admin-dashboard .filter-role { min-height: 42px; border-radius: 10px; }
.admin-dashboard .search-box input, .admin-dashboard .filter-select select, .admin-dashboard .filter-role { font-size: 12px; }
.admin-dashboard .users-table th { height: 42px; font-size: 10px; }
.admin-dashboard .users-table td { height: 64px; font-size: 12px; }
.admin-dashboard .manage-button, .admin-dashboard .user-action-button { min-height: 35px; padding-inline: 10px; border-radius: 9px; font-size: 11px; }
.admin-dashboard .users-panel { border: 1px solid var(--app-border); border-radius: var(--app-radius-panel); background: var(--app-surface); box-shadow: var(--app-shadow-panel); }
.admin-dashboard .panel-heading { padding: 18px 20px 8px; }
.admin-dashboard .panel-heading h2 { color: var(--app-text); font-size: 16px; }
.admin-dashboard .panel-heading p { color: var(--app-muted); font-size: 12px; }
.admin-dashboard .table-toolbar { flex-wrap: wrap; gap: 8px; padding: 8px 20px 16px; border-bottom: 1px solid var(--app-border); }
.admin-dashboard .search-box, .admin-dashboard .filter-select, .admin-dashboard .filter-role { min-height: 38px; border-color: var(--app-border); border-radius: 9px; background: var(--app-surface); }
.admin-dashboard .users-table thead { background: var(--app-background); }
.admin-dashboard .users-table th { height: 42px; border-color: var(--app-border); color: var(--app-muted); font-size: 10px; }
.admin-dashboard .users-table td { height: 64px; border-color: var(--app-border); color: var(--app-text); font-size: 12px; }
.admin-dashboard .users-table tbody tr:hover { background: #f8fbff; }
.admin-dashboard .user-column { width: 34%; }
.admin-dashboard .action-buttons { display: flex; align-items: center; gap: 6px; }
.admin-dashboard .manage-button, .admin-dashboard .user-action-button { min-height: 34px; padding-inline: 10px; border-radius: 9px; font-size: 10px; }
  .admin-dashboard .panel-heading { padding: 16px 14px 8px; }
  .admin-dashboard .table-toolbar { padding: 8px 14px 14px; }
  .admin-dashboard .users-panel { border-radius: 17px; }
  .admin-dashboard .users-table tbody tr { gap: 6px 10px; padding: 10px 14px; border-radius: 10px; box-shadow: 0 2px 8px rgb(27 41 61 / 3%); }
  .admin-dashboard .users-table td { font-size: 11px; }
  .admin-dashboard .action-buttons { gap: 5px; }
  .admin-dashboard .manage-button, .admin-dashboard .user-action-button { min-height: 28px; font-size: 10.5px; }
  .admin-dashboard .search-box, .admin-dashboard .filter-select, .admin-dashboard .filter-role { min-height: 43px; }
.admin-dashboard .panel-heading { padding: 21px 22px 10px; }
.admin-dashboard .panel-heading h2 { font-size: 19px; }
.admin-dashboard .panel-heading p { font-size: 14px; }
.admin-dashboard .table-toolbar { gap: 10px; padding: 10px 22px 18px; }
.admin-dashboard .search-box, .admin-dashboard .filter-select, .admin-dashboard .filter-role { min-height: 46px; gap: 10px; padding-inline: 12px; }
.admin-dashboard .search-box input, .admin-dashboard .filter-select select, .admin-dashboard .filter-role { font-size: 14px; }
.admin-dashboard .search-box svg, .admin-dashboard .filter-select > svg:first-child, .admin-dashboard .filter-role > svg:first-child { width: 18px; flex-basis: 18px; }
  .admin-dashboard .users-table th { height: 48px; font-size: 12px; }
  .admin-dashboard .users-table td { height: 74px; font-size: 14px; }
  .admin-dashboard .manage-button, .admin-dashboard .user-action-button { min-height: 40px; padding-inline: 12px; font-size: 12px; }
  .admin-dashboard .panel-heading { padding: 17px 15px 9px; }
  .admin-dashboard .table-toolbar { padding: 9px 15px 16px; }
  .admin-dashboard .action-buttons { gap: 6px; }
  .admin-dashboard .manage-button, .admin-dashboard .user-action-button { padding-inline: 7px; font-size: 11px; }
</style>
