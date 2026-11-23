import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const BASE_URL = "http://127.0.0.1:20128/v1";
const PROVIDER_ID = "omniroute";

type ApiModelConfig = {
	id: string;
	name: string;
	api: "openai-completions";
	input: ("text" | "image")[];
	cost: { input: number; output: number; cacheRead: number; cacheWrite: number };
	reasoning: boolean;
	contextWindow: number;
	maxTokens: number;
};

function read(source: unknown, key: string): unknown {
	if (source === null || typeof source !== "object") return undefined;
	return key in source ? Reflect.get(source, key) : undefined;
}

function positiveInteger(value: unknown, fallback: number): number {
	return typeof value === "number" && Number.isSafeInteger(value) && value > 0 ? value : fallback;
}

function firstString(...values: unknown[]): string | undefined {
	for (const value of values) {
		if (typeof value === "string" && value.length > 0) return value;
	}
	return undefined;
}

/** Dynamic refresh hands us a discovery context; startup hands us nothing. */
function credentialKey(input: unknown): string | undefined {
	if (typeof input === "string") return firstString(input);

	const apiKey = firstString(read(input, "apiKey"));
	if (apiKey) return apiKey;

	const credential = read(input, "credential");
	const access = read(credential, "type") === "oauth" ? firstString(read(credential, "access")) : undefined;
	return access ?? firstString(read(credential, "key"));
}

function modelRows(payload: unknown): unknown[] {
	if (Array.isArray(payload)) return payload;
	const data = read(payload, "data");
	if (Array.isArray(data)) return data;
	const models = read(payload, "models");
	return Array.isArray(models) ? models : [];
}

function toModelConfig(row: unknown): ApiModelConfig | undefined {
	const id = firstString(read(row, "id"));
	if (!id) return undefined;

	const capabilities = read(row, "capabilities");
	const vision = read(capabilities, "vision") === true || read(row, "vision") === true;
	const reasoning = read(capabilities, "reasoning") === true || read(row, "reasoning") === true;
	return {
		id,
		name: `OmniRoute · ${firstString(read(row, "name")) ?? id}`,
		api: "openai-completions",
		input: vision ? ["text", "image"] : ["text"],
		cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
		reasoning,
		contextWindow: positiveInteger(
			read(capabilities, "contextWindow") ?? read(row, "contextWindow") ?? read(row, "context_length"),
			128000,
		),
		maxTokens: positiveInteger(
			read(capabilities, "maxOutput") ?? read(row, "maxOutput") ?? read(row, "max_completion_tokens"),
			16384,
		),
	};
}

async function loadModels(input?: unknown): Promise<ApiModelConfig[]> {
	const apiKey = credentialKey(input);
	if (!apiKey) return [];

	const timeout = AbortSignal.timeout(8000);
	const signalValue = read(input, "signal");
	const signal = signalValue instanceof AbortSignal ? signalValue : undefined;
	const response = await fetch(`${BASE_URL}/models`, {
		headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : undefined,
		signal: signal ? AbortSignal.any([signal, timeout]) : timeout,
	});
	if (!response.ok) {
		throw new Error(`OmniRoute model list failed (HTTP ${response.status})`);
	}

	const rows = modelRows(await response.json());
	return rows.map(toModelConfig).filter((model): model is ApiModelConfig => model !== undefined);
}

export default function (pi: ExtensionAPI) {
	let models: ApiModelConfig[] = [];

	pi.registerProvider(PROVIDER_ID, {
		name: "OmniRoute",
		baseUrl: BASE_URL,
		api: "openai-completions",
		authHeader: true,
		oauth: {
			name: "OmniRoute API key",
			async login(callbacks) {
				const key = (
					await callbacks.onPrompt({
						message: "Enter your OmniRoute API key (create one at http://localhost:20128/dashboard/api-manager)",
						placeholder: "OmniRoute API key",
						secret: true,
					})
				).trim();
				if (!key) throw new Error("OmniRoute API key cannot be empty");

				try {
					models = await loadModels(key);
				} catch (error) {
					const detail = error instanceof Error ? error.message : String(error);
					throw new Error(`OmniRoute rejected that key or is unreachable: ${detail}`);
				}

				return { refresh: "", access: key, expires: Number.MAX_SAFE_INTEGER };
			},
			async refreshToken(credentials) {
				return credentials;
			},
			getApiKey(credentials) {
				return credentials.access;
			},
		},
		models,
		async fetchDynamicModels(context) {
			try {
				let key = credentialKey(context);
				if (!key) {
					const token = await pi.exec("omp", ["token", PROVIDER_ID], { timeout: 8000 });
					key = token.code === 0 ? token.stdout.trim() : undefined;
				}
				if (!key) {
					models = [];
				} else {
					const signalValue = read(context, "signal");
					models = await loadModels({
						apiKey: key,
						signal: signalValue instanceof AbortSignal ? signalValue : undefined,
					});
				}
			} catch (error) {
				// Surface the failure instead of returning an empty roster, which discovery would cache.
				const detail = error instanceof Error ? error.message : String(error);
				throw new Error(`OmniRoute model discovery failed: ${detail}`);
			}
			return models;
		},
	});
}
