<template>
    <div v-if="editingUser" class="drawer-backdrop" @click.self="close" @keydown.esc="close">
        <aside class="role-drawer" role="dialog" aria-modal="true" aria-labelledby="drawer-title">
          <header class="drawer-header"><div><p class="drawer-eyebrow">TEAM ACCESS</p><h2 id="drawer-title">Edit user role</h2><p>Update this member’s workspace permissions.</p></div><button class="drawer-close" aria-label="Close role editor" @click="close"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18"/></svg></button></header>
          <div class="drawer-body">
            <section class="drawer-user-summary"><InitialAvatar variant="drawer-avatar" :tone="editingUser.avatarTone" :initials="editingUser.initials" /><span><strong>{{ editingUser.name }}</strong><small>{{ editingUser.email }}</small></span><span class="role-badge" :class="roleClass(editingUser.role)">{{ editingUser.role }}</span></section>
            <fieldset class="role-fieldset"><legend>Choose a role</legend><p class="field-hint">Roles determine what this person can see and manage.</p>
              <label v-for="role in roleOptions" :key="role.name" class="role-option" :class="{ 'role-option-selected': selectedRole === role.name }"><input :checked="selectedRole === role.name" @change="emitModel('selectedRole', role.name)" type="radio" :value="role.name" /><span class="role-option-icon" :class="role.iconTone"><svg v-if="role.name === 'Admin'" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3.5 19 6v5.5c0 4.2-2.9 7.5-7 9-4.1-1.5-7-4.8-7-9V6l7-2.5Z"/><path d="m9 12 2 2 4-4"/></svg><svg v-else-if="role.name === 'Manager'" viewBox="0 0 24 24" aria-hidden="true"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 19a5.5 5.5 0 0 1 11 0M16 5.5a3.2 3.2 0 0 1 0 6.2M17 14a5 5 0 0 1 3.5 4.8"/></svg><svg v-else viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="3.5"/><path d="M5 20a7 7 0 0 1 14 0"/></svg></span><span class="role-option-copy"><strong>{{ role.name }}</strong><small>{{ role.description }}</small></span><span class="custom-radio"></span></label>
            </fieldset>
            <div class="privilege-note" :class="{ 'privilege-note-admin': selectedRole === 'Admin', 'privilege-note-manager': selectedRole === 'Manager' }"><span class="privilege-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3.5 19 6v5.5c0 4.2-2.9 7.5-7 9-4.1-1.5-7-4.8-7-9V6l7-2.5Z"/><path d="m9 12 2 2 4-4"/></svg></span><span><strong>{{ selectedRole === 'Admin' ? 'Full workspace access' : selectedRole === 'Manager' ? 'Team management access' : 'Standard member access' }}</strong><small>{{ selectedRole === 'Admin' ? 'Admins can manage roles, teams, schedules, and workspace settings.' : selectedRole === 'Manager' ? 'Managers can manage their team and view team time records.' : 'Members can track their own time and update their profile.' }}</small></span></div>
            <label class="confirm-toggle"><input :checked="confirmRoleChange" @change="emitModel('confirmRoleChange', $event.target.checked)" type="checkbox" /><span class="toggle-track"><i></i></span><span>I understand this role changes the user’s access.</span></label>
          </div>
          <footer class="drawer-footer"><button class="cancel-button" @click="close">Cancel</button><button class="save-role-button" :disabled="!confirmRoleChange || savingRole" @click="save"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m5 12 4.2 4.2L19 6.5"/></svg>{{ savingRole ? 'Saving…' : 'Save role changes' }}</button></footer>
        </aside>
      </div>
</template>

<script>
import InitialAvatar from '../../shared/InitialAvatar.vue'
export default {
  name: 'AdminRoleEditorDrawer',
  components: { InitialAvatar },
  props: {
    editingUser: { type: Object, default: null },
    selectedRole: { type: String, required: true },
    confirmRoleChange: { type: Boolean, required: true },
    savingRole: { type: Boolean, required: true },
    roleOptions: { type: Array, required: true }
  },
  methods: {
    emitModel(name, value) { this.$emit(`update:${name}`, value) },
    roleClass(role) { return { Admin: 'role-admin', Manager: 'role-manager', Employee: 'role-member' }[role] || 'role-member' },
    close() { this.$emit('close') },
    save() { this.$emit('save') }
  }
}
</script>

<style>
.admin-dashboard .drawer-backdrop { position: fixed; z-index: 20; inset: 0; display: flex; justify-content: flex-end; background: rgb(18 25 38 / 38%); backdrop-filter: blur(2px); }
.admin-dashboard .role-drawer { display: flex; width: min(100%, 465px); height: 100%; flex-direction: column; background: #fff; box-shadow: -14px 0 40px rgb(19 28 44 / 13%); }
.admin-dashboard .drawer-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 15px; padding: 25px 26px 19px; border-bottom: 1px solid #edf0f4; }
.admin-dashboard .drawer-eyebrow { margin: 0 0 7px; color: #7685d8; font-size: 9px; font-weight: 750; letter-spacing: 1.1px; }
.admin-dashboard .drawer-header h2 { margin: 0; color: #202b3a; font-size: 19px; font-weight: 720; letter-spacing: -.45px; }
.admin-dashboard .drawer-header > div > p:last-child { margin: 6px 0 0; color: #8590a0; font-size: 11px; }
.admin-dashboard .drawer-close { display: grid; width: 30px; height: 30px; place-items: center; border: 1px solid #e7eaf0; border-radius: 7px; color: #788495; background: white; cursor: pointer; }
.admin-dashboard .drawer-close:hover { color: #344054; background: #f6f7f9; }
.admin-dashboard .drawer-close svg { width: 15px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-width: 1.8; }
.admin-dashboard .drawer-body { flex: 1; overflow-y: auto; padding: 21px 26px; }
.admin-dashboard .drawer-user-summary { display: flex; align-items: center; gap: 10px; padding: 13px; border: 1px solid #e9edf3; border-radius: 9px; background: #fafbfc; }
.admin-dashboard .drawer-user-summary > span:nth-child(2) { display: grid; min-width: 0; gap: 4px; }
.admin-dashboard .drawer-user-summary > span:nth-child(2) strong { overflow: hidden; color: #344054; font-size: 11px; text-overflow: ellipsis; white-space: nowrap; }
.admin-dashboard .drawer-user-summary > span:nth-child(2) small { overflow: hidden; color: #8993a3; font-size: 9px; text-overflow: ellipsis; white-space: nowrap; }
.admin-dashboard .role-fieldset { min-width: 0; margin: 25px 0 0; padding: 0; border: 0; }
.admin-dashboard .role-fieldset legend { margin: 0; color: #273243; font-size: 12px; font-weight: 700; }
.admin-dashboard .field-hint { margin: 5px 0 12px; color: #8994a3; font-size: 10px; }
.admin-dashboard .role-option { display: flex; min-height: 66px; align-items: center; gap: 10px; margin-top: 8px; padding: 10px 11px; border: 1px solid #e6eaf0; border-radius: 8px; cursor: pointer; transition: border .15s ease, background .15s ease, box-shadow .15s ease; }
.admin-dashboard .role-option:hover { border-color: #cdd2f6; background: #fbfbff; }
.admin-dashboard .role-option > input { position: absolute; width: 1px; height: 1px; opacity: 0; }
.admin-dashboard .role-option:focus-within { outline: 3px solid rgb(70 87 216 / 17%); outline-offset: 2px; }
.admin-dashboard .role-option-icon { display: grid; width: 33px; height: 33px; flex: 0 0 33px; place-items: center; border-radius: 8px; }
.admin-dashboard .role-option-icon svg { width: 17px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.65; }
.admin-dashboard .role-option-copy { display: grid; flex: 1; gap: 4px; }
.admin-dashboard .role-option-copy strong { color: #344054; font-size: 10px; font-weight: 680; }
.admin-dashboard .role-option-copy small { color: #8792a1; font-size: 9px; line-height: 1.45; }
.admin-dashboard .custom-radio { display: grid; width: 16px; height: 16px; flex: 0 0 16px; place-items: center; border: 1px solid #cdd3dd; border-radius: 50%; background: white; }
.admin-dashboard .role-option-selected .custom-radio { border: 5px solid #4657d8; }
.admin-dashboard .privilege-note { display: flex; gap: 10px; margin-top: 18px; padding: 12px; border: 1px solid #dce7f7; border-radius: 8px; color: #405b84; background: #f2f7ff; }
.admin-dashboard .privilege-icon { display: grid; width: 27px; height: 27px; flex: 0 0 27px; place-items: center; border-radius: 7px; background: rgb(255 255 255 / 75%); }
.admin-dashboard .privilege-icon svg { width: 15px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 1.7; }
.admin-dashboard .privilege-note > span:last-child { display: grid; gap: 4px; }
.admin-dashboard .privilege-note strong { color: inherit; font-size: 10px; font-weight: 700; }
.admin-dashboard .privilege-note small { color: inherit; font-size: 9px; line-height: 1.5; opacity: .82; }
.admin-dashboard .confirm-toggle { display: flex; align-items: center; gap: 9px; margin-top: 17px; color: #667284; font-size: 9px; line-height: 1.4; cursor: pointer; }
.admin-dashboard .confirm-toggle input { position: absolute; width: 1px; height: 1px; opacity: 0; }
.admin-dashboard .confirm-toggle input:focus-visible + .toggle-track { outline: 3px solid rgb(70 87 216 / 22%); outline-offset: 2px; }
.admin-dashboard .toggle-track { position: relative; width: 30px; height: 17px; flex: 0 0 30px; border-radius: 99px; background: #cbd2dd; transition: background .18s ease; }
.admin-dashboard .toggle-track i { position: absolute; top: 3px; left: 3px; width: 11px; height: 11px; border-radius: 50%; background: white; box-shadow: 0 1px 2px rgb(0 0 0 / 15%); transition: transform .18s ease; }
.admin-dashboard .confirm-toggle input:checked + .toggle-track { background: #4657d8; }
.admin-dashboard .confirm-toggle input:checked + .toggle-track i { transform: translateX(13px); }
.admin-dashboard .drawer-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 14px 26px; border-top: 1px solid #edf0f4; background: #fff; }
.admin-dashboard .cancel-button, .admin-dashboard .save-role-button { display: inline-flex; min-height: 36px; align-items: center; justify-content: center; gap: 7px; padding: 0 12px; border-radius: 7px; font: inherit; font-size: 10px; font-weight: 650; cursor: pointer; transition: background .15s ease, border .15s ease, opacity .15s ease; }
.admin-dashboard .cancel-button { border: 1px solid #e2e6ed; color: #5d6878; background: white; }
.admin-dashboard .cancel-button:hover { background: #f8f9fb; }
.admin-dashboard .save-role-button { border: 1px solid #4657d8; color: white; background: #4657d8; }
.admin-dashboard .save-role-button:hover:not(:disabled) { background: #3949c1; }
.admin-dashboard .save-role-button:disabled { cursor: not-allowed; opacity: .48; }
.admin-dashboard .save-role-button svg { width: 14px; fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 2; }
.admin-dashboard .drawer-fade-enter-active .role-drawer, .admin-dashboard .drawer-fade-leave-active .role-drawer { transition: transform .24s cubic-bezier(.22,.75,.25,1); }
.admin-dashboard .drawer-fade-enter-from .role-drawer, .admin-dashboard .drawer-fade-leave-to .role-drawer { transform: translateX(30px); }
.admin-dashboard .drawer-header h2 { font-size: 21px; }
.admin-dashboard .drawer-header > div > p:last-child { font-size: 13px; }
.admin-dashboard .drawer-user-summary > span:nth-child(2) strong { font-size: 13px; }
.admin-dashboard .drawer-user-summary > span:nth-child(2) small, .admin-dashboard .field-hint { font-size: 11px; }
.admin-dashboard .role-fieldset legend { font-size: 14px; }
.admin-dashboard .role-option-copy strong { font-size: 12px; }
.admin-dashboard .role-option-copy small, .admin-dashboard .privilege-note small { font-size: 11px; }
.admin-dashboard .privilege-note strong { font-size: 12px; }
.admin-dashboard .confirm-toggle { font-size: 11px; }
.admin-dashboard .cancel-button, .admin-dashboard .save-role-button { min-height: 39px; font-size: 12px; }
  .admin-dashboard .role-drawer { width: 100%; }
  .admin-dashboard .drawer-header { padding-right: 18px; padding-left: 18px; }
  .admin-dashboard .drawer-body { padding-right: 18px; padding-left: 18px; }
  .admin-dashboard .drawer-footer { padding-right: 18px; padding-left: 18px; }
.admin-dashboard .drawer-header { padding: 26px 28px 21px; }
.admin-dashboard .drawer-body { padding: 24px 28px; }
.admin-dashboard .drawer-footer { padding: 17px 28px; }
.admin-dashboard .drawer-header h2 { font-size: 24px; }
.admin-dashboard .drawer-header > div > p:last-child, .admin-dashboard .field-hint { font-size: 14px; }
.admin-dashboard .role-fieldset legend { font-size: 16px; }
.admin-dashboard .role-option { min-height: 74px; padding: 14px; }
.admin-dashboard .role-option-copy strong, .admin-dashboard .privilege-note strong { font-size: 14px; }
.admin-dashboard .role-option-copy small, .admin-dashboard .privilege-note small { font-size: 13px; }
.admin-dashboard .confirm-toggle { font-size: 13px; }
.admin-dashboard .cancel-button, .admin-dashboard .save-role-button { min-height: 46px; font-size: 14px; }
</style>
