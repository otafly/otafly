import { config } from "./config";

export async function createAppMeta(meta) {
  const body = Object.keys(meta)
    .map((key) => encodeURIComponent(key) + "=" + encodeURIComponent(meta[key]))
    .join("&");
  await fetch(config.api_endpoint + "/app/meta", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: body,
  });
}

export async function getAppMetas() {
  const response = await fetch(config.api_endpoint + "/app/metas");
  return await response.json();
}
