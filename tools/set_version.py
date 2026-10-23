"""Zet versie en build uit version.properties in tauri.conf.json ("1.0.1+140": bestandsversie 1.0.1.140),
src-tauri/Cargo.toml (+ Cargo.lock) en package.json. Met --check alleen controleren (workflow Build): afwijking = exit 1."""
import json, pathlib, re, sys

root = pathlib.Path(__file__).resolve().parent.parent
props = dict(l.split("=", 1) for l in (root / "version.properties").read_text().splitlines() if l and not l.startswith("#") and "=" in l)
ver, build = props["BINGR_VERSION"].strip(), props["BINGR_BUILD"].strip()
if not re.fullmatch(r"\d+\.\d+\.\d+", ver) or not re.fullmatch(r"\d{1,5}", build) or int(build) > 65535:
    sys.exit(f"ongeldige versie/build in version.properties: {ver} / {build}")
check = "--check" in sys.argv
bad = []

def update(path, old):
    p = root / path
    t = p.read_text()
    n = old(t)
    if n != t:
        bad.append(path)
        if not check: p.write_text(n)

update("src-tauri/tauri.conf.json", lambda t: re.sub(r'("version":\s*")[^"]*(")', rf'\g<1>{ver}+{build}\g<2>', t, count=1))
update("src-tauri/Cargo.toml", lambda t: re.sub(r'(?m)^(version\s*=\s*")[^"]*(")', rf'\g<1>{ver}\g<2>', t, count=1))
update("src-tauri/Cargo.lock", lambda t: re.sub(r'(\[\[package\]\]\nname = "bingr"\nversion = ")[^"]*(")', rf'\g<1>{ver}\g<2>', t, count=1))
update("package.json", lambda t: re.sub(r'("version":\s*")[^"]*(")', rf'\g<1>{ver}\g<2>', t, count=1))

if check and bad:
    sys.exit(f"versie/build {ver}+{build} uit version.properties staat niet in: {', '.join(bad)} (draai python3 tools/set_version.py)")
print(f"Bingr voor Windows {ver} (build {build})" + ("" if check else (": bijgewerkt " + ", ".join(bad) if bad else ": alles klopt al")))
