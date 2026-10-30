<!-- Add these two bullets to the UI folder's CLAUDE.md (or the root CLAUDE.md). Adjust paths. -->

- `DESIGN.md` in this folder is the design authority: direction, token meanings, scale,
  primitives, required states, copy and anti-patterns. Use the `ui-craft` skill for any UI work;
  compose from the primitives it lists and extend the document in the same change when a token
  or primitive is added. The design document test keeps its token table equal to the stylesheet.
- Run `/ui-check <surface>` (light and dark, checklist with evidence, visual and contrast tests)
  before UI work is called done; a `fail` row means the work is not finished.
