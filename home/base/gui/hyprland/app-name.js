import Gio from "gi://Gio";
import GioUnix from "gi://GioUnix";
import GLib from "gi://GLib";

function readText(path) {
  try {
    return new TextDecoder().decode(GLib.file_get_contents(path)[1]);
  } catch {
    // Processes may exit, and their environment may be unreadable.
    return "";
  }
}

export function steamAppId(window, procRoot = "/proc") {
  for (const value of [window.class, window.initialClass]) {
    const match = value?.match(/^steam_app_([1-9][0-9]*)$/i);
    if (match) return match[1];
  }

  let pid = window.pid;
  const visited = new Set();
  while (Number.isSafeInteger(pid) && pid > 1 && !visited.has(pid)) {
    visited.add(pid);
    const directory = GLib.build_filenamev([procRoot, String(pid)]);
    const environment = readText(`${directory}/environ`).split("\0");
    for (const key of ["SteamAppId", "SteamGameId"]) {
      const match = environment.find((value) => new RegExp(`^${key}=[1-9][0-9]*$`).test(value));
      if (match) return match.slice(key.length + 1);
    }
    pid = Number(readText(`${directory}/status`).match(/^PPid:\s+(\d+)$/m)?.[1]);
  }
  return "";
}

function readAcf(path) {
  if (!GLib.file_test(path, GLib.FileTest.IS_REGULAR)) return null;
  const process = Gio.Subprocess.new(
    ["acf", path],
    Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE,
  );
  const [, stdout] = process.communicate_utf8(null, null);
  try {
    if (process.get_successful()) return JSON.parse(stdout);
  } catch {
    // shortcut: steam-acf 0.1 cannot handle every escape; fall back until nixpkgs has a better parser.
  }
  printerr(`screenshot-app-name: cannot parse ${path}; using fallback`);
  return null;
}

export function steamName(appId) {
  if (!appId) return "";
  const home = GLib.get_home_dir();
  const roots = new Set([
    `${GLib.get_user_data_dir()}/Steam`,
    `${home}/.local/share/Steam`,
    `${home}/.steam/steam`,
    `${home}/.steam/root`,
  ]);
  const libraries = new Set(roots);
  for (const root of roots) {
    const folders = readAcf(`${root}/steamapps/libraryfolders.vdf`)?.libraryfolders;
    for (const [key, entry] of Object.entries(folders ?? {})) {
      if (!/^\d+$/.test(key)) continue;
      const path = typeof entry === "string" ? entry : entry?.path;
      if (typeof path === "string" && GLib.path_is_absolute(path)) libraries.add(path);
    }
  }
  for (const library of libraries) {
    const app = readAcf(`${library}/steamapps/appmanifest_${appId}.acf`)?.AppState;
    if (app?.appid === appId && typeof app.name === "string" && app.name.trim()) return app.name;
  }
  return "";
}

export function desktopName(classes) {
  // GIO owns XDG precedence, Hidden entries, localization and Desktop Entry escaping.
  const apps = Gio.AppInfo.get_all().filter((app) => app instanceof GioUnix.DesktopAppInfo);
  const normalize = (value) => value.toLowerCase().replace(/\.desktop$/, "");
  for (const value of classes) {
    const app = apps.find((entry) => normalize(entry.get_id()) === normalize(value));
    if (app) return app.get_name();
  }
  for (const value of classes) {
    const app = apps.find(
      (entry) => entry.get_startup_wm_class()?.toLowerCase() === value.toLowerCase(),
    );
    if (app) return app.get_name();
  }
  return "";
}

function serviceDesktopName(pid) {
  if (!Number.isSafeInteger(pid) || pid <= 1) return "";
  const process = Gio.Subprocess.new(
    ["systemctl", "--user", "whoami", String(pid)],
    Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE,
  );
  const [, stdout] = process.communicate_utf8(null, null);
  if (!process.get_successful()) return "";
  const unit = stdout.trim();
  if (!unit.endsWith(".service")) return "";
  // Resolve only services with a matching desktop ID; shared Proton classes are ambiguous.
  const app = GioUnix.DesktopAppInfo.new(unit.replace(/\.service$/, ".desktop"));
  return app && !app.get_is_hidden() ? app.get_name() : "";
}

export function safeName(name) {
  const cleaned = name.replace(/[/\\\x00-\x1f\x7f]/g, "_").trim();
  let result = "";
  let bytes = 0;
  const encoder = new TextEncoder();
  for (const character of cleaned) {
    bytes += encoder.encode(character).length;
    if (bytes > 200) break;
    result += character;
  }
  return ["", ".", ".."].includes(result) ? "unknown" : result;
}

export function resolveAppName(window) {
  if (!window || typeof window !== "object" || Array.isArray(window)) {
    throw new Error("Expected a Hyprland window JSON object");
  }
  const classes = [window.class, window.initialClass].filter(
    (value) => typeof value === "string" && value.trim(),
  );
  return safeName(
    steamName(steamAppId({ ...window, class: classes[0], initialClass: classes[1] })) ||
      desktopName(classes) ||
      serviceDesktopName(window.pid) ||
      classes[0] ||
      "unknown",
  );
}
