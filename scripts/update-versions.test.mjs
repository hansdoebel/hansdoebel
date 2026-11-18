import assert from "node:assert/strict";
import test from "node:test";
import { updateReadme } from "./update-versions.mjs";

const entry = (name, version) => `- **[${name}](https://github.com/hansdoebel/${name})** — v${version}  `;
const date = "*Last updated on May 23, 2026*";
const now = new Date("2026-11-18T12:00:00Z");

test("updates TickTick from npm latest, preserves spacing, and refreshes the date", async () => {
  const input = `${entry("n8n-nodes-ticktick", "2.2.1")}\n${date}\n`;
  const result = await updateReadme(input, async (name) => {
    assert.equal(name, "n8n-nodes-ticktick");
    return "2.3.0";
  }, now);
  assert.equal(result, `${entry("n8n-nodes-ticktick", "2.3.0")}\n*Last updated on November 18, 2026*\n`);
  assert.equal(await updateReadme(result, async () => "2.3.0", now), result);
});

test("resolves all renamed npm packages, including dida365", async () => {
  const names = ["n8n-nodes-bouncer", "n8n-nodes-dida365", "n8n-nodes-dev"];
  const requested = [];
  await updateReadme(`${names.map((name) => entry(name, "1.0.0")).join("\n")}\n${date}`, async (name) => {
    requested.push(name);
    return "1.0.1";
  }, now);
  assert.deepEqual(requested, ["n8n-nodes-usebouncer", "n8n-nodes-dida", "n8n-nodes-devto"]);
});

test("keeps the date unchanged when versions match", async () => {
  const input = `${entry("n8n-nodes-ticktick", "2.3.0")}\n${date}`;
  assert.equal(await updateReadme(input, async () => "2.3.0", now), input);
});

test("rejects registry failures and malformed responses", async () => {
  const input = `${entry("n8n-nodes-ticktick", "2.2.1")}\n${date}`;
  await assert.rejects(updateReadme(input, async () => { throw new Error("HTTP 503"); }), /HTTP 503/);
  await assert.rejects(updateReadme(input, async () => "undefined"), /Invalid version/);
  await assert.rejects(updateReadme("no packages", async () => "2.3.0"), /Missing or malformed/);
  await assert.rejects(updateReadme(input.replace(" — v2.2.1", ""), async () => "2.3.0"), /Missing or malformed/);
});

test("preserves prerelease and build metadata", async () => {
  const input = `${entry("n8n-nodes-ticktick", "2.3.0-beta.1")}\n${date}`;
  assert.match(await updateReadme(input, async () => "2.3.0-rc.2+build.1", now), /v2\.3\.0-rc\.2\+build\.1/);
});
