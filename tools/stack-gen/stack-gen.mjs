#!/usr/bin/env node
import fs from "fs";
import path from "path";

const ROOT = process.cwd();
const MATRIX_PATH = path.join(ROOT, "system-assets", "playbook", "stack-decision-matrix.json");

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function writeFile(p, content) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, content);
}

function appendOrCreate(p, header, content) {
  if (!fs.existsSync(p)) {
    writeFile(p, content);
    return;
  }
  const existing = fs.readFileSync(p, "utf8");
  if (existing.includes(header)) return;
  const next = `${existing}\n\n${header}\n\n${content}`;
  fs.writeFileSync(p, next);
}

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i += 1) {
    const a = args[i];
    if (a === "--profile") out.profile = args[i + 1];
    if (a === "--input") out.input = args[i + 1];
  }
  return out;
}

function profileToInput(profile) {
  const parts = profile.split("_");
  const out = {};
  if (parts.includes("miniprogram")) out.interaction_mode = "miniprogram";
  if (parts.includes("h5")) out.interaction_mode = "h5";
  if (parts.includes("image")) out.input_type = "image";
  if (parts.includes("text")) out.input_type = "text";
  if (parts.includes("audio")) out.input_type = "audio";
  if (parts.includes("video")) out.input_type = "video";
  if (parts.includes("async")) out.latency = "async";
  if (parts.includes("instant")) out.latency = "instant";
  if (parts.includes("china")) out.compliance = "china_required";
  if (parts.includes("global")) out.compliance = "global_ok";
  return out;
}

function applyDefaults(input, defaults) {
  return { ...defaults, ...input };
}

function ruleMatch(input, rule) {
  return rule.if.every((c) => {
    const v = input[c.field];
    switch (c.op) {
      case ">=":
        return Number(v) >= Number(c.value);
      case "=":
        return v === c.value;
      default:
        return false;
    }
  });
}

function applyRules(input, rules) {
  const applied = {};
  for (const rule of rules) {
    if (ruleMatch(input, rule)) Object.assign(applied, rule.then);
  }
  return applied;
}

function deriveUploadLimitMb(input) {
  if (typeof input.max_file_size_mb === "number") return input.max_file_size_mb;
  return 10;
}

function deriveSyncTimeoutMs(input) {
  if (input.latency === "instant") return 3000;
  if (input.latency === "short") return 9000;
  return 9000;
}

function renderApiContract(input, decisions) {
  const maxMb = deriveUploadLimitMb(input);
  const timeoutMs = deriveSyncTimeoutMs(input);
  const asyncMode = input.latency === "async" || decisions.execution_mode === "jobs";
  return `# 接口契约模板（v0.2 Generated）
+
+## 统一约束
+- 所有响应必须包含：traceId
+- 所有错误必须是结构化 JSON：{ ok:false, code, message, traceId, details? }
+- 超时策略：${asyncMode ? "异步（jobId + 轮询）" : `同步（超时 ${timeoutMs}ms）`}
+- 上传大小限制：MAX_UPLOAD_MB=${maxMb}
+- 直传/分片：${decisions.upload_strategy || "默认"}
+
+## 统一响应结构（强制）
+{ "ok": true/false, "data": {}, "error": {"code":"...","message":"...","details":{}}, "traceId": "..." }
+
+## 错误码（示例）
+- ERR_BAD_REQUEST / ERR_UNAUTHORIZED / ERR_RATE_LIMITED / ERR_TIMEOUT / ERR_UPSTREAM / ERR_UNKNOWN
+- ERR_UPLOAD_SIZE_EXCEEDED / ERR_UPLOAD_EXPIRED / ERR_UPLOAD_FAILED
+- ERR_JOB_NOT_FOUND / ERR_JOB_FAILED
+
+## /health
+GET /health
+Response: { "ok": true, "traceId": "..." }
+
+## /upload/credential
+POST /upload/credential
+Request: { "contentType": "image/jpeg", "size": 345678, "sha256": "..." }
+Response: { "ok": true, "traceId": "...", "data": { "provider": "cos", "tempSecret": {}, "key": "uploads/xxx.jpg", "expireAt": 1234567890 } }
+
+## /jobs/analyze
+POST /jobs/analyze
+Request: { "input": { "type": "image", "cosKey": "uploads/xxx.jpg" }, "options": { "mode": "extract_template_info" } }
+Response（同步完成）: { "ok": true, "traceId": "...", "data": { "result": {} } }
+Response（异步）: { "ok": true, "traceId": "...", "data": { "jobId": "job_123", "status": "queued" } }
+
+## /jobs/:jobId
+GET /jobs/:jobId
+Response: { "ok": true, "traceId": "...", "data": { "status": "running|done|failed", "result": {} } }
+`;
}

function renderEnvExample(input) {
  const maxMb = deriveUploadLimitMb(input);
  const timeoutMs = deriveSyncTimeoutMs(input);
  return `# runtime\nNODE_ENV=development\nAPP_ENV=local  # local|test|prod\n\n# cloudbase\nCLOUDBASE_ENV_ID=\nCLOUDBASE_REGION=ap-shanghai\nAPI_BASE_URL=\n\n# storage\nCOS_BUCKET=\nCOS_REGION=ap-shanghai\nCOS_UPLOAD_PREFIX=uploads/\n\n# llm\nLLM_PROVIDER=hunyuan  # hunyuan|doubao\nLLM_API_KEY=\nLLM_MODEL_ID=\n\n# limits\nMAX_UPLOAD_MB=${maxMb}\nSYNC_TIMEOUT_MS=${timeoutMs}\n`;
}

function renderSmokeCurl(input) {
  const asyncMode = input.latency === "async";
  const asyncTail = asyncMode ? 'fail "async mode expected jobId"' : 'log "sync job done"';
  return `#!/bin/bash\nset -euo pipefail\n\nBASE_URL=\"\${API_BASE_URL:-http://localhost:3000}\"\nMAX_POLL=\"\${MAX_POLL:-5}\"\nSLEEP_SEC=\"\${SLEEP_SEC:-2}\"\n\nlog() { printf \"%s\\n\" \"$1\"; }\nfail() { log \"FAIL: $1\"; exit 1; }\n\nlog \"==> health\"\nhealth_resp=\"$(curl -sS -w \"\\n%{http_code}\" \"$BASE_URL/health\")\"\nhealth_body=\"$(echo \"$health_resp\" | sed '$d')\"\nhealth_code=\"$(echo \"$health_resp\" | tail -n 1)\"\necho \"$health_body\"\ntrace_id=\"$(echo \"$health_body\" | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin).get(\"traceId\",\"\"))' 2>/dev/null || true)\"\nlog \"traceId: $trace_id\"\n[ \"$health_code\" = \"200\" ] || fail \"/health status $health_code\"\n\nlog \"==> upload credential\"\ncred_resp=\"$(curl -sS -H 'Content-Type: application/json' -d '{\"contentType\":\"image/jpeg\",\"size\":12345,\"sha256\":\"test\"}' -w \"\\n%{http_code}\" \"$BASE_URL/upload/credential\")\"\ncred_body=\"$(echo \"$cred_resp\" | sed '$d')\"\ncred_code=\"$(echo \"$cred_resp\" | tail -n 1)\"\necho \"$cred_body\"\ntrace_id=\"$(echo \"$cred_body\" | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin).get(\"traceId\",\"\"))' 2>/dev/null || true)\"\nlog \"traceId: $trace_id\"\n[ \"$cred_code\" = \"200\" ] || fail \"/upload/credential status $cred_code\"\n\nlog \"==> analyze job\"\njob_resp=\"$(curl -sS -H 'Content-Type: application/json' -d '{\"input\":{\"type\":\"image\",\"cosKey\":\"uploads/placeholder.jpg\"},\"options\":{\"mode\":\"extract_template_info\"}}' -w \"\\n%{http_code}\" \"$BASE_URL/jobs/analyze\")\"\njob_body=\"$(echo \"$job_resp\" | sed '$d')\"\njob_code=\"$(echo \"$job_resp\" | tail -n 1)\"\necho \"$job_body\"\ntrace_id=\"$(echo \"$job_body\" | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin).get(\"traceId\",\"\"))' 2>/dev/null || true)\"\nlog \"traceId: $trace_id\"\n[ \"$job_code\" = \"200\" ] || fail \"/jobs/analyze status $job_code\"\n\njob_id=\"$(echo \"$job_body\" | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin).get(\"data\",{}).get(\"jobId\",\"\"))' 2>/dev/null || true)\"\nif [ -n \"$job_id\" ]; then\n  log \"==> polling job: $job_id\"\n  for i in $(seq 1 \"$MAX_POLL\"); do\n    poll_resp=\"$(curl -sS -w \"\\n%{http_code}\" \"$BASE_URL/jobs/$job_id\")\"\n    poll_body=\"$(echo \"$poll_resp\" | sed '$d')\"\n    poll_code=\"$(echo \"$poll_resp\" | tail -n 1)\"\n    echo \"$poll_body\"\n    trace_id=\"$(echo \"$poll_body\" | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin).get(\"traceId\",\"\"))' 2>/dev/null || true)\"\n    log \"traceId: $trace_id\"\n    [ \"$poll_code\" = \"200\" ] || fail \"/jobs/$job_id status $poll_code\"\n    status=\"$(echo \"$poll_body\" | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin).get(\"data\",{}).get(\"status\",\"\"))' 2>/dev/null || true)\"\n    if [ \"$status\" = \"done\" ] || [ \"$status\" = \"failed\" ]; then\n      log \"job status: $status\"\n      exit 0\n    fi\n    sleep \"$SLEEP_SEC\"\n  done\n  fail \"job not finished after $MAX_POLL polls\"\nfi\n\n${asyncTail}\n`;
}

function renderDeployChecklist(decisions) {
  return `# 部署检查清单（v0.2 Generated）\n\n## 部署前（必做）\n- 构建目录已确认\n- 环境变量：local/test/prod 已区分且无缺失\n- CORS：prod 不允许 *\n- 配额/超时：上传大小、函数超时、内存配置确认\n- 日志：traceId 已接入\n- 冒烟测试：已在目标环境跑过并通过\n\n## 部署后（必做）\n- 线上 /health 通过\n- 核心链路 smoke-tests 通过\n- 错误码 & traceId 能定位\n\n## 运行时建议\n- 运行时：${decisions.runtime || "CloudBase 云函数"}\n- 回退策略：${decisions.degrade_strategy || "不可用时返回可解释降级结果"}\n`;
}

function main() {
  const args = parseArgs();
  if (!args.profile && !args.input) {
    console.error("Usage: node tools/stack-gen/stack-gen.mjs --profile <name> | --input <file>");
    process.exit(1);
  }

  const matrix = readJson(MATRIX_PATH);
  const inputFromProfile = args.profile ? profileToInput(args.profile) : {};
  const inputFromFile = args.input ? readJson(path.resolve(ROOT, args.input)) : {};
  const input = applyDefaults({ ...inputFromProfile, ...inputFromFile }, matrix.inputs.defaults);
  const decisions = applyRules(input, matrix.rules);

  const apiContract = renderApiContract(input, decisions);
  const envExample = renderEnvExample(input);
  const smokeCurl = renderSmokeCurl(input);
  const deployChecklist = renderDeployChecklist(decisions);

  writeFile(path.join(ROOT, "system-assets", "contracts", "api-contract.generated.md"), apiContract);
  writeFile(path.join(ROOT, "system-assets", "contracts", "env.generated.example"), envExample);
  writeFile(path.join(ROOT, "system-assets", "smoke-tests", "smoke.generated.curl.sh"), smokeCurl);
  writeFile(path.join(ROOT, "system-assets", "deploy", "deploy-checklist.generated.md"), deployChecklist);

  const rootApi = path.join(ROOT, "api-contract.md");
  const rootEnv = path.join(ROOT, "env.example");
  const rootSmokeDir = path.join(ROOT, "smoke-tests");
  const rootSmokeReadme = path.join(rootSmokeDir, "README.md");
  const rootSmokeCurl = path.join(rootSmokeDir, "smoke.curl.sh");
  const rootSmokeGenerated = path.join(rootSmokeDir, "smoke.generated.curl.sh");

  appendOrCreate(rootApi, "# Generated (v0.2)", apiContract);
  appendOrCreate(rootEnv, "# Generated (v0.2)", envExample);

  if (!fs.existsSync(rootSmokeDir)) fs.mkdirSync(rootSmokeDir, { recursive: true });
  if (fs.existsSync(rootSmokeReadme)) {
    writeFile(rootSmokeGenerated, smokeCurl);
  } else {
    writeFile(rootSmokeReadme, "# Smoke Tests\n\n生成器输出在此目录。\n");
    writeFile(rootSmokeCurl, smokeCurl);
  }

  console.log("Generated files written.");
}

main();
