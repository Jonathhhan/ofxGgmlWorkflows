# Hermes Source Learning Map

Use this map when Hermes needs to learn from upstream code without blurring the
ofxGgml addon boundaries. Treat these projects as source-learning references,
not as permission to vendor code, copy generated artifacts, or change runtime
ownership.

Generate an agent-ready retrieval packet with:

```powershell
scripts\plan-hermes-source-learning.ps1 -Json
```

## Primary Sources

### ggml-org

- `https://github.com/ggml-org/ggml` - low-level tensor and machine-learning
  library. Read `include`, `src`, `tests`, `examples`, `docs`, and CMake files
  when learning core tensor, backend, quantization, and no-runtime-allocation
  patterns.
- `https://github.com/ggml-org/llama.cpp` - LLM inference in C/C++ and the main
  proving ground for new ggml features. Read model-loading, GGUF, backend,
  server, tools, examples, and API changelog docs when learning text inference
  provider behavior.
- `https://github.com/ggml-org/whisper.cpp` - speech-to-text inference pattern
  where the high-level model lives in the companion layer while ggml provides
  the machine-learning core. Read `whisper.h`, `whisper.cpp`, examples, model
  download scripts, quantization paths, and backend setup docs when learning
  audio runtime behavior.

### stable-diffusion.cpp

- `https://github.com/leejet/stable-diffusion.cpp` - pure C/C++ diffusion
  inference based on ggml, covering image, edit, and video model families such
  as SD, SDXL, SD3, Flux, Wan, Qwen Image, and Z-Image. Read `include`, `src`,
  `examples`, `docs`, CMake, backend selection, performance, quantization/GGUF,
  and command-line docs when learning diffusion runtime behavior.

### openFrameworks

- `https://github.com/openframeworks/openFrameworks` - the C++ creative-coding
  toolkit and project layout authority. Read `addons`, `apps`, `docs`,
  `examples`, `libs`, `scripts`, `projectGenerator`, platform docs, and
  generated project guidance when learning addon structure or build workflows.

## Agent Source References

Use external agent repositories as source-learning references only. Do not
vendor their code, copy their runtime architecture wholesale, or let their
claims override local evidence and ofxGgml lane boundaries. These references
appear in the improvement planner (`scripts\plan-hermes-agent-improvement.ps1`)
as `agent_source_references`.

| Source | Learn From | Translate To |
| --- | --- | --- |
| `NousResearch/hermes-agent` | learning-loop design, skill creation, persistent searchable memory, isolated subagent fanout | source-grounded memory records, specialized prompt packets, bounded sidecar reviewers, agent-improvement evals |
| `openai/codex` | local coding-agent ergonomics, repository instruction discovery, terminal-first validation workflow, handoff discipline | `AGENTS.md`/`HERMES.md` layering, local validation before handoff, explicit permissions, clean final summaries |

## Lessons For ofxGgml

- Keep Core as the shared ggml/runtime provider. Upstream model projects can
  teach implementation details, but model-specific UX and setup stay in
  companion addons.
- Keep openFrameworks release layout intact. Addons live beside the OF root,
  examples stay in addon-owned folders, and generated project files remain
  disposable unless a workflow explicitly owns them.
- Treat openFrameworks releases as self-contained. Do not mix files, generated
  projects, libraries, or examples across different OF release directories.
- Study upstream C APIs, backend flags, model file formats, and runtime
  initialization paths before designing addon abstractions.
- Study `stable-diffusion.cpp` for diffusion-specific model loading, sampler,
  backend selection, image/video generation, and conversion behavior, then keep
  UX and model setup in the StableDiffusion or Video companion lane.
- Prefer small provider contracts over copied model logic. Move behavior into
  `ofxGgmlCore` only when it is stable, domain-neutral, dependency-light, and
  covered by focused tests.
- Always classify the translated lesson as Core runtime, Workflows policy, or
  companion UX before editing.
- Preserve backend honesty: hardware acceleration support should be backed by
  runtime smoke evidence, not inferred from headers, libraries, or build flags.
- Treat upstream model files, generated binaries, caches, sample media, and
  downloaded runtimes as generated or external artifacts that do not belong in
  addon commits.

## Retrieval Order

1. Read local `AGENTS.md`, `HERMES.md`, and the touched addon docs.
2. Check `docs\hermes-memory-contract.md` and run
   `scripts\check-hermes-memory-index.ps1` when a generated memory index exists.
   Use `scripts\plan-hermes-source-learning.ps1` to choose the upstream source
   folders for the task lane.
3. For addon layout, inspect openFrameworks `addons`, `apps`, `docs`,
   `examples`, `libs`, `scripts`, platform docs, and projectGenerator behavior.
4. For core tensor or backend design, inspect upstream `ggml` headers, source,
   tests, and examples.
5. For LLM behavior, inspect `llama.cpp` docs, GGUF/model loading code,
   backend integration, server/tool contracts, and API changelogs.
6. For speech/audio behavior, inspect `whisper.cpp` high-level model files,
   examples, quantization paths, and backend setup docs.
7. For diffusion image/video behavior, inspect `stable-diffusion.cpp` model
   docs, backend selection, conversion, sampling, quantization/GGUF, and CLI
   contracts.
8. Translate the lesson into an ofxGgml lane decision before editing: Core
   runtime, Workflows policy, or companion UX.

## Stop Conditions

Stop and write a handoff when:

- The upstream lesson implies changing Core and a companion addon together.
- The change would vendor upstream generated artifacts, model files, binaries,
  caches, or sample media.
- The upstream API, command-line option, backend behavior, or openFrameworks
  release layout changed recently and local Core/provider/addon docs have not
  been refreshed.
- Runtime support cannot be proven with local smoke or evidence scripts.
