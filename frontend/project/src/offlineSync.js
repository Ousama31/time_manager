import { Network } from '@capacitor/network';
import { Haptics, ImpactStyle, NotificationType } from '@capacitor/haptics';
import api from './api';

const QUEUE_STORAGE_KEY = 'tm_offline_fifo_queue';
const CACHE_STORAGE_KEY = 'tm_offline_cache';

class OfflineSyncManager {
  constructor() {
    this.isOnline = true;
    this.isSyncing = false;
    this.listeners = new Set();
    this.init();
  }

  async init() {
    try {
      const status = await Network.getStatus();
      this.isOnline = status.connected;
    } catch {
      this.isOnline = navigator.onLine;
    }

    // Listen to network status changes
    Network.addListener('networkStatusChange', async (status) => {
      const wasOffline = !this.isOnline;
      this.isOnline = status.connected;
      this.notifyListeners();

      if (wasOffline && this.isOnline) {
        // Just reconnected: trigger automatic FIFO sync
        await this.syncPendingQueue();
      }
    });

    window.addEventListener('online', async () => {
      if (!this.isOnline) {
        this.isOnline = true;
        this.notifyListeners();
        await this.syncPendingQueue();
      }
    });

    window.addEventListener('offline', () => {
      this.isOnline = false;
      this.notifyListeners();
    });
  }

  subscribe(callback) {
    this.listeners.add(callback);
    callback({ isOnline: this.isOnline, isSyncing: this.isSyncing, queueCount: this.getQueue().length });
    return () => this.listeners.delete(callback);
  }

  notifyListeners() {
    const queue = this.getQueue();
    for (const listener of this.listeners) {
      listener({
        isOnline: this.isOnline,
        isSyncing: this.isSyncing,
        queueCount: queue.length
      });
    }
  }

  // FIFO Queue management in localStorage (JSON.stringify)
  getQueue() {
    try {
      const raw = localStorage.getItem(QUEUE_STORAGE_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch {
      return [];
    }
  }

  saveQueue(queue) {
    localStorage.setItem(QUEUE_STORAGE_KEY, JSON.stringify(queue));
    this.notifyListeners();
  }

  enqueue(action) {
    const queue = this.getQueue();
    const item = {
      id: `${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      timestamp: new Date().toISOString(),
      ...action
    };
    // Append to back of list (FIFO)
    queue.push(item);
    this.saveQueue(queue);

    try {
      Haptics.impact({ style: ImpactStyle.Light });
    } catch {}

    return item;
  }

  dequeue() {
    const queue = this.getQueue();
    if (queue.length === 0) return null;
    const first = queue.shift(); // First In, First Out
    this.saveQueue(queue);
    return first;
  }

  clearQueue() {
    localStorage.removeItem(QUEUE_STORAGE_KEY);
    this.notifyListeners();
  }

  // Local Cache storage
  saveLocalCache(key, data) {
    try {
      const cache = this.getAllCache();
      cache[key] = { data, updatedAt: Date.now() };
      localStorage.setItem(CACHE_STORAGE_KEY, JSON.stringify(cache));
    } catch (e) {
      console.warn('Failed to save to local cache', e);
    }
  }

  getLocalCache(key) {
    try {
      const cache = this.getAllCache();
      return cache[key]?.data || null;
    } catch {
      return null;
    }
  }

  getAllCache() {
    try {
      const raw = localStorage.getItem(CACHE_STORAGE_KEY);
      return raw ? JSON.parse(raw) : {};
    } catch {
      return {};
    }
  }

  // Synchronize queued actions with the backend in FIFO order
  async syncPendingQueue(onProgress = null) {
    const queue = this.getQueue();
    if (queue.length === 0 || this.isSyncing || !this.isOnline) {
      return { syncedCount: 0, errors: [] };
    }

    this.isSyncing = true;
    this.notifyListeners();

    let syncedCount = 0;
    const errors = [];

    try {
      while (this.getQueue().length > 0) {
        const item = this.getQueue()[0]; // Peek at front of FIFO
        if (onProgress) onProgress({ current: item, remaining: this.getQueue().length });

        try {
          await api({
            method: item.method,
            url: item.url,
            data: item.data,
            headers: item.headers || {}
          });

          // Successfully executed, remove from FIFO
          this.dequeue();
          syncedCount++;
        } catch (error) {
          console.error('Error executing queued offline request:', item, error);
          errors.push({ item, error });

          // Per Epitech spec: on error, cancel execution and resume data from server
          try {
            Haptics.notification({ type: NotificationType.Error });
          } catch {}
          break;
        }
      }

      if (syncedCount > 0 && errors.length === 0) {
        try {
          Haptics.notification({ type: NotificationType.Success });
        } catch {}
      }
    } finally {
      this.isSyncing = false;
      this.notifyListeners();
    }

    return { syncedCount, errors };
  }
}

export const offlineSync = new OfflineSyncManager();
export default offlineSync;
