# AI-Assisted Code Literacy

**Status:** Draft proposal; intended to evolve into a reusable Agent Skill.

## Proposal Context for AegisSovereignAI

Within AegisSovereignAI, this proposal applies the workflow to its
multi-language, security-sensitive code and legacy integrations. It enables
engineers to work safely in technologies they may not already know while
keeping language semantics, intended behavior, testing, and human approval
authoritative.

## Executive Summary

### Problem

AI can accelerate work on unfamiliar and legacy code, but it can also move from
partial understanding to confident analysis or modification too quickly.
Reusable instruction formats make procedural knowledge easier to package, but
packaging alone does not ensure that an agent establishes and verifies a
sufficient mental model before changing code. Undocumented intent, unfamiliar
language semantics, hidden dependencies, and limited test coverage amplify this
risk, creating **comprehension debt**: plausible changes made without a verified
understanding of the code's behavior, constraints, and risks.

### Solution

This document defines a bounded, phase-gated workflow for using AI on unfamiliar
code while keeping human engineering judgment in control. It applies to
inherited codebases, unfamiliar languages and frameworks, debugging, security
and performance reviews, modernization, incident investigation, cross-team
reviews, and coding exercises.

```text
1. UNDERSTAND
      │
      └── 1.1 DEEP MODEL [OPTIONAL]
      ↓
2. ANALYZE
      ↓
3. FIX
      ↓
4. VALIDATE
```

The workflow separates observed facts from inference, requires understanding
before modification, introduces deeper modeling only when warranted, favors
minimal changes, applies focused test-first proof to approved implementation
behavior changes where practical, and uses broader risk-driven functional
validation followed by a separate final diff review.

### Cross-Validation at a Glance

Cross-validation should match the claim being checked and the risk of getting
it wrong. Expertise and authority are different: experts validate technical or
domain claims, while an accountable human authorizes changes and accepts risk.

| Phase | Cross-validation question | Preferred validation |
| --- | --- | --- |
| Understand | Are the behavior and intended workflow represented correctly? | Domain or requirements expertise plus language, runtime, or toolchain expertise |
| Analyze | Is each finding technically real and materially important? | Language or framework expertise plus the relevant domain, security, data, or operations expertise |
| Fix | Is the expected behavior correct and the proposed scope authorized? | Accountable human owner, supported by codebase and language expertise |
| Validate | Does the combined evidence justify acceptance? | Executable checks plus independent domain, operational, or code review as relevant |

When appropriate expertise is unavailable, independent role-specific LLM
judges and deterministic tools may challenge the output and expose uncertainty.
They do not create missing requirements, accept organizational risk, or replace
authorization to modify code.

### What It Is Not Yet

This is an evolving standalone workflow and candidate source for a reusable
Agent Skill; it is not yet compact, packaged, or validated across
representative unfamiliar- and legacy-code tasks. Reaching that stage requires
progressive disclosure, supporting reference files, and practical evaluation.
It is not a substitute for human requirements, domain knowledge, engineering
judgment, or task-specific security and testing practices.

## Workflow Phase Summary

### 1. Understand

Establish what the program is intended to do: its inputs, outputs,
responsibilities, execution flow, and important state. Avoid proposing fixes
until the behavior and intent are clear.

### 1.1 Deep Model — Optional

When concurrency, ownership, framework behavior, state relationships, or trust
boundaries are non-obvious, build a more detailed execution and data model.
Skip this when the initial understanding is already sufficient.

### 2. Analyze

Review the code systematically for correctness, security, concurrency,
reliability, and performance issues. Prioritize findings so current, definite
defects are distinguished from conditional risks and assumptions.

### 3. Fix

Select only the issues worth addressing and propose the smallest safe change
before editing. After the plan is reviewed and explicitly approved, reuse or
add the focused test coverage needed to demonstrate the expected failure,
implement the smallest targeted change, and prove that the test passes.

### 4. Validate

Build broader, risk-driven functional confidence around the targeted change. Add
coverage only for material behaviors that are not already tested, run the
relevant suite, distinguish explicitly accepted known failures from unexpected
failures, and finish with a read-only review of the changes, tests, and
remaining risks.

Concise summary:

> I first establish intent and build a clear execution and state model. If
> concurrency or language semantics are complex, I deepen that model before
> reviewing the code. I then prioritize concrete findings, propose and
> implement the smallest justified changes with targeted test-first proof, then
> validate the bounded unit more broadly with functional tests and a final diff
> review.

Remember:

> **Understand → Analyze → Fix → Validate**

Use **1.1 Deep Model** only when more understanding is needed before analysis.

---

# Scope

## Granularity

This workflow is optimized for a **bounded, human-reviewable unit of code**, typically:

* a single file
* a small set of closely related files (one module, package, or class)
* one focused change set, diff, or pull request
* one service or trust boundary

It applies to production and non-production code alike, including prototypes,
sandboxes, coding exercises, migration utilities, tests, and operational tools.
Its rigor should be proportionate to the consequences of the change, but its
phase boundaries and evidence rules do not depend on deployment status.

In this document, **implementation code** means the code whose behavior is
being changed; it does not imply that the code is deployed to production.

It is deliberately **not** a whole-repository comprehension tool. For a large or unfamiliar repository, first narrow the scope: pick one entry point (an API route, a job, a CLI command, a failing test) and apply the workflow there. Widen only after the initial unit is understood.

The heavier structural elements (architecture diagrams in Phase 1A; multiple stores, queues, and trust boundaries in Phase 1.1) apply only when the unit in scope actually spans them. For a single self-contained file, keep the diagram small and usually skip Phase 1.1.

---

# Prior Art and Positioning

This document synthesizes established code-comprehension, review, and validation
practices into a phase-gated workflow with a human in control.

Related public work it draws on and complements:

* **Comprehension-first / "comprehension debt."** Recent work argues
  for understanding before generating and names the failure modes when you do
  not — black-box acceptance, context mismatch, dependency-induced atrophy, and
  verification bypass (Ahmad, *Comprehension Debt in GenAI-Assisted Software
  Engineering Projects*, arXiv:2604.13277). See [References](#references).
* **Agent Skills (open standard).** Anthropic's Agent Skills package procedural
  knowledge as a `SKILL.md` file with `name`/`description` frontmatter and
  progressive disclosure, now published as a cross-platform open standard
  (agentskills.io). This document is structured so it can later be packaged
  with compatible metadata and instructions. Follow "As an Agent Skill" below
  for the remaining packaging steps.
* **GitHub Copilot customizations.** The community `awesome-copilot` collection
  hosts equivalent instructions, prompts, and skills for Copilot — an
  established home and format for portable, shareable engineering workflows.
* **Classic engineering discipline.** The workflow restates durable practices in
  an AI context: understand a mechanism before removing it ("Chesterton's
  Fence"), and use characterization tests where needed to protect existing
  legacy behavior (Feathers, *Working Effectively with Legacy Code*).

What is distinctive here is the **combination**: a single, bounded-unit,
phase-gated loop (**Understand → optional Deep Model → Analyze → Fix →
Validate**) that forbids code changes during understanding and analysis, keeps
the human in control of phase progression and change authorization, and
separates observed fact from inference. It is a **meta-workflow**: it does not replace task-specific practices
(code review, refactoring, test generation, incident investigation, security
remediation) — it sequences them behind an understand-first discipline.

---

# How to Use

## As a Standalone Guide

Place this file in the repository, for example:

`AI_CODE_LITERACY.md`

Run one phase at a time:

> Read `AI_CODE_LITERACY.md` and execute Phase 1 against the current code. Stop after Phase 1.

Then explicitly request the next phase:

> Execute Phase 2.

Do not automatically run the full workflow unless explicitly requested.

## As an Agent Skill

To package this workflow as an Agent Skill, add the required `name` and
`description` frontmatter, name the entry point exactly `SKILL.md`, and place it
in a directory whose name matches the frontmatter `name`. For example:

`.github/skills/ai-assisted-code-literacy/SKILL.md`

The current all-in-one source exceeds the [Agent Skills recommendation](https://agentskills.io/specification#progressive-disclosure)
to keep `SKILL.md` below 500 lines. Before publishing it as an installable
skill, retain the operational core in `SKILL.md` and move detailed examples and
reference material into one-level-deep supporting files.

---

# Operating Principles

* Execute only the phase explicitly requested.
* Never advance automatically.
* Keep responses concise, concrete, and engineering-focused.
* Understand behavior before analyzing or modifying implementation.
* Do not modify code during Phases 1 and 2.
* Phase 1.1 is optional.
* Before modifying code in Phase 3, present the plan and stop at the Human
  Checkpoint. Only approval through that checkpoint authorizes Phase 3C.
* Prefer minimal, targeted changes.
* Preserve intended behavior and existing interfaces unless change is necessary.
* Reuse adequate existing tests. Add tests only when relevant coverage is
  missing or insufficient.
* Apply test-first development to every approved implementation behavior change
  where executable testing is practical. Identify or add the smallest
  behavior-oriented test for the human-approved expected outcome, confirm that
  it fails for the expected reason against the unchanged implementation, make
  the smallest change required to pass, and keep it green through any approved
  refactoring.
* If test-first development is impractical, document why, use the strongest
  executable reproduction available, and obtain human acceptance of the
  residual risk at the Phase 3 Human Checkpoint.
* Before completing Phase 3C, confirm that the targeted test or approved
  executable reproduction demonstrates the expected behavior after the change,
  and run the immediately relevant existing tests. Do not defer this first
  successful targeted proof to Phase 4.
* Add characterization tests only when untested surrounding behavior materially
  increases regression risk; do not encode a known defect as required behavior.
* Use Phase 4 for broader risk-driven functional validation and final review.
  Add tests only for material behavior not already covered.
* Treat a known failure as expected only when it is a confirmed defect with an
  explicitly accepted deferral and a traceable finding. Do not encode an
  unresolved requirement or assumption as a normative failing test.
* Distinguish:

  * observed facts
  * strong inferences
  * ambiguities
  * assumptions
  * potential concerns
* Do not treat every theoretical issue as a defect.
* Do not recommend a design pattern or programming paradigm merely as a stylistic preference.
* Explain unfamiliar language constructs only when they materially affect understanding.
* Use the human's familiar programming languages as comparison points where useful.
* Prefer existing project conventions, libraries, architecture, build tools, and testing frameworks.
* Avoid unrelated refactoring and speculative improvements.
* Do not assume AI-generated analysis or code is correct.
* The human retains control of requirements, priorities, tradeoffs, implementation scope, and acceptance.

---

# Cross-Validation and Assurance

Cross-validation is **risk-proportional**. The roles below need not be separate
people, and every bounded task does not require every specialty. Select the
reviewers and evidence that can validate the material claims in the current
phase. If a needed validator is unavailable, identify the resulting assurance
gap instead of silently treating the claim as confirmed.

Expertise and authority serve different purposes:

* **Expertise** helps establish whether a claim about the domain, language,
  runtime, codebase, or operational environment is sound.
* **Authority** determines intended behavior, approves implementation scope,
  and accepts residual risk. AI judges and technical experts can inform this
  decision but cannot assume it.

## Phase-Specific Cross-Validation

| Phase | What needs validation | Preferred reviewer or evidence |
| --- | --- | --- |
| Phase 1 — Understand | Business intent, terminology, expected workflow, and the plain-English model | Domain or requirements expert; authoritative policies, specifications, examples, or documented user-facing expectations |
| Phase 1 — Understand | Language semantics, dialect, runtime behavior, and interpretation of unfamiliar constructs | Language, runtime, or toolchain expert; official references, an existing build/run harness, or read-only compiler checks |
| Phase 1.1 — Deep Model | Architecture, data flow, state ownership, concurrency, external dependencies, and trust boundaries | Codebase maintainer, architect, operations, data, or security expert as relevant; architecture and deployment artifacts |
| Phase 2 — Analyze | Whether the suspected defect mechanism is technically real | Language or framework expert; reproducible evidence, focused experiments, static analysis, or existing tests |
| Phase 2 — Analyze | Whether the behavior is actually defective and how important it is | Domain, product, security, data, or operational owner as relevant; confirmed requirements and deployment context |
| Phase 3 — Fix | Expected behavior, acceptable change scope, priorities, and risk acceptance | Accountable human owner at the Human Checkpoint, supported by codebase and language expertise |
| Phases 3 and 4 | Patch correctness, focused-test adequacy, broader behavior, and residual risk | Executable tests and toolchain checks plus independent code, domain, security, or operational review as warranted |

A language expert is not a substitute for a domain expert: knowing the code's
current behavior does not establish what it should do. Likewise, a domain
expert may confirm intended behavior without being able to validate
language-specific mechanisms. When the stakes warrant it, use both.

## Match Evidence to the Claim

Prefer the evidence closest to the claim instead of treating all reviewers or
artifacts as interchangeable:

* Validate **intended behavior** against requirements, policies, contracts,
  examples, or an accountable domain owner.
* Validate **actual behavior** with executable tests, observations, fixtures,
  traces, and reproducible experiments.
* Validate **language and runtime semantics** with official references,
  compilers, analyzers, and relevant expertise.
* Validate **codebase and operational assumptions** with configuration,
  deployment artifacts, schemas, telemetry, and maintainers or operators.
* Validate **acceptance and residual risk** through the accountable human owner.

Passing tests prove only the behavior they exercise. Executable evidence
establishes observed behavior, not necessarily intended behavior. Expert or LLM
agreement does not turn an unsupported requirement into ground truth.
Investigate material conflicts, determine which claim each source can support,
and leave unresolved claims explicit.

## Automated Cross-Validation When Expertise Is Unavailable

Automation can extend review capacity, but it does not convert missing ground
truth into confirmation. Unless a separately defined and explicitly authorized
operating mode says otherwise, automated cross-validation may support every
phase but does **not** remove the Phase 3 Human Checkpoint.

Use the following risk-proportional arrangement:

1. Assemble the bounded code, available requirements, relevant documentation,
   build instructions, tests, and operational evidence into a common evidence
   set.
2. Produce the primary phase output from that evidence without concealing
   ambiguities or unsupported assumptions.
3. Use separate role-specific judges for the material dimensions—for example,
   domain interpretation, language semantics, engineering findings, security,
   and test adequacy. Do not ask only whether the primary answer "looks good."
4. Prefer independent model families where practical and conceal authorship of
   the primary output. Multiple judges with correlated blind spots are not
   independent ground truth.
5. Require each judge to cite exact evidence, identify counterexamples, attempt
   to falsify important claims, and state uncertainty. A score or majority vote
   alone is insufficient.
6. Run deterministic checks such as compilation, existing tests, focused
   experiments, static analysis, schema validation, and fixture comparisons
   wherever they can test the claim directly.
   Apply checks only within the current phase's execution and mutation
   boundaries. During Phases 1 and 2, do not modify repository files or
   deployable artifacts; use an isolated temporary work area when a check must
   generate files, and assess side effects before running unfamiliar code.
7. Reconcile disagreements against the underlying evidence. If the evidence
   cannot resolve them, report the disagreement and reduce confidence rather
   than forcing consensus.
8. Stop or fail closed when unresolved uncertainty could materially affect
   security, privacy, compliance, money, data integrity, irreversible behavior,
   or an important external interface.
9. Preserve the Human Checkpoint before modifying implementation code. AI judges
   may recommend approval but cannot grant it or accept organizational risk.

For material claims, especially when expertise is limited, include a compact
assurance status in the phase output:

```text
Cross-validation:
- Domain intent: CONFIRMED — access policy section 4.2
- Language semantics: EVIDENCE-CHECKED — compiler and official reference
- Operational assumptions: UNVERIFIED — deployment details unavailable
- Human authorization: NOT YET GRANTED
```

Use the status to expose the basis and limits of confidence, not as a ceremonial
checklist. A fully unattended workflow would require a separate, explicitly
selected operating mode, a pre-authorized risk envelope, and safeguards
appropriate to its impact; it is outside the current workflow and is not the
default fallback for missing expertise.

---

# Phase 1 — UNDERSTAND

## Objective

Build a clear, mostly language-independent mental model of the code that a
reader can consume without prior familiarity with the language, dialect, or
framework.

Start with the story, then show the picture.

## Phase 1A — Plain-English Flow and High-Level Picture

### Plain-English End-to-End Flow

Begin with 4–8 numbered, language-independent steps describing what happens
from external input to externally visible output. Include major decisions and
state changes, but do not produce a line-by-line walkthrough.

Give this scenario a concise, plain-language domain name followed by
`— End-to-End Flow`. Do not name the overall scenario after a function or
present it as though it were a function.

For a simple unit, this flow may replace the primary execution or scenario-flow
diagram when both would communicate the same sequence.

After the steps, use concise, self-explanatory pictures. When multiple
meaningful functions participate in the behavior, separate the picture into
two views rather than combining responsibilities, state interactions, and
execution order in one crowded diagram:

1. **Function responsibilities and state interactions**

   Describe each important function independently. Show its main input, reads,
   writes, important decision, and output. Omit trivial helpers and
   implementation detail.

2. **Primary execution or scenario flow**

   Show how those functions compose during the main execution path, including
   the important state changes and externally visible outputs. Begin with the
   relevant external inputs, hard-coded inputs, and configuration. Label values
   passed between major steps when they materially explain the behavior, and end
   with the program's externally visible outputs. Do not repeat every function
   argument or return value when it would add clutter without improving the
   mental model. Omit this picture when it would only repeat the plain-English
   end-to-end flow.

A single combined picture is acceptable when the code is simple enough that the
two views would merely duplicate each other.

Show where applicable:

* main inputs
* outputs
* major logical operations
* important function boundaries
* important state
* storage
* caches or queues
* external services
* important reads and writes
* major state changes
* primary execution path

Use meaningful names from the code.

Label responsibilities in plain-language domain terms rather than relying on
implementation identifiers alone. Clearly distinguish each responsibility from
the exact implementation identifier that performs it. For legacy or unfamiliar
code, prefer a secondary label such as:

```text
Source unit: CHECKA (subroutine)
```

`Source unit` may identify a program, module, class, function, method,
subroutine, or similar construct. A short parenthetical identifier is acceptable
when the language and identifier are already familiar. Do not rename the code
during this phase.

Prefer:

```text
Is the high-risk action approved?
Source unit: approve_high_risk_action (function)
```

over:

```text
approve_high_risk_action(token)
```

Prefer:

```text
User Store
Session Store
User Cache
Identity Provider
Payment Service
```

over generic labels such as:

```text
State
Storage
Logic
Service
```

Example function view:

```text
Create a session
(createSession)
  create token + TTL → write Session Store → return token

Authenticate a session
(authenticate)
  read Session Store → reject missing/expired → getUser(user)

Retrieve a user
(getUser)
  read User Cache
    ├─ hit  → return cached user
    └─ miss → read User Store → populate cache → return result
```

Example primary flow:

```text
Inputs / configuration
  user
  session TTL
    ↓
Create session (createSession) ──write──▶ Session Store
    ↓ output: token
Authenticate session (authenticate) ───read───▶ Session Store
    ↓ validated user ID
Retrieve user (getUser) ──────────read──▶ User Cache / User Store
    ↓ output: authenticated user
Program output
  authenticated user
```

Someone should be able to understand the basic story from the steps and
pictures without reading the implementation.

Do not create a detailed line-by-line flowchart.

---

## Phase 1B — Explain Intent

Summarize in language-independent terms:

* what the code appears intended to do
* inputs and outputs
* major operations
* key data
* important state
* where state lives
* persistent versus temporary data
* external services, APIs, or libraries
* likely expected behavior
* apparent requirements
* important assumptions

Focus on behavior rather than syntax.

Define domain-specific terms and acronyms on first use when they materially
affect understanding. State whether each meaning is established by code or
requirements, or merely inferred from names and context. Do not assign a
stronger meaning than the available evidence supports.

---

## Phase 1C — Explain Unfamiliar Constructs Only When Needed

Assume the reader may have zero familiarity with the language. If an unfamiliar
construct is necessary to understand the program, explain it briefly in context
and in plain language. Introduce syntax only after explaining the behavior it
implements.

Do not provide a general language tutorial.

When the language, dialect, or toolchain is obsolete or outside your confident
knowledge, say so explicitly. Verify unfamiliar idioms against a language
reference, an existing build or run harness, or a read-only compiler check
rather than relying on memory. If a new harness is needed, propose it for a
later approved phase; do not create it during Phase 1 or 2. Do not assume a
legacy idiom is a defect — some, such as fixed-point decimal for money, are
deliberate and correct.

If the human's familiar languages are known, use them as comparison points where useful.

Otherwise, ask for familiar languages only when such a comparison would materially help.

Focus especially on semantics involving:

* control flow
* async/concurrency
* shared mutation
* values versus references
* error handling
* resource lifetime

Example:

> `await` suspends this async function until the asynchronous operation completes. It does not necessarily block the runtime thread.

---

## Phase 1D — Ambiguities and Early Risk Flags

Call out only **obvious, high-confidence observations** noticed while understanding the code. Do not perform the full engineering review yet — that is Phase 2.

Watch especially for:

* **Security** — authentication without authorization; roles or permissions modeled but not enforced; mishandled credentials, secrets, or tokens; sensitive data crossing an unexpected boundary.
* **Data and state consistency** — cache and authoritative store can diverge; a mutation leaves dependent state stale; multiple sources of truth; deleted objects with live references.
* **Reliability and lifecycle** — expired objects never cleaned up; resources with no visible lifecycle; unbounded state growth; obviously absent failure handling.
* **Performance and scalability** — only readily visible issues (repeated expensive work, unnecessary blocking, unbounded collections, duplicate I/O). Do not invent scalability issues without evidence.
* **Design and architecture** — data models a concept the behavior ignores; responsibilities conflict with apparent requirements; unclear ownership or authority; coupling that creates a concrete correctness or lifecycle problem.
* **Claims that live elsewhere** — a behavior or invariant that actually depends on another file, process, or a replaced/ported implementation (for example a comment asserting what a different component caches or enforces). Verify it against that artifact rather than trusting the comment.

Name the **design pattern or paradigm** (procedural, object-oriented, functional, event-driven, layered, repository/service, ...) only when it improves understanding. Do not recommend changing paradigms merely because another style is possible.

The full dimension taxonomy for the systematic review is in Phase 2A.

---

## Phase 1E — Separate Fact From Interpretation

Use these categories where helpful.

### Observed Fact

Directly visible in the code.

> A `role` field exists, but the deletion path never checks it.

### Strong Inference

Strongly suggested by context.

> The artificial delay likely simulates a database or remote lookup.

### Ambiguity

Cannot be determined from available requirements.

> It is unclear whether ordinary users should be allowed to delete other users.

### Potential Concern

May matter depending on deployment assumptions.

> The token-generation mechanism may be unsuitable if the token protects a real security boundary.

---

## Phase 1F — Decide Whether Phase 1.1 Is Needed

End Phase 1 with one of:

```text
Deep Model Recommendation: SKIP PHASE 1.1
```

or:

```text
Deep Model Recommendation: RUN PHASE 1.1
```

Give one short reason.

Recommend **RUN PHASE 1.1** when deeper modeling would materially improve understanding because of:

* complex async/concurrency behavior
* non-obvious state relationships
* multiple stores or caches
* queues or event-driven flows
* multiple external systems
* unfamiliar language semantics
* complex ownership/reference behavior
* framework-heavy behavior
* unclear error propagation
* important trust boundaries
* unclear control/data flow

Recommend **SKIP PHASE 1.1** when Phase 1 already provides enough understanding to analyze the code confidently.

---

## Desired Outcome

The human should be able to answer:

> What does this code do?

> What talks to what?

> Where does important state live?

> What assumptions or obvious inconsistencies exist?

> Do I understand it well enough to analyze it?

**Do not modify code.**

---

# Phase 1.1 — DEEP MODEL [OPTIONAL]

## Objective

Deepen the understanding from Phase 1 when the system is too complex, unfamiliar, or ambiguous to analyze confidently.

Skip this phase when Phase 1 is sufficient.

---

## Phase 1.1A — Detailed Execution Model

Create a concise control-flow and data-flow diagram showing where relevant:

* function or method calls
* decision points
* loops
* asynchronous or concurrent work
* callbacks or event handlers
* reads and writes
* state transitions
* external calls
* error paths
* retries
* timeouts
* cancellation

Example:

```text
Request
   │
   ▼
Validate
   │
   ├── invalid ───────────────▶ Error
   │
   ▼
Load Session ────────────────▶ Session Store
   │
   ▼
Authorize
   │
   ├── denied ────────────────▶ Forbidden
   │
   ▼
Load User
   │
   ├── cache hit ─────────────▶ User Cache
   │
   └── cache miss
            │
            ▼
        User Store
            │
            └───────────────▶ populate cache
   │
   ▼
Perform Operation
   │
   ▼
Persist / Return
```

---

## Phase 1.1B — Detailed Data Model

Explain:

* important structures, classes, or types
* what each represents
* relationships between them
* mutable versus immutable state
* authoritative state
* cached or derived state
* identifiers and keys
* ownership
* lifetime
* persistence boundaries

Example:

```text
User
 ├── id
 ├── role
 └── profile

Session
 ├── token
 ├── userId ───────────────▶ User.id
 └── expiresAt

Cache
 └── userId ───────────────▶ User
```

---

## Phase 1.1C — Identify Invariants

Identify conditions that should always remain true.

Examples:

```text
A valid session must reference an existing user.

A successful deletion must remove the authoritative record.

A deleted user must not remain visible through cache.

Only authorized principals may perform privileged operations.
```

Separate:

* invariants enforced by code
* invariants assumed but not enforced
* apparently missing invariants

---

## Phase 1.1D — Map Important Language Semantics

Explain only language-specific behavior that materially affects reasoning about the program.

Consider:

* data structures
* type semantics
* values versus references
* ownership/borrowing
* closures
* async/await
* threads/tasks
* synchronization
* exceptions or explicit error values
* cancellation
* garbage collection
* resource cleanup
* module/package behavior
* framework conventions

Where useful, compare these with languages the human already knows.

Example:

```text
Logical Concept          Current Language        Familiar Equivalent
─────────────────────    ───────────────────     ─────────────────────
Lookup value             Map.get()               dictionary lookup
Concurrent task          goroutine               lightweight task
Wait for completion      WaitGroup               join/gather
Shared mutation          pointer/reference       shared object
Failure propagation      error return            exception/status
```

Focus on semantic differences that could otherwise lead to incorrect conclusions.

---

## Phase 1.1E — Trust and Process Boundaries

When relevant, identify:

* untrusted callers
* API boundaries
* authentication boundaries
* authorization boundaries
* process or service boundaries
* databases
* privileged components
* external providers

Example:

```text
Untrusted Client
      │
      ▼
┌─────────────────┐
│ API Boundary    │
└───────┬─────────┘
        ▼
 Authentication
        │
        ▼
 Authorization
        │
        ▼
 Internal State ─────────▶ Database
```

---

## Desired Outcome

The human should understand:

> how control moves

> how important data moves and changes

> what must remain true

> where trust boundaries exist

> which language semantics materially affect behavior

**Do not modify code.**

---

# Phase 2 — ANALYZE

## Objective

Perform the systematic engineering review and produce **prioritized findings**.

Unlike Phase 1, actively search for defects and risks.

---

## Phase 2A — Analyze Across Relevant Dimensions

### Correctness

* incorrect results
* violated invariants
* state-transition bugs
* ordering problems
* logical errors

### Edge Cases

* empty or missing inputs
* boundary values
* duplicates
* overflow/underflow
* partial state
* unexpected ordering

### Error Handling

* ignored errors
* swallowed exceptions
* incorrect retries
* missing timeouts
* partial failures
* incorrect recovery

### Concurrency

* races
* deadlocks
* lost updates
* unsafe shared mutation
* ordering problems
* cancellation issues
* async lifecycle bugs

### Security

* authentication
* authorization
* access control
* input validation
* injection
* credentials and secrets
* tokens
* cryptography
* sensitive-data exposure
* privilege boundaries
* trust assumptions

### Performance and Scalability

* algorithmic complexity
* repeated I/O
* N+1 access patterns
* unnecessary blocking
* memory growth
* unnecessary allocations
* cache behavior
* hot-path inefficiencies

### Reliability

* retries
* timeouts
* cleanup
* partial writes
* inconsistent state
* resource exhaustion
* failure assumptions

### Maintainability and Design

* unnecessary complexity
* hidden coupling
* unclear ownership
* duplicated logic
* inappropriate abstractions
* mismatch between implementation and requirements

---

## Phase 2B — Prioritize Before Detailing

Start the output with a concise **prioritized findings summary**.

Use this compact summary shape so the reasoning behind each priority is visible:

```text
Priority | Finding | Severity | Current Applicability | Certainty
```

Keep the cells short. Put detailed evidence, triggers, consequences, and
mitigations in the finding details rather than expanding the summary table.

Prioritization should consider:

* impact/severity
* certainty
* applicability to the current system
* likelihood or trigger conditions
* whether required behavior is affected now

Use:

```text
P0 — Must address now; blocks required correctness or safety
P1 — Should address in the current scope
P2 — Conditional; validate requirements or deployment assumptions
P3 — Follow-up or hardening
```

Priority is the final action decision informed by severity, current
applicability, likelihood, certainty, and urgency. It is not a direct severity
scale:

```text
Severity              = how damaging the issue is if triggered
Current applicability = whether its trigger conditions exist in this system now
Certainty             = confidence that the finding and its interpretation are correct
Priority              = when the issue should be addressed after considering these factors
```

Do not force a finding into every priority level. It is valid to have no P0
findings. Do not equate theoretical severity with implementation priority.

For example, a potentially HIGH-severity issue may still be **P2** if it depends on an unconfirmed deployment assumption.

---

## Phase 2C — Detail Each Finding

For each meaningful finding provide:

* priority
* category
* finding
* evidence or code path
* trigger
* consequence
* root cause
* severity
* certainty
* smallest reasonable mitigation

Certainty:

```text
DEFINITE BUG
LIKELY ISSUE
POTENTIAL CONCERN
ASSUMPTION TO VALIDATE
```

Severity where useful:

```text
CRITICAL
HIGH
MEDIUM
LOW
INFORMATIONAL
```

Do not exaggerate severity.

---

## Phase 2D — Challenge the Analysis

Explicitly identify:

* findings dependent on unknown requirements
* issues that matter only at particular scale
* assumptions requiring confirmation
* technically valid concerns that are not worth fixing now
* findings whose priority would change under different deployment assumptions

The goal is a **prioritized engineering assessment**, not a generic checklist.

---

## Desired Outcome

The human should know:

> What actually matters?

> Which findings are real versus conditional?

> What should be fixed first?

> What assumptions must be validated before acting?

**Do not modify code.**

---

# Phase 3 — FIX

## Objective

Fix only the issues worth addressing.

Any instruction that refers only to Phase 3—including run, do, execute,
implement, or complete—means completing Phase 3A and Phase 3B, presenting the
proposed fix plan, and stopping at the Human Checkpoint. Only approval through
that checkpoint authorizes adding tests, modifying implementation code, or
entering Phase 3C.

---

## Phase 3A — Select Scope

Start from the prioritized Phase 2 findings.

Group the selected work into:

### Must Fix

Material correctness, security, or required-behavior issues.

### Should Fix

Important issues worth addressing if scope permits.

### Optional Follow-Up

Useful improvements outside the minimal change.

Do not automatically fix every Phase 2 finding.

Use the Phase 2 priority as an input, not a mechanical mapping:

* **P0** normally enters Must Fix.
* **P1** normally enters Must Fix or Should Fix, depending on scope and impact.
* **P2** remains conditional until its requirement or deployment assumption is
  resolved; only then place it in Must Fix or Should Fix when warranted.
* **P3** normally remains Optional Follow-Up unless new evidence raises its
  priority.

---

## Phase 3B — Propose the Minimal Plan

Before changing code, propose the smallest reasonable patch.

For every proposed implementation behavior change, first determine whether an
existing focused test adequately expresses the expected outcome. Reuse it when
it does. If relevant coverage is missing or insufficient, include the smallest
behavior-oriented test as the first item in the proposed change. Use a
**regression test** for a defect and an equally focused behavior test for new
behavior. A newly needed test is part of the change, but do not add it before
approval. Plan to run the identified or newly added test against the unchanged
implementation and confirm that it fails for the expected reason before
modifying implementation code.

When proposing a new test, state the coverage gap explicitly:

> Existing tests do not adequately cover [behavior]. Therefore, this plan adds
> [test] to prove [expected outcome].

Do not say only that a test will be added; identify what was checked and why the
existing coverage is missing or insufficient.

Add **characterization tests** only when untested surrounding behavior
materially increases the risk of an unintended regression. Use them to protect
behavior that should remain unchanged, not to encode the known defect as
required behavior.

If intended behavior is unresolved, stop for a human decision before writing a
normative test. If test-first development is impractical, explain why, propose
the strongest executable reproduction available, and include the residual risk
in the Human Checkpoint decision.

For each change explain:

* what changes
* why
* finding addressed
* externally visible behavior impact
* interface impact
* tradeoffs
* new risks

Prefer:

* small diffs
* existing abstractions
* existing APIs
* project conventions
* idiomatic language constructs

Avoid:

* opportunistic refactoring
* broad rewrites
* unnecessary dependencies
* speculative abstractions

**Stop before implementation.**

---

## Human Checkpoint

The human may:

* approve
* reject
* reprioritize
* narrow
* expand
* modify

the plan.

The assistant must initiate the approval interaction by asking the direct Y/N
question below. Do not tell the human to issue a separate approval command or
prompt. After asking the question, end the response and wait for the answer.

An explicit `Y` from the authorized human owner authorizes Phase 3C. `N`, any
other answer, or a requested revision does not.

End every Phase 3 proposal with the following hard-stop gate, adapted to state
any unresolved expected behavior. When the plan uses the test-first exception,
adapt the Y/N question to ask the human to accept the stated residual testing
risk explicitly. The gate must be the final content in the response:

> **HARD STOP — HUMAN APPROVAL REQUIRED**
>
> Do not call tools, modify files, or begin Phase 3C while waiting for the
> answer.
>
> **Do you approve [expected behavior], the proposed test or reproduction, and
> the implementation changes? Answer Y or N.**

---

## Phase 3C — Incorporate Approved Changes

After explicit approval to incorporate the proposed changes:

* reuse the adequate focused test, or add it if approved coverage is missing or
  insufficient; run it against the unchanged implementation and confirm it
  fails for the expected reason rather than because of test or environment
  problems
* before adding an approved test, state that existing coverage was checked,
  name the missing or insufficient behavior, and say that the test is being
  added for that reason
* if the approved plan includes risk-justified characterization coverage, reuse
  adequate existing tests and add only the missing tests; run them against the
  unchanged implementation to establish the surrounding behavior that must be
  preserved
* when the approved plan uses an executable reproduction instead of a test,
  capture its unchanged-implementation result as the before-change baseline
* if the focused test passes unexpectedly, fails for a different reason, or the
  agreed test or reproduction cannot run, investigate and report the blocker or
  changed assumption before modifying implementation code
* implement only agreed changes
* rerun the focused test or executable reproduction after the implementation
  change and confirm the approved outcome
* run the immediately relevant existing tests, including any approved
  characterization tests; confirm that ordinary tests pass and any pre-existing
  accepted expected failures remain explicit and occur for their documented
  reasons
* if the targeted proof or another relevant test fails, diagnose and report it;
  do not claim the change is incorporated or broaden the implementation change
  without renewed human approval
* keep the patch minimal
* preserve interfaces where reasonable
* preserve intended behavior unless change is required
* follow project conventions
* avoid unrelated changes

Then summarize:

* what changed
* why
* findings addressed
* behavior changed
* assumptions retained
* tests reused and tests added, described by the behavior each proves
* before-change and after-change test or reproduction results

---

## Desired Outcome

Maintain this control loop:

```text
AI understands
     ↓
AI analyzes
     ↓
AI proposes
     ↓
Human decides
     ↓
AI implements
     ↓
Targeted proof passes
```

---

# Phase 4 — VALIDATE

## Objective

Build broader confidence in the bounded unit around the targeted proof completed
in Phase 3, then review the combined implementation, tests, behavior changes,
and remaining risks.

---

## Phase 4A — Select the Highest-Value Functional Behaviors

Identify the externally visible or operational behaviors most important to
validate across the bounded unit.

Build on the now-passing targeted test—or the successful executable reproduction
approved when test-first development was impractical—and any optional
characterization baseline established in Phase 3C. Do not repeat Phase 3's
targeted proof as though it were new validation.

Consider:

* happy path
* boundary conditions
* invalid input
* failure paths
* regressions
* state transitions
* authorization
* authentication
* cache consistency
* concurrency
* security-sensitive behavior
* resource cleanup
* dependency failures
* timeout/retry behavior

Select a functional set broad enough to cover material behavior around the
change while remaining proportionate to the bounded scope. Prefer
**risk-driven tests** over maximizing test count or coverage percentage.

---

## Phase 4B — Add Missing Functional Coverage

Use the project's existing testing framework.

Reuse existing tests first. Add focused functional tests only when Phase 4A
identifies a material behavior that is not already covered. A small, well-tested
change may require no new Phase 4 tests.

Before adding a test, state the coverage gap explicitly:

> Existing tests do not adequately cover [behavior or risk]. Therefore, Phase 4
> adds [test] to validate it.

Do not add tests without recording this reason. If existing coverage is
adequate, reuse it and state that no new test is needed for that behavior.

Where relevant, the functional set should cover:

* the primary successful flow
* important boundaries adjacent to the change
* important invalid-input or failure paths
* the behavior intentionally changed
* important behavior that must remain unchanged

Tests should be:

* deterministic
* focused
* readable
* behavior-oriented
* independent where practical

Avoid excessive mocking when real behavior can reasonably be tested.

Do not create a failing test merely because a P2 or P3 finding remains open:

* If the intended behavior is unresolved, keep it as an assumption or question;
  do not encode a normative expected result.
* If a defect is confirmed but deliberately deferred, use the test framework's
  explicit expected-failure mechanism only when the human has accepted the
  deferral. Link the expected failure to its finding, state the expected reason,
  and make an unexpected pass visible when the framework supports strict
  expected failures.
* Do not weaken assertions, skip broad groups of tests, or silently treat an
  ordinary failure as expected.

---

## Phase 4C — Run and Diagnose

Run the Phase 4 functional set and the relevant existing suite.

The acceptance state is:

* all ordinary tests pass
* only explicitly registered and human-accepted expected failures remain
* every expected failure still occurs for its documented reason
* no unexpected test failures remain

For every failure:

1. state what failed
2. identify the likely root cause
3. determine whether the problem is in:

   * implementation code
   * test code
   * inferred requirements
   * environment
4. propose the smallest correction

Treat an unexpected pass of a deferred-defect test as a result to investigate:
the defect may have been fixed, the trigger may no longer be exercised, or the
test may be stale.

Do not alter implementation behavior simply to satisfy a faulty test.

If validation reveals that implementation code needs another change, return to a
Phase 3 proposal and Human Checkpoint rather than modifying it within Phase 4.

---

## Phase 4D — Final Diff Review

Review the resulting diff **without modifying it**.

Apply extra skepticism to AI-generated implementation and test changes.

Check:

* correctness
* regressions
* unintended behavior changes
* security
* concurrency
* state consistency
* performance
* error handling
* resource lifecycle
* interface changes
* unnecessary complexity
* project conventions
* missing tests
* expected failures and their linked findings

Review together:

```text
Implementation changes
        +
Test changes
        +
Behavior changes
```

Classify remaining items as:

### Blockers

Should prevent acceptance.

### Important Follow-Ups

Worth addressing but not necessarily blocking.

### Assumptions

Could not be established from available information.

### Optional Improvements

Nonessential enhancements.

---

## Phase 4 Output

Report the validation evidence in behavioral terms. Include:

* the targeted test or approved executable reproduction from Phase 3, plus
  other relevant tests reused from the existing suite
* any functional or boundary tests added in Phase 4 because coverage was
  missing or insufficient
* the behavior or risk each reused or added test covers
* ordinary passes, accepted expected failures, and unexpected failures
* important behaviors not tested and the reason they remain uncovered

Do not report only test filenames or imply exhaustive coverage. If existing
tests already provide adequate risk-driven coverage, explicitly state that no
new Phase 4 tests were needed.

---

## Desired Outcome

Finish with a broadly tested and separately reviewed change set: targeted proof
demonstrates the approved behavior, ordinary functional tests pass, any accepted
expected failures are explicit and traceable, and remaining risks are visible.

---

# Mental Model

Keep the loop easy to remember:

> **Understand → Analyze → Fix → Validate**

And when understanding is insufficient:

> **Understand → Deep Model → Analyze → Fix → Validate**

---

# Typical Invocation

## Phase 1

> Execute Phase 1 against the current code for a reader with no prior familiarity with its language or domain. Lead with a named, plain-English end-to-end flow, then map responsibilities to exact source units and show only useful state/interaction pictures. Define material domain terms, explain only the unfamiliar language constructs needed to understand behavior, and cover intent, state/storage, expected behavior, and obvious early risk/design flags. End by recommending whether Phase 1.1 is useful. Do not modify files.

## Phase 1.1 — Optional

> Execute Phase 1.1. Build the deeper control/data model, identify invariants and trust boundaries, and explain unfamiliar language semantics that materially affect behavior. Do not modify files.

## Phase 2

> Execute Phase 2. Perform the full engineering analysis. Start with prioritized findings using P0–P3, then provide evidence, severity, certainty, root cause, and the smallest reasonable mitigation for each important finding. Do not modify files.

## Phase 3

> Execute Phase 3A and 3B only. Select the appropriate scope and propose the smallest reasonable implementation plan. Apply test-first development to each behavior change where practical: reuse an adequate focused test or add one when relevant coverage is missing or insufficient. If test-first proof is impractical, explain why, propose the strongest executable reproduction available, and expose the residual risk. Stop before modifying files. Ask the user the direct Y/N authorization question in the Phase 3 hard-stop gate, end the response, and wait for the answer; do not require a separate approval command.

After explicit approval:

> Incorporate the approved changes using Phase 3C and the agreed plan. Complete
> the targeted red-to-green test proof—or the approved executable
> reproduction when test-first proof is impractical—and run the immediately
> relevant existing tests before reporting the change as incorporated.

## Phase 4

> Execute Phase 4. Build broader, risk-driven functional confidence for the bounded unit. Reuse adequate existing coverage, add high-value tests only where coverage is missing or insufficient, run the relevant suite, distinguish explicit accepted expected failures from unexpected failures, diagnose results, and perform a final read-only diff review. Report which behavioral coverage was reused or added and identify material gaps. Return any newly required implementation change to Phase 3.

---

# Core Principle

AI accelerates:

* comprehension
* unfamiliar-language learning
* mental-model construction
* defect discovery
* implementation
* testing
* review

The human retains control of:

* intended behavior
* requirements
* assumptions
* risk interpretation
* prioritization
* tradeoffs
* implementation scope
* validation
* acceptance

**Understand first. Deep-model only when needed. Prioritize before fixing. Make
the smallest justified change. Validate in a separate skeptical pass.**

---

# References

* Anthropic. "Equipping agents for the real world with Agent Skills." 2025. <https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills>
* Agent Skills — open standard and format specification for cross-platform skills. <https://agentskills.io/specification>
* Anthropic. Agent Skills examples (`SKILL.md` format; many are Apache-2.0, while some document skills use separate source-available terms). <https://github.com/anthropics/skills>
* GitHub. "Awesome GitHub Copilot" — community instructions, prompts, and skills. <https://github.com/github/awesome-copilot>
* M. O. Ahmad. "Comprehension Debt in GenAI-Assisted Software Engineering Projects." arXiv:2604.13277, 2026. <https://arxiv.org/abs/2604.13277>
* IBM. "What is legacy code?" Published 2025; updated 2026. <https://www.ibm.com/think/topics/legacy-code>
* NIST. "AI Risk Management Framework Core" — human oversight, domain expertise, independent assessment, and testing, evaluation, verification, and validation. <https://airc.nist.gov/airmf-resources/airmf/5-sec-core/>
* OpenAI. "How evals drive the next chapter in AI for businesses" — expert-defined evaluation criteria, LLM graders, and continuing human audit. <https://openai.com/index/evals-drive-next-chapter-of-ai/>
* L. Shi et al. "Judging the Judges: A Systematic Study of Position Bias in LLM-as-a-Judge." arXiv:2406.07791, 2024. <https://arxiv.org/abs/2406.07791>
* G. K. Chesterton. *The Thing* (1929) — origin of "Chesterton's Fence": understand why a mechanism exists before removing it.
* M. Feathers. *Working Effectively with Legacy Code.* Prentice Hall, 2004 — characterization tests for pinning existing behavior before change.

---

# License

`SPDX-License-Identifier: Apache-2.0`

This is a short license notice, not the complete Apache License text. Include a
full `LICENSE` file before distributing this material as an open-source package.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at <https://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
