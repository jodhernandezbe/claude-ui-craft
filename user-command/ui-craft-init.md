---
description: Incorporate the ui-craft design workflow into the current project (skill, commands, hook, DESIGN.md, tests), committed so every colleague gets it by cloning
argument-hint: [ui-dir, default auto-detected]
---

Incorporate the ui-craft kit from `~/Documents/claude-ui-craft` into the project in the current
working directory. Everything lands inside the project and is meant to be committed, so
colleagues need to do nothing. Work through these steps in order and stop only where a step says
to ask.

1. **Resolve the project root first.** Run `git rev-parse --show-toplevel`. That path is the
   project root and is the **first argument** to the installer, whatever directory you are
   standing in. `.claude/` always belongs at the root, so Claude Code finds it from anywhere in
   the repository. If this is not a git repository, use the directory holding the top-level
   manifest and say which you chose.

2. **Find the UI directory, expressed relative to that root.** Use `$ARGUMENTS` if given,
   normalised to a root-relative path: strip any leading `./`, and convert an absolute path or
   one relative to the current directory. A nested layout such as `ui/frontend` is normal and is
   passed whole as the second argument. Otherwise look for the folder holding the web UI's
   `package.json` and its main stylesheet, searching more than one level down (`frontend/`,
   `web/`, `client/`, `app/`, `ui/frontend/`, or `.` when the UI is the whole repository). If
   there is no web UI, say so and stop.

3. **Run the installer**: `~/Documents/claude-ui-craft/install.sh "<project-root>" "<ui-dir>"`,
   using the root from step 1, never the UI folder and never a bare `$PWD` you have not checked.
   The installer refuses a root that is a subdirectory of the repository and prints the correct
   command; if you see that error, re-read step 1 rather than working around it. It copies the
   skill, `/ui-check`, `/ui-audit` and the reminder hook into `.claude/`, registers the hook in
   `.claude/settings.json` without removing existing hooks, scaffolds `<ui-dir>/DESIGN.md` only
   if absent, and copies the two token tests only if absent. Report what it printed.

4. **Write DESIGN.md** with the `ui-craft` skill, if the file is still the scaffold. Existing UI:
   describe what the stylesheet and shared components actually do, list inconsistencies under
   "Known drift", never restyle. No UI yet: ask for a one-paragraph brief and use the
   `frontend-design` skill for direction. Either way, show the Direction and Tokens sections and
   **ask the user to confirm** before going on.

5. **Make the tests fit this project.** In `designDoc.test.ts` and `contrast.test.ts` set the
   stylesheet path and the dark-theme marker to this project's, and set the contrast pairs to the
   text and surface tokens that really exist. If tokens are not CSS variables, adapt the parsing
   or remove the test and say why. Run the UI package's test command; both must pass.

6. **Point the folder rules at it.** Add the two bullets from
   `~/Documents/claude-ui-craft/templates/frontend-CLAUDE.section.md` to `<ui-dir>/CLAUDE.md`
   (create it if missing), or to the root `CLAUDE.md` when the UI is the whole repo. Respect any
   line limit the project enforces on its CLAUDE.md files.

7. **Prove it works.** Run `/ui-check` on one existing surface and show the table.

8. **Hand over.** List the files to commit (`.claude/skills/ui-craft/`, `.claude/commands/ui-check.md`,
   `.claude/commands/ui-audit.md`, `.claude/hooks/ui-reminder.sh`, `.claude/settings.json`,
   `<ui-dir>/DESIGN.md`, the two tests, the CLAUDE.md edit). Make sure screenshot references
   (`__screenshots__/`) are not ignored and `.vitest/` is. Do not commit unless the user asks.
   Mention that colleagues get everything on their next pull; Claude Code asks each of them once
   to trust the project's hooks.
