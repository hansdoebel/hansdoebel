import { execFile } from "node:child_process";
import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const exec = promisify(execFile);
const readmePath = new URL("../README.md", import.meta.url);
const npmNames = {
  "n8n-nodes-bouncer": "n8n-nodes-usebouncer",
  "n8n-nodes-dida365": "n8n-nodes-dida",
  "n8n-nodes-dev": "n8n-nodes-devto",
};
const entryPattern = /^(- \*\*\[(n8n-nodes-[a-z0-9-]+)\]\(https:\/\/github\.com\/hansdoebel\/\2\)\*\* — v)([^\s]+)([^\S\r\n]*)$/gm;
const versionPattern = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$/;

export async function fetchVersion(name) {
  const { stdout } = await exec("curl", [
    "--fail", "--silent", "--show-error", "--retry", "2",
    "--connect-timeout", "10", "--max-time", "30",
    `https://registry.npmjs.org/${encodeURIComponent(name)}/latest`,
  ]);
  const metadata = JSON.parse(stdout);
  if (metadata.name !== name || !versionPattern.test(metadata.version)) {
    throw new Error(`Invalid npm latest metadata for ${name}`);
  }
  return metadata.version;
}

export async function updateReadme(readme, getVersion = fetchVersion, now = new Date()) {
  const entries = [...readme.matchAll(entryPattern)];
  const listed = [...readme.matchAll(/^- \*\*\[n8n-nodes-/gm)];
  if (!entries.length || entries.length !== listed.length) {
    throw new Error("Missing or malformed n8n package entries");
  }
  const versions = new Map();
  // Fetch everything before changing the README so failures leave it intact.
  for (const [, , name] of entries) {
    const version = await getVersion(npmNames[name] ?? name);
    if (!versionPattern.test(version)) throw new Error(`Invalid version for ${name}`);
    versions.set(name, version);
  }
  const updated = readme.replace(entryPattern, (_, prefix, name, old, space) =>
    `${prefix}${versions.get(name)}${space}`,
  );
  if (updated === readme) return readme;
  if (!/^\*Last updated on .+\*$/m.test(updated)) throw new Error("Missing last updated date");
  const date = now.toLocaleDateString("en-US", {
    month: "long", day: "2-digit", year: "numeric", timeZone: "UTC",
  });
  return updated.replace(/^\*Last updated on .+\*$/m, `*Last updated on ${date}*`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    const readme = await readFile(readmePath, "utf8");
    const updated = await updateReadme(readme);
    if (process.argv.includes("--check")) {
      if (updated !== readme) throw new Error("README versions differ from npm latest; run npm run uv");
      console.log("All README versions match npm latest.");
    } else if (updated !== readme) {
      await writeFile(readmePath, updated);
      console.log("Updated README versions and date from npm latest.");
    } else {
      console.log("README versions already match npm latest.");
    }
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
