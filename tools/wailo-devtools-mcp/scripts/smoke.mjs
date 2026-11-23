import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "../../..");
const client = new Client({ name: "wailo-devtools-smoke", version: "1.0.0" });
const transport = new StdioClientTransport({
  command: "node",
  args: [path.resolve(here, "../dist/index.js")],
  env: { ...Object.fromEntries(Object.entries(process.env).filter(([, v]) => v !== undefined)), WAILO_REPO: root }
});
await client.connect(transport);
const listed = await client.listTools();
console.log(JSON.stringify({ tools: listed.tools.map(tool => tool.name) }, null, 2));
const tail = await client.callTool({ name: "log_tail", arguments: { lines: 2 } });
console.log(JSON.stringify({ logTailCalled: !tail.isError }, null, 2));
await client.close();
