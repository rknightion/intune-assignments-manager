import { Monitor, Smartphone, TabletSmartphone, Globe } from 'lucide-svelte';
import type { MobileApp, ConfigurationPolicy } from '$lib/types/graph';
import { getAppTypeInfo } from '$lib/utils/app-types';
import { getPlatformLabel, getTechnologyLabel } from '$lib/utils/profile-types';

// ─── Types ──────────────────────────────────────────────────────────

export type AssignmentStatus = 'all' | 'assigned' | 'unassigned';

export interface FilterOption {
	id: string;
	label: string;
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	icon?: any;
}

// ─── App Platform Filter Options ────────────────────────────────────

export const APP_PLATFORM_OPTIONS: FilterOption[] = [
	{ id: 'Windows', label: 'Windows', icon: Monitor },
	{ id: 'iOS', label: 'iOS', icon: Smartphone },
	{ id: 'Android', label: 'Android', icon: TabletSmartphone },
	{ id: 'macOS', label: 'macOS', icon: Monitor },
	{ id: 'Web', label: 'Web', icon: Globe }
];

// ─── Profile Platform Filter Options ────────────────────────────────

export const PROFILE_PLATFORM_OPTIONS: FilterOption[] = [
	{ id: 'Windows', label: 'Windows', icon: Monitor },
	{ id: 'macOS', label: 'macOS', icon: Monitor },
	{ id: 'iOS', label: 'iOS', icon: Smartphone },
	{ id: 'Android', label: 'Android', icon: TabletSmartphone },
	{ id: 'Android Enterprise', label: 'Android Enterprise', icon: TabletSmartphone },
	{ id: 'Linux', label: 'Linux', icon: Monitor }
];

// ─── Profile Technology Filter Options ──────────────────────────────

export const PROFILE_TECHNOLOGY_OPTIONS: FilterOption[] = [
	{ id: 'MDM', label: 'MDM' },
	{ id: 'Config Manager', label: 'Config Manager' },
	{ id: 'Microsoft Defender', label: 'Microsoft Defender' },
	{ id: 'Enrollment', label: 'Enrollment' }
];

// ─── Audit Category Filter Options ─────────────────────────────────

export const AUDIT_CATEGORY_OPTIONS: FilterOption[] = [
	{ id: 'Application', label: 'Application' },
	{ id: 'Compliance', label: 'Compliance' },
	{ id: 'Device', label: 'Device' },
	{ id: 'DeviceConfiguration', label: 'Device Configuration' },
	{ id: 'DeviceIntent', label: 'Device Intent' },
	{ id: 'Enrollment', label: 'Enrollment' },
	{ id: 'Role', label: 'Role' },
	{ id: 'SoftwareUpdates', label: 'Software Updates' },
	{ id: 'Other', label: 'Other' }
];

export const AUDIT_RESULT_OPTIONS: FilterOption[] = [
	{ id: 'Success', label: 'Success' },
	{ id: 'Failure', label: 'Failure' }
];

// ─── Dynamic App Type Options ───────────────────────────────────────

export function deriveAppTypeOptions(apps: MobileApp[]): FilterOption[] {
	const seen = new Map<string, FilterOption>();
	for (const app of apps) {
		const info = getAppTypeInfo(app['@odata.type']);
		if (!seen.has(info.label)) {
			seen.set(info.label, { id: info.label, label: info.label, icon: info.icon });
		}
	}
	return [...seen.values()].sort((a, b) => a.label.localeCompare(b.label));
}

// ─── Filter Predicates ──────────────────────────────────────────────

export function filterApps(
	apps: MobileApp[],
	options: {
		search?: string;
		platforms?: string[];
		appTypes?: string[];
		assignmentStatus?: AssignmentStatus;
	}
): MobileApp[] {
	let result = apps;

	const q = options.search?.trim().toLowerCase();
	if (q) {
		result = result.filter((app) => app.displayName.toLowerCase().includes(q));
	}

	if (options.platforms && options.platforms.length > 0) {
		const platforms = new Set(options.platforms);
		result = result.filter((app) => {
			const info = getAppTypeInfo(app['@odata.type']);
			return platforms.has(info.platform);
		});
	}

	if (options.appTypes && options.appTypes.length > 0) {
		const types = new Set(options.appTypes);
		result = result.filter((app) => {
			const info = getAppTypeInfo(app['@odata.type']);
			return types.has(info.label);
		});
	}

	if (options.assignmentStatus === 'assigned') {
		result = result.filter((app) => app.isAssigned);
	} else if (options.assignmentStatus === 'unassigned') {
		result = result.filter((app) => !app.isAssigned);
	}

	return result;
}

export function filterProfiles(
	profiles: ConfigurationPolicy[],
	options: {
		search?: string;
		platforms?: string[];
		technologies?: string[];
		assignmentStatus?: AssignmentStatus;
	}
): ConfigurationPolicy[] {
	let result = profiles;

	const q = options.search?.trim().toLowerCase();
	if (q) {
		result = result.filter((p) => p.name.toLowerCase().includes(q));
	}

	if (options.platforms && options.platforms.length > 0) {
		const platformSet = new Set(options.platforms);
		result = result.filter((p) => {
			const label = getPlatformLabel(p.platforms);
			return platformSet.has(label);
		});
	}

	if (options.technologies && options.technologies.length > 0) {
		const techSet = new Set(options.technologies);
		result = result.filter((p) => {
			const label = getTechnologyLabel(p.technologies);
			return techSet.has(label);
		});
	}

	if (options.assignmentStatus === 'assigned') {
		result = result.filter((p) => p.isAssigned);
	} else if (options.assignmentStatus === 'unassigned') {
		result = result.filter((p) => !p.isAssigned);
	}

	return result;
}

export function hasActiveAppFilters(
	platforms: string[],
	appTypes: string[],
	assignmentStatus: AssignmentStatus
): boolean {
	return platforms.length > 0 || appTypes.length > 0 || assignmentStatus !== 'all';
}

export function hasActiveProfileFilters(
	platforms: string[],
	technologies: string[],
	assignmentStatus: AssignmentStatus
): boolean {
	return platforms.length > 0 || technologies.length > 0 || assignmentStatus !== 'all';
}
