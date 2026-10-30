# claude-ui-craft

A small kit that makes Claude Code produce consistent, self-explanatory UI in a project
**without re-describing the look in every prompt**. It moves design knowledge out of chat and
into files the agent loads automatically.

Everything runs inside Claude Code. No Figma, no Storybook, no external service.

## The four layers

| Layer | File(s) | What it does |
| --- | --- | --- |
| Design document | `<ui-dir>/DESIGN.md` | The project's visual contract: direction, token meanings, type and spacing scale, primitives and when to use them, required panel states, copy rules, anti-patterns. Written once per project, read by the agent on every UI task. |
| Skill | `.claude/skills/ui-craft/` | The method. Read `DESIGN.md` first (or derive one when absent), commit to a direction before coding, compose from existing primitives and tokens, cover every required state, verify visually. Project-agnostic. |
| Verification command | `.claude/commands/ui-check.md` | `/ui-check <surface>`: render the changed surface in light and dark, screenshot it, check it against `DESIGN.md`, run the visual and contrast tests, report pass/fail with evidence. |
| Reminder hook | `.claude/hooks/ui-reminder.sh` + `.claude/settings.json` | After the agent edits a UI source file, a one-line reminder to run `/ui-check` is fed back to it. Nothing heavy runs in the hook. |
| Audit command | `.claude/commands/ui-audit.md` | `/ui-audit`: inventory every surface, render each in light and dark, score ten heuristics with evidence, write a ranked improvement proposal to `docs/ui-audit-<date>.md`. Changes no code; each proposal becomes its own change. |

Plus two optional tests that keep the document honest: `designDoc.test.ts` (every CSS token is
documented and every documented token exists) and `contrast.test.ts` (token pairs meet WCAG AA).

## The one command

Once per machine, link the user-level command (already done on this machine):

```sh
ln -sf ~/Documents/claude-ui-craft/user-command/ui-craft-init.md ~/.claude/commands/ui-craft-init.md
```

Then, in any project, open Claude Code and run:

```
/ui-craft-init
```

It finds the UI folder, runs `install.sh`, writes `DESIGN.md` from the existing UI (or a brief)
and asks you to confirm the direction, fits the token tests to the project, adds the CLAUDE.md
bullets, runs a first `/ui-check`, and lists the files to commit.

**Colleagues do nothing.** Everything is installed inside the project (`.claude/` and the UI
folder) and committed, so they get the skill, `/ui-check`, `/ui-audit` and the hook on their next
pull. Claude Code asks each of them once to trust the project's hooks. Only the person who
incorporates the kit needs this folder.

The manual steps below are what the command automates.

## Integrate into an existing project by hand

1. Run the installer from this folder:

   ```sh
   ./install.sh /path/to/project frontend
   ```

   The second argument is the UI directory relative to the project root (`frontend`, `web`,
   `client`, or `.` when the UI is the whole repo). Default: `frontend`.

   The installer copies the skill, the command and the hook script into `.claude/`, adds the
   hook to `.claude/settings.json` (creating the file, or appending to existing hooks; it never
   removes anything), and writes `<ui-dir>/DESIGN.md` from the template **only if none exists**.

2. Fill `DESIGN.md`. Open Claude Code in the project and say:

   > Use the ui-craft skill to write DESIGN.md from the existing stylesheet and components.

   The agent reads your tokens and components, drafts the document, and asks you to confirm the
   direction. Edit until it describes the UI you actually want. Keep the token table complete.

3. Add two bullets to the UI folder's `CLAUDE.md` (or the root one). The text is in
   `templates/frontend-CLAUDE.section.md`.

4. Optional but recommended: copy `templates/designDoc.test.ts` and `templates/contrast.test.ts`
   into the UI source folder and adjust the two path constants at the top. They run with Vitest.
   If you want screenshot tests, copy `templates/vitest.visual.config.ts` and
   `templates/Example.visual.tsx`, install `@vitest/browser-playwright` and `playwright`, and
   add `"test:visual": "vitest run --config vitest.visual.config.ts"` to `package.json`.
   Commit the `__screenshots__/` references; ignore `.vitest/` (diff attachments) in git.

5. Try it: edit any component, notice the reminder, run `/ui-check <component name>`.

6. For an existing app, run `/ui-audit` once. It scores every surface and writes a ranked list
   of improvements; pick the top items and implement each as its own change.

## Integrate into a new project

1. Scaffold the app (Vite, Next, whatever you use) and install the kit as above.
2. In Claude Code, give a one-paragraph brief (what the product is, who uses it, what it must
   feel like) and say:

   > Use the ui-craft skill to write DESIGN.md from this brief, then build the first screen.

   The skill makes the agent commit to palette, type, layout and principles **before** writing
   components, and asks you to confirm. That confirmation is the one iteration that replaces
   dozens of corrective prompts later.
3. Put tokens where `DESIGN.md` says they live (CSS variables are the simplest), add the two
   tests, and from then on every screen inherits the system.

## Update an installed copy

Re-run `./install.sh /path/to/project <ui-dir>` and commit the result. It overwrites the skill, command and hook with
the kit's versions, leaves `settings.json` entries and `DESIGN.md` alone, and is safe to run any
number of times. This folder is the source of truth; edit the kit here, then re-install.

## How the hook works

`settings.json` registers a `PostToolUse` hook on `Edit|Write|MultiEdit`. The script reads the
tool payload from stdin, extracts `file_path`, and only when the path is under the UI directory
and ends in `.tsx`, `.jsx` or `.css` it returns a JSON `additionalContext` reminding the agent to
run `/ui-check` before finishing. It exits 0 in every case and runs in milliseconds. Uses `jq`
when available, a `sed` fallback otherwise.

## Layout

```
claude-ui-craft/
  README.md
  install.sh
  user-command/ui-craft-init.md
  skills/ui-craft/SKILL.md
  skills/ui-craft/references/design-md-template.md
  skills/ui-craft/references/states-checklist.md
  skills/ui-craft/references/verify-loop.md
  skills/ui-craft/references/audit-heuristics.md
  commands/ui-check.md
  commands/ui-audit.md
  hooks/ui-reminder.sh
  hooks/settings.hooks.json
  templates/DESIGN.template.md
  templates/frontend-CLAUDE.section.md
  templates/designDoc.test.ts
  templates/contrast.test.ts
  templates/vitest.visual.config.ts
  templates/Example.visual.tsx
```

## Works with

- Anthropic's `frontend-design` skill (direction and taste for new designs). `ui-craft` defers
  to it when a project has no direction yet and never repeats its content.
- The `dataviz` skill for charts.
- `/run` and Claude in Chrome for driving the live app when no Playwright harness exists.
