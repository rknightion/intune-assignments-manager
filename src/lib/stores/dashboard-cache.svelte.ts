import type { AuditEvent } from '$lib/types/graph';

const CACHE_KEY = 'dashboard-cache';
const CACHE_TTL = 15 * 60 * 1000; // 15 minutes

interface DashboardCacheData {
	appCount: number;
	profileCount: number;
	assignedCount: number;
	recentActivity: AuditEvent[];
	timestamp: number;
}

function createDashboardCache() {
	let appCount = $state<number | null>(null);
	let profileCount = $state<number | null>(null);
	let assignedCount = $state<number | null>(null);
	let recentActivity = $state<AuditEvent[]>([]);
	let loading = $state(false);
	let error = $state<string | null>(null);

	function loadFromLocalStorage(): boolean {
		try {
			const raw = localStorage.getItem(CACHE_KEY);
			if (!raw) return false;
			const data: DashboardCacheData = JSON.parse(raw);
			if (Date.now() - data.timestamp > CACHE_TTL) return false;
			appCount = data.appCount;
			profileCount = data.profileCount;
			assignedCount = data.assignedCount;
			recentActivity = data.recentActivity;
			return true;
		} catch {
			return false;
		}
	}

	function saveToLocalStorage() {
		if (appCount === null || profileCount === null) return;
		const data: DashboardCacheData = {
			appCount: appCount ?? 0,
			profileCount: profileCount ?? 0,
			assignedCount: assignedCount ?? 0,
			recentActivity,
			timestamp: Date.now()
		};
		try {
			localStorage.setItem(CACHE_KEY, JSON.stringify(data));
		} catch {
			// localStorage full or unavailable
		}
	}

	return {
		get appCount() {
			return appCount;
		},
		get profileCount() {
			return profileCount;
		},
		get assignedCount() {
			return assignedCount;
		},
		get recentActivity() {
			return recentActivity;
		},
		get loading() {
			return loading;
		},
		get error() {
			return error;
		},

		loadFromLocalStorage,

		setLoading(v: boolean) {
			loading = v;
		},

		setError(e: string | null) {
			error = e;
		},

		setCounts(apps: number, profiles: number, assigned: number) {
			appCount = apps;
			profileCount = profiles;
			assignedCount = assigned;
			saveToLocalStorage();
		},

		setRecentActivity(events: AuditEvent[]) {
			recentActivity = events;
			saveToLocalStorage();
		},

		/** Update app/profile counts as a side-effect from list pages */
		updateAppCount(count: number) {
			appCount = count;
			saveToLocalStorage();
		},

		updateProfileCount(count: number) {
			profileCount = count;
			saveToLocalStorage();
		},

		clearCache() {
			appCount = null;
			profileCount = null;
			assignedCount = null;
			recentActivity = [];
			error = null;
			try {
				localStorage.removeItem(CACHE_KEY);
			} catch {
				// ignore
			}
		}
	};
}

export const dashboardCache = createDashboardCache();
