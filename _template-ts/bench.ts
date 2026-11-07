import { bench, run } from "mitata";
import { run as experiment } from "./index";

bench("run", () => experiment());

await run();
