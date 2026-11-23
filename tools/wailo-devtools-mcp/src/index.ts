import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { spawn, execFile } from "node:child_process";
import { promisify } from "node:util";
import { mkdir, readFile, writeFile, rm, access, open, stat } from "node:fs/promises";
import path from "node:path";

const execFileAsync = promisify(execFile);
const repo = path.resolve(process.env.WAILO_REPO ?? process.cwd());
const tmp = "/tmp/wailo-devtools";
const statePath = path.join(tmp, "state.json");
const logPath = path.join(tmp, "wailo.log");
const helperPath = path.join(tmp, "wailo-helper");
const actionPath = path.join(tmp, "test-window-action");

type State = { wailoPid?: number; testWindowPid?: number };
async function ensureTmp() { await mkdir(tmp, { recursive: true }); }
async function state(): Promise<State> { try { return JSON.parse(await readFile(statePath, "utf8")); } catch { return {}; } }
async function saveState(value: State) { await ensureTmp(); await writeFile(statePath, JSON.stringify(value)); }
function alive(pid?: number) { if (!pid) return false; try { process.kill(pid, 0); return true; } catch { return false; } }
async function stopPid(pid?: number) { if (alive(pid)) { try { process.kill(pid!, "SIGTERM"); } catch {} } }
async function text(value: unknown) { return { content: [{ type: "text" as const, text: typeof value === "string" ? value : JSON.stringify(value, null, 2) }] }; }
async function run(file: string, args: string[], options: { cwd?: string; timeout?: number } = {}) {
  return execFileAsync(file, args, { cwd: options.cwd ?? repo, timeout: options.timeout ?? 120_000, maxBuffer: 10 * 1024 * 1024 });
}
async function ensureHelper() {
  await ensureTmp();
  const source = path.join(repo, "tools/wailo-devtools-mcp/helpers/wailo-helper.swift");
  try {
    const [sourceStat, outputStat] = await Promise.all([stat(source), stat(helperPath)]);
    if (outputStat.mtimeMs >= sourceStat.mtimeMs) return;
  } catch {}
  await run("swiftc", [source, "-o", helperPath], { timeout: 180_000 });
}
function safeHealthURL(input?: string) {
  const raw = input ?? process.env.WAILO_BACKEND_URL ?? "http://localhost:3000";
  const url = new URL(raw); if (!["http:", "https:"].includes(url.protocol)) throw new Error("Only HTTP(S) health URLs are allowed");
  url.pathname = "/health"; url.search = ""; url.hash = ""; return url;
}

const server = new McpServer({ name: "wailo-devtools", version: "1.0.0" });

server.registerTool("launch_wailo", {
  description: "Build and launch one local Wailo instance, optionally with an autodemo and debug events.",
  inputSchema: { autodemo: z.enum(["folder", "safari", "cursed", "prompt"]).optional(), debug: z.boolean().optional() }
}, async ({ autodemo, debug }) => {
  await ensureTmp(); const current = await state(); await stopPid(current.wailoPid);
  await run("swift", ["build"], { cwd: path.join(repo, "app"), timeout: 300_000 });
  await writeFile(logPath, ""); const handle = await open(logPath, "a");
  const child = spawn(path.join(repo, "app/.build/debug/Wailo"), [], {
    cwd: path.join(repo, "app"), detached: true,
    env: { ...process.env, ...(autodemo ? { WAILO_AUTODEMO: autodemo } : {}), ...(debug ? { WAILO_DEBUG: "1" } : {}) },
    stdio: ["ignore", handle.fd, handle.fd]
  });
  child.unref(); await handle.close(); await saveState({ ...current, wailoPid: child.pid });
  return text({ pid: child.pid, logPath });
});

server.registerTool("quit_wailo", { description: "Quit the Wailo instance launched by this MCP.", inputSchema: {} }, async () => {
  const current = await state(); await stopPid(current.wailoPid); delete current.wailoPid; await saveState(current); return text({ stopped: true });
});

server.registerTool("screenshot", {
  description: "Capture a local screenshot to /tmp, downscale to 1200px, and return image content.",
  inputSchema: { delaySeconds: z.number().min(0).max(30).optional(), region: z.object({ x: z.number(), y: z.number(), w: z.number().positive(), h: z.number().positive() }).optional() }
}, async ({ delaySeconds, region }) => {
  await ensureTmp(); if (delaySeconds) await new Promise(r => setTimeout(r, delaySeconds * 1000));
  const output = path.join(tmp, `screenshot-${Date.now()}.png`); const args = ["-x"];
  if (region) args.push("-R", `${Math.round(region.x)},${Math.round(region.y)},${Math.round(region.w)},${Math.round(region.h)}`);
  args.push(output); await run("screencapture", args); await run("sips", ["-Z", "1200", output]);
  const data = await readFile(output); return { content: [{ type: "text" as const, text: output }, { type: "image" as const, data: data.toString("base64"), mimeType: "image/png" }] };
});

server.registerTool("ax_dump", {
  description: "Dump a bounded local AX role/title/description/frame tree without text-field values.",
  inputSchema: { bundleId: z.string().min(1), depth: z.number().int().min(0).max(12).optional() }
}, async ({ bundleId, depth }) => { await ensureHelper(); return text(JSON.parse((await run(helperPath, ["ax-dump", bundleId, String(depth ?? 4)])).stdout)); });

server.registerTool("dock_items", { description: "List local Dock AX item title, subrole, and frame data.", inputSchema: {} },
  async () => { await ensureHelper(); return text(JSON.parse((await run(helperPath, ["dock-items"])).stdout)); });

server.registerTool("cpu_sample", {
  description: "Sample CPU percentage for the MCP-launched Wailo process.", inputSchema: { seconds: z.number().int().min(1).max(120) }
}, async ({ seconds }) => {
  const current = await state(); if (!alive(current.wailoPid)) throw new Error("Wailo is not running through this MCP");
  const samples: number[] = [];
  for (let i = 0; i < seconds; i++) { const { stdout } = await run("ps", ["-p", String(current.wailoPid), "-o", "%cpu="]); samples.push(Number(stdout.trim()) || 0); await new Promise(r => setTimeout(r, 1000)); }
  return text({ pid: current.wailoPid, samples, mean: samples.reduce((a, b) => a + b, 0) / samples.length });
});

server.registerTool("log_tail", {
  description: "Read bounded lines from the local WAILO_DEBUG log.", inputSchema: { lines: z.number().int().min(1).max(1000).optional(), grep: z.string().max(100).optional() }
}, async ({ lines, grep }) => {
  let rows: string[]; try { rows = (await readFile(logPath, "utf8")).split(/\r?\n/); } catch { rows = []; }
  if (grep) rows = rows.filter(line => line.includes(grep)); return text(rows.slice(-(lines ?? 80)).join("\n"));
});

server.registerTool("grimoire_read", { description: "Read the local Wailo Grimoire JSON.", inputSchema: {} }, async () => {
  const file = path.join(process.env.HOME ?? "", "Library/Application Support/Wailo/grimoire.json");
  try { return text(JSON.parse(await readFile(file, "utf8"))); } catch { return text({ spells: [], path: file }); }
});

server.registerTool("backend_health", { description: "Call GET /health on the configured Wailo backend.", inputSchema: { url: z.string().url().optional() } },
  async ({ url }) => { const target = safeHealthURL(url); const response = await fetch(target); return text({ url: target.origin, status: response.status, body: await response.json().catch(() => null) }); });

server.registerTool("test_window", {
  description: "Show, move, or close a throwaway helper window owned by this tool.", inputSchema: { action: z.enum(["show", "glide", "jump", "close"]) }
}, async ({ action }) => {
  await ensureTmp(); await ensureHelper(); const current = await state();
  if (action === "show") {
    await stopPid(current.testWindowPid); await writeFile(actionPath, "");
    const child = spawn(helperPath, ["test-window", actionPath], { detached: true, stdio: "ignore" }); child.unref(); current.testWindowPid = child.pid; await saveState(current);
  } else if (action === "close") { await writeFile(actionPath, "close"); delete current.testWindowPid; await saveState(current); }
  else { if (!alive(current.testWindowPid)) throw new Error("Test window is not running"); await writeFile(actionPath, action); }
  return text({ action, pid: current.testWindowPid });
});

server.registerTool("synthetic_drag", {
  description: "Perform a gated local synthetic mouse drag for Wailo QA.", inputSchema: { from: z.object({ x: z.number(), y: z.number() }), to: z.object({ x: z.number(), y: z.number() }), steps: z.number().int().min(1).max(200).optional() }
}, async ({ from, to, steps }) => {
  if (process.env.WAILO_DEVTOOLS_ALLOW_INPUT !== "1") throw new Error("Refused: set WAILO_DEVTOOLS_ALLOW_INPUT=1 explicitly");
  await ensureHelper(); const { stdout } = await run(helperPath, ["drag", String(from.x), String(from.y), String(to.x), String(to.y), String(steps ?? 20)]); return text(JSON.parse(stdout));
});

await ensureTmp();
await server.connect(new StdioServerTransport());
