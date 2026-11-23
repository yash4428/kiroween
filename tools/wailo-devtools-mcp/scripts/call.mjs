import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import path from "node:path";
import { fileURLToPath } from "node:url";

const [name, raw = "{}"] = process.argv.slice(2);
if (!name) throw new Error("usage: node scripts/call.mjs <tool> '<json arguments>'");
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../..");
const env = Object.fromEntries(Object.entries(process.env).filter(([, value]) => value !== undefined));
const client = new Client({ name: "wailo-devtools-call", version: "1.0.0" });
const transport = new StdioClientTransport({
  command: "node",
  args: [path.resolve(here, "../dist/index.js")],
  env: { ...env, WAILO_REPO: repo, WAILO_DEVTOOLS_ALLOW_INPUT: "1" }
});
await client.connect(transport);
const result = await client.callTool({ name, arguments: JSON.parse(raw) });
console.log(JSON.stringify(result, null, 2));
await client.close();
