import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

// WCAG 2.x contrast of the design tokens, light and dark: text pairs need 4.5:1.
// Adjust CSS_PATH, the dark-theme marker and PAIRS to the project's token names.
const CSS_PATH = "src/index.css";
const DARK_MARKER = "@media (prefers-color-scheme: dark)";
const AA_TEXT = 4.5;

const PAIRS: [string, string][] = [
  ["fg", "bg"],
  ["fg-2", "bg"],
  ["accent", "bg"],
  ["accent-fg", "accent"],
];

type Theme = Map<string, string>;

function tokens(block: string): Theme {
  return new Map([...block.matchAll(/--([\w-]+):\s*(#[0-9a-fA-F]{6})\b/g)].map((m) => [m[1] ?? "", m[2] ?? ""]));
}

function channel(hex: string, start: number): number {
  const c = parseInt(hex.slice(start, start + 2), 16) / 255;
  return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

const luminance = (hex: string): number =>
  0.2126 * channel(hex, 1) + 0.7152 * channel(hex, 3) + 0.0722 * channel(hex, 5);

function contrast(a: string, b: string): number {
  const lighter = Math.max(luminance(a), luminance(b));
  const darker = Math.min(luminance(a), luminance(b));
  return (lighter + 0.05) / (darker + 0.05);
}

const css = readFileSync(CSS_PATH, "utf8");
const darkAt = css.indexOf(DARK_MARKER);
const light = tokens(darkAt < 0 ? css : css.slice(0, darkAt));
const dark: Theme = darkAt < 0 ? light : new Map([...light, ...tokens(css.slice(darkAt))]);

describe.each([
  ["light", light],
  ["dark", dark],
])("%s theme text contrast", (_, theme) => {
  it.each(PAIRS)("%s on %s meets WCAG AA", (fg, bg) => {
    expect(theme.has(fg), `token --${fg} missing`).toBe(true);
    expect(theme.has(bg), `token --${bg} missing`).toBe(true);
    expect(contrast(theme.get(fg) ?? "#000000", theme.get(bg) ?? "#000000")).toBeGreaterThanOrEqual(AA_TEXT);
  });
});
