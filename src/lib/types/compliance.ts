import type { AssignmentTarget } from './graph';

// ─── Compliance Policy Types ────────────────────────────────────────

export interface DeviceCompliancePolicy {
	id: string;
	displayName: string;
	description: string | null;
	createdDateTime: string;
	lastModifiedDateTime: string;
	version: number;
	roleScopeTagIds: string[];
	'@odata.type': string;
	isAssigned: boolean;
}

export interface DeviceCompliancePolicyAssignment {
	id: string;
	target: AssignmentTarget;
}
