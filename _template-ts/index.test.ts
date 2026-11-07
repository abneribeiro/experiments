import { expect, test } from "bun:test";
import { run } from "./index";

test("run", () => {
  expect(run()).toBeUndefined();
});

// A type test: the line below must not compile. `tsc --noEmit` fails if it does.
// @ts-expect-error run takes no arguments
run(1);
