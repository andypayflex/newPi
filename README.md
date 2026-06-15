# Pi Azure Agent

Local project scaffold for running [Pi](https://pi.dev/docs/latest) as a coding agent with Azure-hosted models behind it.

This repo is set up for two backend shapes:

1. `azure-openai-responses` via Pi's built-in Azure provider
2. A custom OpenAI-compatible provider for Azure AI Foundry-style endpoints

Use the built-in Azure provider first unless your endpoint is not a standard Azure OpenAI base URL.

## Repo Layout

- `.pi/settings.json` - project-local Pi defaults
- `.env.pi.example` - environment variables for the built-in Azure provider
- `examples/models.azure-foundry.example.json` - custom provider example for non-standard Foundry endpoints
- `scripts/setup.sh` - one-command bootstrap (Node, Pi, packages, .env.pi)
- `scripts/run-pi.sh` - loads `.env.pi` and starts `pi`
- `AGENTS.md` - project instructions Pi will load automatically

## Quick Start (one command)

```bash
./scripts/setup.sh
```

That handles everything: Node check, Pi install, extension/skill packages, and `.env.pi` creation.

Then edit `.env.pi` with your Azure credentials and run:

```bash
./scripts/run-pi.sh
# or
npm run pi
```

---

## Manual Setup

Prefer the one-command setup above. The steps below show what `setup.sh` does.

### 1. Prerequisites

- **Node 18+** (for Pi and npm packages)
- **git** (recommended, for package updates)

### 2. Install Pi

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

Or:

```bash
curl -fsSL https://pi.dev/install.sh | sh
```

### 3. Install extensions & skills

```bash
pi install npm:pi-agent-browser-native
pi install npm:pi-agent-memory
pi install npm:pi-prompt-autoresearch
pi install npm:pi-web-access
pi install npm:pi-mcporter
```

### 4. Azure Provider Setup

If your endpoint looks like either of these, start here:

- `https://<resource>.openai.azure.com`
- `https://<resource>.cognitiveservices.azure.com`

Setup:

```bash
cd /home/andy/dev/pi-azure-agent
cp .env.pi.example .env.pi
```

Fill in:

- `AZURE_OPENAI_API_KEY`
- `AZURE_OPENAI_BASE_URL`
- `PI_DEFAULT_MODEL`
- `AZURE_OPENAI_DEPLOYMENT_NAME_MAP`

Example:

```bash
AZURE_OPENAI_API_KEY=replace-me
AZURE_OPENAI_BASE_URL=https://my-resource.openai.azure.com
AZURE_OPENAI_API_VERSION=2024-02-01
PI_DEFAULT_MODEL=gpt-4.1
AZURE_OPENAI_DEPLOYMENT_NAME_MAP=gpt-4.1=my-gpt-4-1-deployment
```

Then run:

```bash
./scripts/run-pi.sh
```

Pi should open with the project-local defaults from `.pi/settings.json`.

## Custom Azure AI Foundry Path

If your URL is not a standard Azure OpenAI resource base URL, use the custom model path.

Copy the example file into Pi's global config area:

```bash
mkdir -p ~/.pi/agent
cp examples/models.azure-foundry.example.json ~/.pi/agent/models.json
```

Then export the variables referenced by that file:

```bash
export AZURE_FOUNDRY_API_KEY=replace-me
export AZURE_FOUNDRY_BASE_URL=https://your-endpoint.example.com/v1
```

Update the model entry in `~/.pi/agent/models.json` to match your deployed model ID and capabilities.

If your endpoint expects `api-key` headers rather than `Authorization: Bearer`, keep the example shape as-is.

## Recommended First Edit

Once you have the exact endpoint and deployed model name in place:

1. Set `.pi/settings.json` `defaultModel`
2. Adjust `.env.pi` deployment mapping or `models.json`
3. Start Pi and run a small test prompt against this repo

Example:

```text
Summarize this repository and tell me whether the Azure Pi setup is complete.
```

## Notes

- Pi project settings live in `.pi/settings.json`.
- Pi global settings live in `~/.pi/agent/settings.json`.
- Pi custom models live in `~/.pi/agent/models.json`.
- Pi will load this repo's `AGENTS.md` automatically when started here.

## Sources

- Pi docs home: https://pi.dev/docs/latest
- Providers: https://pi.dev/docs/latest/providers
- Custom models: https://pi.dev/docs/latest/models
- Settings: https://pi.dev/docs/latest/settings
