// SPDX-License-Identifier: AGPL-3.0-only

import { defineEnvVars } from '@sveltejs/kit/env';

export const variables = defineEnvVars({
	// Microsoft Entra ID application (client) ID, inlined at build time.
	PUBLIC_ENTRA_CLIENT_ID: {
		public: true,
		static: true,
		description: 'Microsoft Entra ID application (client) ID'
	}
});
