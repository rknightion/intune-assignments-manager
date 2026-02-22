<script lang="ts">
	import { X, Package, Search } from 'lucide-svelte';
	import SearchInput from '$lib/components/ui/SearchInput.svelte';
	import MultiSelectFilter from '$lib/components/ui/MultiSelectFilter.svelte';
	import Skeleton from '$lib/components/ui/Skeleton.svelte';
	import EmptyState from '$lib/components/ui/EmptyState.svelte';
	import ErrorState from '$lib/components/ui/ErrorState.svelte';
	import Tabs from '$lib/components/ui/Tabs.svelte';
	import { getAppTypeInfo } from '$lib/utils/app-types';
	import { getProfileTypeInfo } from '$lib/utils/profile-types';
	import { getGraphClient } from '$lib/stores/graph';
	import { listApps, getApp } from '$lib/graph/apps';
	import { listConfigPolicies, getConfigPolicy } from '$lib/graph/configurations';
	import { toFriendlyMessage } from '$lib/graph/errors';
	import type { MobileApp, ConfigurationPolicy } from '$lib/types/graph';
	import {
		APP_PLATFORM_OPTIONS,
		PROFILE_PLATFORM_OPTIONS,
		PROFILE_TECHNOLOGY_OPTIONS,
		deriveAppTypeOptions,
		filterApps,
		filterProfiles,
		type AssignmentStatus
	} from '$lib/utils/filters';

	interface Props {
		selectedApps: MobileApp[];
		selectedProfiles: ConfigurationPolicy[];
		preselectedAppId: string | null;
		preselectedProfileId: string | null;
		apps: MobileApp[];
		profiles: ConfigurationPolicy[];
		onUpdateApps: (apps: MobileApp[]) => void;
		onUpdateProfiles: (profiles: ConfigurationPolicy[]) => void;
		onAppsLoaded: (apps: MobileApp[]) => void;
		onProfilesLoaded: (profiles: ConfigurationPolicy[]) => void;
	}

	const {
		selectedApps,
		selectedProfiles,
		preselectedAppId,
		preselectedProfileId,
		apps,
		profiles,
		onUpdateApps,
		onUpdateProfiles,
		onAppsLoaded,
		onProfilesLoaded
	}: Props = $props();

	// ─── Internal State ──────────────────────────────────────────────
	let activeTab = $state<string>('apps');
	let appSearch = $state('');
	let profileSearch = $state('');
	let appPlatformFilter = $state<string[]>([]);
	let appTypeFilter = $state<string[]>([]);
	let appAssignmentStatus = $state<AssignmentStatus>('all');
	let profilePlatformFilter = $state<string[]>([]);
	let profileTechnologyFilter = $state<string[]>([]);
	let profileAssignmentStatus = $state<AssignmentStatus>('all');
	let loadingApps = $state(false);
	let loadingProfiles = $state(false);
	let appsError = $state<string | null>(null);
	let profilesError = $state<string | null>(null);
	let hasPreselected = $state(false);

	const tabs = [
		{ id: 'apps', label: 'Apps' },
		{ id: 'profiles', label: 'Config Profiles' }
	];

	// ─── Derived State ───────────────────────────────────────────────
	const appTypeOptions = $derived(deriveAppTypeOptions(apps));

	const filteredApps = $derived(
		filterApps(apps, {
			search: appSearch,
			platforms: appPlatformFilter,
			appTypes: appTypeFilter,
			assignmentStatus: appAssignmentStatus
		})
	);

	const filteredProfiles = $derived(
		filterProfiles(profiles, {
			search: profileSearch,
			platforms: profilePlatformFilter,
			technologies: profileTechnologyFilter,
			assignmentStatus: profileAssignmentStatus
		})
	);

	const appStatusOptions: { id: AssignmentStatus; label: string }[] = [
		{ id: 'all', label: 'All' },
		{ id: 'assigned', label: 'Assigned' },
		{ id: 'unassigned', label: 'Unassigned' }
	];

	const profileStatusOptions: { id: AssignmentStatus; label: string }[] = [
		{ id: 'all', label: 'All' },
		{ id: 'assigned', label: 'Assigned' },
		{ id: 'unassigned', label: 'Unassigned' }
	];

	const allSelected = $derived([
		...selectedApps.map((app) => ({ type: 'app' as const, id: app.id, name: app.displayName })),
		...selectedProfiles.map((profile) => ({
			type: 'profile' as const,
			id: profile.id,
			name: profile.name
		}))
	]);

	// ─── Selection Helpers ───────────────────────────────────────────
	function isAppSelected(appId: string): boolean {
		return selectedApps.some((a) => a.id === appId);
	}

	function isProfileSelected(profileId: string): boolean {
		return selectedProfiles.some((p) => p.id === profileId);
	}

	function toggleApp(app: MobileApp): void {
		if (isAppSelected(app.id)) {
			onUpdateApps(selectedApps.filter((a) => a.id !== app.id));
		} else {
			onUpdateApps([...selectedApps, app]);
		}
	}

	function toggleProfile(profile: ConfigurationPolicy): void {
		if (isProfileSelected(profile.id)) {
			onUpdateProfiles(selectedProfiles.filter((p) => p.id !== profile.id));
		} else {
			onUpdateProfiles([...selectedProfiles, profile]);
		}
	}

	function removeApp(appId: string): void {
		onUpdateApps(selectedApps.filter((a) => a.id !== appId));
	}

	function removeProfile(profileId: string): void {
		onUpdateProfiles(selectedProfiles.filter((p) => p.id !== profileId));
	}

	// ─── Data Fetching ───────────────────────────────────────────────
	async function fetchApps(): Promise<void> {
		loadingApps = true;
		appsError = null;
		try {
			const client = getGraphClient();
			const result = await listApps(client, { orderBy: 'displayName' });
			onAppsLoaded(result);
		} catch (err) {
			appsError = toFriendlyMessage(err);
		} finally {
			loadingApps = false;
		}
	}

	async function fetchProfiles(): Promise<void> {
		loadingProfiles = true;
		profilesError = null;
		try {
			const client = getGraphClient();
			const result = await listConfigPolicies(client);
			onProfilesLoaded(result);
		} catch (err) {
			profilesError = toFriendlyMessage(err);
		} finally {
			loadingProfiles = false;
		}
	}

	// ─── Pre-selection ───────────────────────────────────────────────
	async function handlePreselection(): Promise<void> {
		if (hasPreselected) return;
		hasPreselected = true;

		const client = getGraphClient();

		if (preselectedAppId) {
			activeTab = 'apps';
			const existing = apps.find((a) => a.id === preselectedAppId);
			if (existing) {
				if (!isAppSelected(existing.id)) {
					onUpdateApps([...selectedApps, existing]);
				}
			} else {
				try {
					const app = await getApp(client, preselectedAppId);
					if (!isAppSelected(app.id)) {
						onUpdateApps([...selectedApps, app]);
					}
				} catch {
					// Pre-selection failed silently
				}
			}
		}

		if (preselectedProfileId) {
			if (!preselectedAppId) activeTab = 'profiles';
			const existing = profiles.find((p) => p.id === preselectedProfileId);
			if (existing) {
				if (!isProfileSelected(existing.id)) {
					onUpdateProfiles([...selectedProfiles, existing]);
				}
			} else {
				try {
					const profile = await getConfigPolicy(client, preselectedProfileId);
					if (!isProfileSelected(profile.id)) {
						onUpdateProfiles([...selectedProfiles, profile]);
					}
				} catch {
					// Pre-selection failed silently
				}
			}
		}
	}

	// ─── Effects ─────────────────────────────────────────────────────
	$effect(() => {
		if (apps.length === 0) {
			fetchApps();
		}
	});

	$effect(() => {
		if (profiles.length === 0) {
			fetchProfiles();
		}
	});

	$effect(() => {
		if (
			(preselectedAppId || preselectedProfileId) &&
			!hasPreselected &&
			(apps.length > 0 || profiles.length > 0 || !loadingApps || !loadingProfiles)
		) {
			handlePreselection();
		}
	});
</script>

<!-- Tabs with animated underline -->
<div class="mb-4">
	<Tabs {tabs} active={activeTab} onchange={(id) => (activeTab = id)} />
</div>

<!-- Selected Items Chips -->
{#if allSelected.length > 0}
	<div class="mb-3 flex flex-wrap gap-2">
		{#each allSelected as chip (chip.type + chip.id)}
			<span
				class="bg-accent-light text-accent inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-medium"
			>
				{chip.name}
				<button
					type="button"
					class="hover:bg-accent/10 ml-0.5 rounded-full p-0.5 transition-colors"
					aria-label="Remove {chip.name}"
					onclick={() => {
						if (chip.type === 'app') removeApp(chip.id);
						else removeProfile(chip.id);
					}}
				>
					<X size={14} />
				</button>
			</span>
		{/each}
	</div>
{/if}

<!-- Tab Panels -->
{#if activeTab === 'apps'}
	<div role="tabpanel">
		<div class="mb-3">
			<SearchInput placeholder="Search apps by name..." bind:value={appSearch} />
		</div>
		<div class="mb-3 flex flex-wrap items-center gap-2">
			<MultiSelectFilter
				label="Platform"
				options={APP_PLATFORM_OPTIONS}
				bind:selected={appPlatformFilter}
			/>
			<MultiSelectFilter label="App Type" options={appTypeOptions} bind:selected={appTypeFilter} />
			<div class="flex gap-1" role="radiogroup" aria-label="Assignment status">
				{#each appStatusOptions as option (option.id)}
					<button
						type="button"
						role="radio"
						aria-checked={appAssignmentStatus === option.id}
						onclick={() => (appAssignmentStatus = option.id)}
						class="rounded-full border px-2.5 py-1 text-xs font-medium transition-colors {appAssignmentStatus ===
						option.id
							? 'border-accent bg-accent text-white'
							: 'border-border text-ink-faint hover:border-accent hover:text-accent'}"
					>
						{option.label}
					</button>
				{/each}
			</div>
		</div>

		{#if appsError}
			<div class="mb-4">
				<ErrorState message={appsError} onretry={fetchApps} />
			</div>
		{/if}

		{#if loadingApps}
			<div class="border-border space-y-2 rounded-lg border p-2">
				{#each Array(6) as _}
					<div class="flex items-center gap-3 px-2 py-2">
						<Skeleton width="1rem" height="1rem" rounded="sm" />
						<Skeleton width="1.125rem" height="1.125rem" rounded="sm" />
						<div class="flex-1 space-y-1">
							<Skeleton width="50%" height="0.875rem" />
							<Skeleton width="30%" height="0.625rem" />
						</div>
					</div>
				{/each}
			</div>
		{:else if filteredApps.length === 0 && appSearch.trim() !== ''}
			<EmptyState
				icon={Search}
				title="No apps match your search"
				description="Try a different search term or clear your filter."
			/>
		{:else if apps.length === 0 && !appsError}
			<EmptyState
				icon={Package}
				title="No applications found"
				description="Your Intune tenant doesn't have any mobile apps configured."
			/>
		{:else}
			<div class="border-border max-h-96 overflow-y-auto rounded-lg border">
				{#each filteredApps as app (app.id)}
					{@const typeInfo = getAppTypeInfo(app['@odata.type'])}
					{@const Icon = typeInfo.icon}
					<label
						class="border-border hover:bg-canvas flex cursor-pointer items-center gap-3 border-b px-4 py-2.5 last:border-b-0"
					>
						<input
							type="checkbox"
							class="accent-accent h-4 w-4 rounded"
							checked={isAppSelected(app.id)}
							onchange={() => toggleApp(app)}
						/>
						<Icon size={18} class="text-muted shrink-0" />
						<div class="min-w-0 flex-1">
							<p class="text-ink truncate text-sm font-medium">
								{app.displayName}
							</p>
							<p class="text-ink-faint truncate text-xs">
								{typeInfo.label}
								{#if app.publisher}
									&middot; {app.publisher}
								{/if}
							</p>
						</div>
					</label>
				{/each}
			</div>
		{/if}
	</div>
{:else}
	<div role="tabpanel">
		<div class="mb-3">
			<SearchInput placeholder="Search profiles by name..." bind:value={profileSearch} />
		</div>
		<div class="mb-3 flex flex-wrap items-center gap-2">
			<MultiSelectFilter
				label="Platform"
				options={PROFILE_PLATFORM_OPTIONS}
				bind:selected={profilePlatformFilter}
			/>
			<MultiSelectFilter
				label="Technology"
				options={PROFILE_TECHNOLOGY_OPTIONS}
				bind:selected={profileTechnologyFilter}
			/>
			<div class="flex gap-1" role="radiogroup" aria-label="Assignment status">
				{#each profileStatusOptions as option (option.id)}
					<button
						type="button"
						role="radio"
						aria-checked={profileAssignmentStatus === option.id}
						onclick={() => (profileAssignmentStatus = option.id)}
						class="rounded-full border px-2.5 py-1 text-xs font-medium transition-colors {profileAssignmentStatus ===
						option.id
							? 'border-accent bg-accent text-white'
							: 'border-border text-ink-faint hover:border-accent hover:text-accent'}"
					>
						{option.label}
					</button>
				{/each}
			</div>
		</div>

		{#if profilesError}
			<div class="mb-4">
				<ErrorState message={profilesError} onretry={fetchProfiles} />
			</div>
		{/if}

		{#if loadingProfiles}
			<div class="border-border space-y-2 rounded-lg border p-2">
				{#each Array(6) as _}
					<div class="flex items-center gap-3 px-2 py-2">
						<Skeleton width="1rem" height="1rem" rounded="sm" />
						<Skeleton width="1.125rem" height="1.125rem" rounded="sm" />
						<div class="flex-1 space-y-1">
							<Skeleton width="50%" height="0.875rem" />
							<Skeleton width="30%" height="0.625rem" />
						</div>
					</div>
				{/each}
			</div>
		{:else if filteredProfiles.length === 0 && profileSearch.trim() !== ''}
			<EmptyState
				icon={Search}
				title="No profiles match your search"
				description="Try a different search term or clear your filter."
			/>
		{:else if profiles.length === 0 && !profilesError}
			<EmptyState
				icon={Package}
				title="No configuration profiles found"
				description="Your Intune tenant doesn't have any configuration policies configured."
			/>
		{:else}
			<div class="border-border max-h-96 overflow-y-auto rounded-lg border">
				{#each filteredProfiles as profile (profile.id)}
					{@const typeInfo = getProfileTypeInfo(profile.platforms, profile.technologies)}
					{@const Icon = typeInfo.icon}
					<label
						class="border-border hover:bg-canvas flex cursor-pointer items-center gap-3 border-b px-4 py-2.5 last:border-b-0"
					>
						<input
							type="checkbox"
							class="accent-accent h-4 w-4 rounded"
							checked={isProfileSelected(profile.id)}
							onchange={() => toggleProfile(profile)}
						/>
						<Icon size={18} class="text-muted shrink-0" />
						<div class="min-w-0 flex-1">
							<p class="text-ink truncate text-sm font-medium">
								{profile.name}
							</p>
							<p class="text-ink-faint truncate text-xs">
								{typeInfo.label}
								&middot; {profile.settingCount} setting{profile.settingCount !== 1 ? 's' : ''}
							</p>
						</div>
					</label>
				{/each}
			</div>
		{/if}
	</div>
{/if}
