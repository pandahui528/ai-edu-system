const baseUrl = process.env.API_BASE_URL || "http://localhost:3000";
const maxPoll = Number(process.env.MAX_POLL || 5);
const sleepMs = Number(process.env.SLEEP_MS || 2000);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function request(path, options = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });
  const text = await res.text();
  let body = {};
  try {
    body = JSON.parse(text);
  } catch {
    body = { raw: text };
  }
  console.log(text);
  if (!res.ok) {
    throw new Error(`${path} status ${res.status}`);
  }
  return body;
}

async function main() {
  await request("/health");

  await request("/upload/credential", {
    method: "POST",
    body: JSON.stringify({ contentType: "image/jpeg", size: 12345, sha256: "test" }),
  });

  const jobRes = await request("/jobs/analyze", {
    method: "POST",
    body: JSON.stringify({
      input: { type: "image", cosKey: "uploads/placeholder.jpg" },
      options: { mode: "extract_template_info" },
    }),
  });

  const jobId = jobRes?.data?.jobId;
  if (jobId) {
    for (let i = 0; i < maxPoll; i += 1) {
      const poll = await request(`/jobs/${jobId}`);
      const status = poll?.data?.status;
      if (status === "done" || status === "failed") return;
      await sleep(sleepMs);
    }
    throw new Error(`job not finished after ${maxPoll} polls`);
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
