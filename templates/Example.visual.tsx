import "../index.css";

import { cleanup, render } from "@testing-library/react";
import type { ReactNode } from "react";
import { afterEach, describe, expect, it } from "vitest";
import { page } from "vitest/browser";

// A screenshot test: rendered in real Chromium in light and dark (see vitest.visual.config.ts)
// and compared with the approved image under __screenshots__/. Render every required state
// (ready, empty, absent value, error), not only the happy path. Approve a new reference with
// `-u` only after looking at the image.

afterEach(cleanup);

function Frame({ children }: { children: ReactNode }) {
  return (
    <div data-testid="frame" style={{ width: 640, padding: 16, background: "var(--bg)", color: "var(--fg)" }}>
      {children}
    </div>
  );
}

describe("Example surface", () => {
  it("ready state", async () => {
    render(
      <Frame>
        <p>Replace with the component under test, fed by fixtures.</p>
      </Frame>,
    );
    await expect(page.getByTestId("frame")).toMatchScreenshot("example-ready");
  });
});
