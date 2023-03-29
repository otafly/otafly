import { config } from "./config";

export async function getLatestPackages() {
  return await request(config.api_endpoint + "/app/packages/latest", "GET");
}

export async function getPackage(id) {
  const url = new URL(config.api_endpoint + "/app/packages/");
  url.searchParams.append("appId", id);
  return await request(url.toString(), "GET");
}

export async function createAppMeta(meta) {
  const body = Object.keys(meta)
    .map((key) => encodeURIComponent(key) + "=" + encodeURIComponent(meta[key]))
    .join("&");
  await request(
    config.api_endpoint + "/app/meta",
    "POST",
    { "Content-Type": "application/x-www-form-urlencoded" },
    body
  );
}

export async function getAppMetas() {
  return await request(config.api_endpoint + "/app/metas", "GET");
}

export async function getUser(username, password) {
  let auth = window.btoa(username + ":" + password);
  let user = await request(
    config.api_endpoint + "/user",
    "GET",
    {
      Authorization: "Basic " + auth,
    },
    null,
    false
  );
  sessionStorage.setItem("auth", auth);
  return user;
}

export function isAdmin() {
  return sessionStorage.getItem("auth") != null;
}

async function request(endpoint, method, headers, body, protect) {
  var options = {
    method: method,
    headers: headers ?? {},
  };
  if (protect == undefined || protect || protect == true) {
    let auth = sessionStorage.getItem("auth");
    if (auth) {
      options.headers.Authorization = "Basic " + auth;
    }
  } else {
    console.log("not protected");
  }
  if (body) {
    options.body = body;
  }
  const response = await fetch(endpoint, options);
  if (response.status >= 400) {
    let errorModel = await response.json();
    console.log(errorModel);
    throw new Error(errorModel.reason);
  }
  if (response.status == 201) {
    return;
  } else {
    return await response.json();
  }
}
