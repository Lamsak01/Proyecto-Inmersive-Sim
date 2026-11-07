#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Genera una enciclopedia en un único archivo .html autocontenido a partir de GameVault/.
Uso:
  python3 tools/export_vault_html.py --output /home/lamsaktp/Enciclopedia_LaPlacaDePetri.html --sin-secta-ni-diario
  python3 tools/export_vault_html.py --output /home/lamsaktp/Enciclopedia_LaPlacaDePetri_Completa.html
"""

import argparse
import html
import json
import os
import re
import unicodedata
from pathlib import Path


FOLDER_LABELS = {
    "00_MOC": "00 · Mapa Principal",
    "01_Vision_y_Reglas": "01 · Visión y Reglas",
    "02_Sistemas": "02 · Sistemas del Juego",
    "03_La_Secta": "03 · La Secta",
    "04_Censo_y_Misiones": "04 · Censo, Edificios y Misiones",
    "04_Censo_y_Misiones/Vecinos": "04a · Vecinos del Pueblo",
    "04_Censo_y_Misiones/Misiones": "04b · Misiones Secundarias",
    "05_Roadmap_y_Lore": "05 · Hoja de Ruta y Lore",
    "06_Diario": "06 · Diario de Desarrollo",
    "Plantillas": "Plantillas",
}


def slugify(text: str) -> str:
    norm = unicodedata.normalize("NFKD", text.strip().lower())
    ascii_text = "".join(c for c in norm if not unicodedata.combining(c))
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_text).strip("-")
    return slug or "nota"


def parse_frontmatter_and_body(raw: str) -> tuple[dict, str]:
    meta = {}
    body = raw.replace("\r\n", "\n")
    # Quitar bloque %% kanban:settings ... %% de Obsidian Kanban
    body = re.sub(r"%%\s*kanban:settings.*?%%", "", body, flags=re.DOTALL)
    if body.startswith("---\n"):
        end_idx = body.find("\n---", 4)
        if end_idx != -1:
            fm_text = body[4:end_idx].strip()
            body = body[end_idx + 4 :].lstrip("\n")
            current_key = None
            for line in fm_text.split("\n"):
                line_s = line.strip()
                if not line_s:
                    continue
                if line_s.startswith("- ") and current_key:
                    val = line_s[2:].strip().strip('"\'')
                    if isinstance(meta.get(current_key), list):
                        meta[current_key].append(val)
                    continue
                if ":" in line_s:
                    k, v = line_s.split(":", 1)
                    k = k.strip()
                    v = v.strip().strip('"\'')
                    if k == "kanban-plugin":
                        current_key = None
                        continue
                    if v == "":
                        meta[k] = []
                        current_key = k
                    else:
                        meta[k] = v
                        current_key = k
    return meta, body.strip()


def collect_notes(vault_dir: Path, exclude_secta_diario: bool, include_templates: bool) -> list[dict]:
    excluded_top = {".obsidian", "99_Archivo"}
    if exclude_secta_diario:
        excluded_top.update({"03_La_Secta", "06_Diario"})
    if not include_templates:
        excluded_top.add("Plantillas")

    notes = []
    used_ids = set()

    for root, dirs, files in os.walk(vault_dir):
        rel_root = Path(root).relative_to(vault_dir)
        parts = rel_root.parts
        if parts and parts[0] in excluded_top:
            dirs[:] = []
            continue
        dirs[:] = sorted(d for d in dirs if d not in excluded_top and not d.startswith("."))
        for fname in sorted(files):
            if not fname.endswith(".md"):
                continue
            fpath = Path(root) / fname
            rel_path = fpath.relative_to(vault_dir).as_posix()
            folder_key = rel_root.as_posix() if rel_root.as_posix() != "." else "00_MOC"
            title = fname[:-3]
            base_id = slugify(title)
            note_id = base_id
            counter = 2
            while note_id in used_ids:
                note_id = f"{base_id}-{counter}"
                counter += 1
            used_ids.add(note_id)

            raw = fpath.read_text(encoding="utf-8")
            meta, body = parse_frontmatter_and_body(raw)
            notes.append(
                {
                    "id": note_id,
                    "title": title,
                    "rel_path": rel_path,
                    "folder": folder_key,
                    "folder_label": FOLDER_LABELS.get(folder_key, folder_key),
                    "meta": meta,
                    "body": body,
                }
            )

    notes.sort(key=lambda n: (n["folder"], n["title"].lower()))
    return notes


def build_html(notes: list[dict], subtitle: str) -> str:
    notes_json = json.dumps(notes, ensure_ascii=False)
    default_id = next((n["id"] for n in notes if n["title"] == "La Placa de Petri"), notes[0]["id"] if notes else "")
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>La Placa de Petri — Enciclopedia del Proyecto</title>
<style>
  :root {{
    --bg: #161514;
    --bg-panel: #1f1d1b;
    --bg-card: #262320;
    --bg-hover: #312d28;
    --text: #ebe5dc;
    --text-muted: #a89f93;
    --accent: #e0a958;
    --accent-soft: rgba(224, 169, 88, 0.16);
    --link: #efb968;
    --link-missing: #9a7d6c;
    --border: #38332e;
    --check-ok: #6bbf7b;
  }}
  * {{ box-sizing: border-box; }}
  body {{
    margin: 0;
    font-family: system-ui, -apple-system, "Segoe UI", Roboto, Ubuntu, sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.65;
    display: flex;
    flex-direction: column;
    height: 100vh;
    overflow: hidden;
  }}
  header {{
    background: var(--bg-panel);
    border-bottom: 1px solid var(--border);
    padding: 0.65rem 1rem;
    display: flex;
    align-items: center;
    gap: 0.85rem;
    flex-wrap: wrap;
    z-index: 10;
  }}
  .menu-btn {{
    display: none;
    background: var(--bg-card);
    color: var(--text);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 0.4rem 0.65rem;
    font-size: 1rem;
    cursor: pointer;
  }}
  .brand {{
    font-weight: 700;
    font-size: 1.05rem;
    color: var(--accent);
    letter-spacing: 0.02em;
    cursor: pointer;
  }}
  .subtitle {{
    font-size: 0.82rem;
    color: var(--text-muted);
  }}
  .search-wrap {{
    margin-left: auto;
    position: relative;
    flex: 1 1 260px;
    max-width: 420px;
  }}
  #search-input {{
    width: 100%;
    padding: 0.48rem 0.8rem;
    border-radius: 6px;
    border: 1px solid var(--border);
    background: var(--bg);
    color: var(--text);
    font-size: 0.92rem;
  }}
  #search-input:focus {{
    outline: 2px solid var(--accent);
    border-color: transparent;
  }}
  .layout {{
    display: flex;
    flex: 1;
    overflow: hidden;
    position: relative;
  }}
  aside {{
    width: 310px;
    background: var(--bg-panel);
    border-right: 1px solid var(--border);
    overflow-y: auto;
    padding: 0.75rem 0.6rem 2rem;
    flex-shrink: 0;
  }}
  .folder-group {{
    margin-bottom: 0.75rem;
  }}
  .folder-title {{
    font-size: 0.78rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-muted);
    padding: 0.35rem 0.5rem;
    cursor: pointer;
    user-select: none;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }}
  .folder-title:hover {{
    color: var(--text);
  }}
  .folder-items {{
    list-style: none;
    margin: 0;
    padding: 0;
  }}
  .nav-item {{
    display: block;
    padding: 0.34rem 0.65rem;
    margin: 1px 0;
    border-radius: 5px;
    color: var(--text);
    text-decoration: none;
    font-size: 0.9rem;
    cursor: pointer;
    transition: background 0.12s;
  }}
  .nav-item:hover {{
    background: var(--bg-hover);
  }}
  .nav-item.active {{
    background: var(--accent-soft);
    color: var(--accent);
    font-weight: 600;
  }}
  main {{
    flex: 1;
    overflow-y: auto;
    padding: 1.8rem 2.4rem 4rem;
  }}
  .note-container {{
    max-width: 820px;
    margin: 0 auto;
  }}
  .note-folder-crumb {{
    font-size: 0.82rem;
    color: var(--text-muted);
    margin-bottom: 0.3rem;
  }}
  .meta-bar {{
    display: flex;
    flex-wrap: wrap;
    gap: 0.4rem;
    margin-bottom: 1.2rem;
  }}
  .badge {{
    font-size: 0.75rem;
    background: var(--bg-card);
    border: 1px solid var(--border);
    color: var(--text-muted);
    padding: 0.15rem 0.55rem;
    border-radius: 999px;
  }}
  h1, h2, h3, h4 {{
    color: #f6efe4;
    line-height: 1.3;
    margin-top: 1.6em;
    margin-bottom: 0.55em;
  }}
  h1 {{
    font-size: 1.85rem;
    margin-top: 0.2rem;
    border-bottom: 1px solid var(--border);
    padding-bottom: 0.45rem;
  }}
  h2 {{
    font-size: 1.35rem;
    border-bottom: 1px solid rgba(255,255,255,0.07);
    padding-bottom: 0.25rem;
  }}
  h3 {{ font-size: 1.12rem; }}
  p {{ margin: 0.75em 0; }}
  ul, ol {{
    padding-left: 1.4rem;
    margin: 0.6em 0;
  }}
  li {{ margin: 0.3em 0; }}
  li.task-item {{
    list-style: none;
    margin-left: -1.1rem;
  }}
  .task-box {{
    display: inline-block;
    width: 1.15rem;
    font-weight: bold;
    color: var(--text-muted);
  }}
  .task-box.done {{
    color: var(--check-ok);
  }}
  a.wikilink {{
    color: var(--link);
    text-decoration: none;
    border-bottom: 1px dashed rgba(239, 185, 104, 0.5);
    cursor: pointer;
  }}
  a.wikilink:hover {{
    background: var(--accent-soft);
    border-bottom-style: solid;
  }}
  a.wikilink.missing {{
    color: var(--link-missing);
    border-bottom-color: rgba(154, 125, 108, 0.4);
  }}
  blockquote {{
    margin: 1rem 0;
    padding: 0.6rem 1rem;
    border-left: 3px solid var(--accent);
    background: var(--bg-card);
    color: var(--text-muted);
    border-radius: 0 6px 6px 0;
  }}
  code {{
    font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    font-size: 0.86em;
    background: var(--bg-card);
    padding: 0.12rem 0.35rem;
    border-radius: 4px;
    border: 1px solid var(--border);
  }}
  pre {{
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 0.85rem 1rem;
    overflow-x: auto;
  }}
  pre code {{
    background: none;
    border: none;
    padding: 0;
  }}
  table {{
    width: 100%;
    border-collapse: collapse;
    margin: 1.1rem 0;
    font-size: 0.92rem;
  }}
  th, td {{
    border: 1px solid var(--border);
    padding: 0.5rem 0.7rem;
    text-align: left;
    vertical-align: top;
  }}
  th {{
    background: var(--bg-card);
    color: var(--accent);
  }}
  hr {{
    border: none;
    border-top: 1px solid var(--border);
    margin: 1.6rem 0;
  }}
  .search-results-banner {{
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 0.9rem 1.1rem;
    margin-bottom: 1.4rem;
  }}
  .search-hit {{
    padding: 0.55rem 0;
    border-bottom: 1px solid var(--border);
  }}
  .search-hit:last-child {{ border-bottom: none; }}
  .search-hit-title {{
    color: var(--link);
    font-weight: 600;
    cursor: pointer;
  }}
  .search-hit-snippet {{
    font-size: 0.85rem;
    color: var(--text-muted);
    margin-top: 0.2rem;
  }}
  @media (max-width: 820px) {{
    .menu-btn {{ display: inline-block; }}
    aside {{
      position: absolute;
      top: 0;
      bottom: 0;
      left: 0;
      z-index: 20;
      transform: translateX(-100%);
      transition: transform 0.2s ease;
      box-shadow: 4px 0 18px rgba(0,0,0,0.6);
    }}
    aside.open {{
      transform: translateX(0);
    }}
    main {{
      padding: 1.2rem 1rem 3rem;
    }}
  }}
</style>
</head>
<body>
<header>
  <button class="menu-btn" id="menu-toggle" title="Mostrar u ocultar índice">☰ Índice</button>
  <div class="brand" id="home-btn">La Placa de Petri</div>
  <div class="subtitle">{html.escape(subtitle)} ({len(notes)} notas)</div>
  <div class="search-wrap">
    <input type="search" id="search-input" placeholder="Buscar en toda la enciclopedia…" autocomplete="off">
  </div>
</header>
<div class="layout">
  <aside id="sidebar"></aside>
  <main id="main-scroll">
    <div class="note-container" id="content"></div>
  </main>
</div>
<script>
const NOTES = {notes_json};
const DEFAULT_ID = {json.dumps(default_id)};

const byId = new Map();
const byTitleLower = new Map();
const byRelLower = new Map();

function normKey(s) {{
  return (s || "").trim().toLowerCase()
    .normalize("NFD").replace(/[\\u0300-\\u036f]/g, "");
}}

for (const n of NOTES) {{
  byId.set(n.id, n);
  byTitleLower.set(normKey(n.title), n);
  byRelLower.set(normKey(n.rel_path.replace(/\\.md$/i, "")), n);
}}

function resolveWikiTarget(rawTarget) {{
  const clean = rawTarget.split("#")[0].trim();
  if (!clean) return null;
  const k = normKey(clean);
  if (byTitleLower.has(k)) return byTitleLower.get(k);
  if (byRelLower.has(k)) return byRelLower.get(k);
  const base = normKey(clean.split("/").pop());
  if (byTitleLower.has(base)) return byTitleLower.get(base);
  return null;
}}

function escapeHtml(s) {{
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}}

function renderInline(text) {{
  let s = escapeHtml(text);
  // Bloques de código en línea `...`
  const codeTokens = [];
  s = s.replace(/`([^`]+)`/g, (_, c) => {{
    const idx = codeTokens.length;
    codeTokens.push(`<code>${{c}}</code>`);
    return `\\u0000CODE${{idx}}\\u0000`;
  }});
  // Enlaces internos [[Destino|Etiqueta]] o [[Destino]]
  s = s.replace(/\\[\\[([^\\]]+)\\]\\]/g, (_, inner) => {{
    const parts = inner.split("|");
    const targetRaw = parts[0].trim();
    const label = (parts[1] ? parts[1] : targetRaw.split("/").pop().replace("#", " · ")).trim();
    const found = resolveWikiTarget(targetRaw);
    if (found) {{
      return `<a class="wikilink" href="#${{found.id}}" data-note="${{found.id}}">${{label}}</a>`;
    }}
    return `<a class="wikilink missing" title="Nota no incluida en esta edición">${{label}}</a>`;
  }});
  // Enlaces markdown [texto](url)
  s = s.replace(/\\[([^\\]]+)\\]\\(([^)]+)\\)/g, (_, lbl, url) => {{
    if (url.endsWith(".md") || !url.includes("://")) {{
      const found = resolveWikiTarget(decodeURIComponent(url.replace(/\\.md$/i, "")));
      if (found) {{
        return `<a class="wikilink" href="#${{found.id}}" data-note="${{found.id}}">${{lbl}}</a>`;
      }}
    }}
    return `<a class="wikilink" href="${{url}}" target="_blank" rel="noopener">${{lbl}}</a>`;
  }});
  // Negrita y cursiva
  s = s.replace(/\\*\\*([^*]+)\\*\\*/g, "<strong>$1</strong>");
  s = s.replace(/\\*([^*]+)\\*/g, "<em>$1</em>");
  // Restaurar código en línea
  s = s.replace(/\\u0000CODE(\\d+)\\u0000/g, (_, idx) => codeTokens[Number(idx)]);
  return s;
}}

function renderMarkdown(md) {{
  const lines = md.split("\\n");
  let out = [];
  let inCode = false;
  let codeBuf = [];
  let listStack = [];
  let inTable = false;
  let tableRows = [];

  function closeLists() {{
    while (listStack.length > 0) {{
      out.push(`</${{listStack.pop()}}>`);
    }}
  }}
  function flushTable() {{
    if (!inTable) return;
    inTable = false;
    if (tableRows.length === 0) return;
    let htmlTbl = "<table>";
    tableRows.forEach((r, idx) => {{
      const cells = r.split("|").slice(1, -1).map(c => c.trim());
      if (idx === 1 && cells.every(c => /^[:\\-]+$/.test(c))) return;
      const tag = idx === 0 ? "th" : "td";
      htmlTbl += "<tr>" + cells.map(c => `<${{tag}}>${{renderInline(c)}}</${{tag}}>`).join("") + "</tr>";
    }});
    htmlTbl += "</table>";
    out.push(htmlTbl);
    tableRows = [];
  }}

  for (let i = 0; i < lines.length; i++) {{
    const rawLine = lines[i];
    const trimmed = rawLine.trim();

    if (trimmed.startsWith("```")) {{
      closeLists();
      flushTable();
      if (!inCode) {{
        inCode = true;
        codeBuf = [];
      }} else {{
        inCode = false;
        out.push(`<pre><code>${{escapeHtml(codeBuf.join("\\n"))}}</code></pre>`);
      }}
      continue;
    }}
    if (inCode) {{
      codeBuf.push(rawLine);
      continue;
    }}

    if (trimmed.startsWith("|") && trimmed.endsWith("|")) {{
      closeLists();
      inTable = true;
      tableRows.push(trimmed);
      continue;
    }} else if (inTable) {{
      flushTable();
    }}

    if (!trimmed) {{
      closeLists();
      continue;
    }}

    if (/^---+$/.test(trimmed)) {{
      closeLists();
      out.push("<hr>");
      continue;
    }}

    const hMatch = trimmed.match(/^(#{{1,4}})\\s+(.*)$/);
    if (hMatch) {{
      closeLists();
      const lvl = hMatch[1].length;
      out.push(`<h${{lvl}}>${{renderInline(hMatch[2])}}</h${{lvl}}>`);
      continue;
    }}

    if (trimmed.startsWith(">")) {{
      closeLists();
      const qText = trimmed.replace(/^>\\s?/, "");
      out.push(`<blockquote>${{renderInline(qText)}}</blockquote>`);
      continue;
    }}

    const ulMatch = rawLine.match(/^(\\s*)[-*]\\s+(.*)$/);
    if (ulMatch) {{
      if (listStack[listStack.length - 1] !== "ul") {{
        closeLists();
        listStack.push("ul");
        out.push("<ul>");
      }}
      const itemContent = ulMatch[2];
      const taskMatch = itemContent.match(/^\\[([ xX])\\]\\s+(.*)$/);
      if (taskMatch) {{
        const done = taskMatch[1].toLowerCase() === "x";
        const box = done ? '<span class="task-box done">☑</span>' : '<span class="task-box">☐</span>';
        out.push(`<li class="task-item">${{box}} ${{renderInline(taskMatch[2])}}</li>`);
      }} else {{
        out.push(`<li>${{renderInline(itemContent)}}</li>`);
      }}
      continue;
    }}

    const olMatch = rawLine.match(/^(\\s*)\\d+\\.\\s+(.*)$/);
    if (olMatch) {{
      if (listStack[listStack.length - 1] !== "ol") {{
        closeLists();
        listStack.push("ol");
        out.push("<ol>");
      }}
      out.push(`<li>${{renderInline(olMatch[2])}}</li>`);
      continue;
    }}

    closeLists();
    out.push(`<p>${{renderInline(trimmed)}}</p>`);
  }}

  closeLists();
  flushTable();
  return out.join("\\n");
}}

let currentId = DEFAULT_ID;

function buildSidebar(filterText = "") {{
  const sb = document.getElementById("sidebar");
  const q = normKey(filterText);
  const groups = new Map();

  for (const n of NOTES) {{
    if (q) {{
      const hay = normKey(n.title + " " + n.folder_label + " " + n.body);
      if (!hay.includes(q)) continue;
    }}
    if (!groups.has(n.folder_label)) groups.set(n.folder_label, []);
    groups.get(n.folder_label).push(n);
  }}

  let htmlParts = [];
  for (const [folderLabel, items] of groups.entries()) {{
    htmlParts.push(`<div class="folder-group">`);
    htmlParts.push(`<div class="folder-title"><span>${{escapeHtml(folderLabel)}}</span><span>${{items.length}}</span></div>`);
    htmlParts.push(`<ul class="folder-items">`);
    for (const item of items) {{
      const activeCls = item.id === currentId ? " active" : "";
      htmlParts.push(`<li><a class="nav-item${{activeCls}}" href="#${{item.id}}" data-note="${{item.id}}">${{escapeHtml(item.title)}}</a></li>`);
    }}
    htmlParts.push(`</ul></div>`);
  }}
  if (htmlParts.length === 0) {{
    htmlParts.push(`<p style="padding:0.5rem;color:var(--text-muted);font-size:0.9rem;">No hay notas que coincidan con «${{escapeHtml(filterText)}}».</p>`);
  }}
  sb.innerHTML = htmlParts.join("");
}}

function openNote(id, pushHash = true) {{
  const note = byId.get(id) || byId.get(DEFAULT_ID);
  if (!note) return;
  currentId = note.id;
  if (pushHash && location.hash !== "#" + note.id) {{
    history.pushState(null, "", "#" + note.id);
  }}

  const metaEntries = Object.entries(note.meta || {{}});
  let metaHtml = "";
  if (metaEntries.length > 0) {{
    metaHtml = `<div class="meta-bar">` + metaEntries.map(([k, v]) => {{
      const val = Array.isArray(v) ? v.join(", ") : v;
      return `<span class="badge">${{escapeHtml(k)}}: ${{escapeHtml(val)}}</span>`;
    }}).join("") + `</div>`;
  }}

  let bodyMd = note.body;
  const hasH1 = /^#\\s+/m.test(bodyMd);
  const titleHtml = hasH1 ? "" : `<h1>${{escapeHtml(note.title)}}</h1>`;

  const q = document.getElementById("search-input").value.trim();
  let searchBanner = "";
  if (q.length >= 2) {{
    const qNorm = normKey(q);
    const hits = NOTES.filter(n => normKey(n.title + " " + n.body).includes(qNorm)).slice(0, 12);
    if (hits.length > 0) {{
      searchBanner = `<div class="search-results-banner"><strong>Resultados para «${{escapeHtml(q)}}» (${{hits.length}}):</strong>` +
        hits.map(h => `<div class="search-hit"><span class="search-hit-title" data-note="${{h.id}}">${{escapeHtml(h.title)}}</span> <span class="badge">${{escapeHtml(h.folder_label)}}</span></div>`).join("") +
        `</div>`;
    }}
  }}

  const contentEl = document.getElementById("content");
  contentEl.innerHTML =
    searchBanner +
    `<div class="note-folder-crumb">${{escapeHtml(note.folder_label)}}</div>` +
    titleHtml +
    metaHtml +
    renderMarkdown(bodyMd);

  document.getElementById("main-scroll").scrollTop = 0;
  buildSidebar(document.getElementById("search-input").value);
  document.getElementById("sidebar").classList.remove("open");
}}

document.addEventListener("click", (ev) => {{
  const link = ev.target.closest("[data-note]");
  if (link) {{
    ev.preventDefault();
    const targetId = link.getAttribute("data-note");
    if (targetId) openNote(targetId, true);
  }}
}});

document.getElementById("search-input").addEventListener("input", (ev) => {{
  const val = ev.target.value;
  buildSidebar(val);
  openNote(currentId, false);
}});

document.getElementById("menu-toggle").addEventListener("click", () => {{
  document.getElementById("sidebar").classList.toggle("open");
}});

document.getElementById("home-btn").addEventListener("click", () => {{
  document.getElementById("search-input").value = "";
  openNote(DEFAULT_ID, true);
}});

window.addEventListener("hashchange", () => {{
  const h = location.hash.replace(/^#/, "");
  if (h && byId.has(h)) openNote(h, false);
}});

const initialHash = location.hash.replace(/^#/, "");
openNote(byId.has(initialHash) ? initialHash : DEFAULT_ID, false);
</script>
</body>
</html>
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Exporta GameVault a un único archivo HTML autocontenido.")
    parser.add_argument(
        "--vault",
        default=str(Path(__file__).resolve().parents[1] / "GameVault"),
        help="Ruta a la carpeta GameVault",
    )
    parser.add_argument(
        "--output",
        default="/home/lamsaktp/Enciclopedia_LaPlacaDePetri.html",
        help="Ruta del archivo .html generado (fuera del repositorio por defecto)",
    )
    parser.add_argument(
        "--sin-secta-ni-diario",
        action="store_true",
        help="Excluye 03_La_Secta/ y 06_Diario/ para evitar spoilers o notas internas",
    )
    parser.add_argument(
        "--incluir-plantillas",
        action="store_true",
        help="Incluye la carpeta Plantillas/",
    )
    args = parser.parse_args()

    vault_dir = Path(args.vault).resolve()
    notes = collect_notes(vault_dir, args.sin_secta_ni_diario, args.incluir_plantillas)
    subtitle = (
        "Edición sin spoilers ni diario"
        if args.sin_secta_ni_diario
        else "Edición completa"
    )
    out_html = build_html(notes, subtitle)
    out_path = Path(args.output).resolve()
    out_path.write_text(out_html, encoding="utf-8")
    print(f"Generado: {out_path} ({len(notes)} notas, {len(out_html) // 1024} KB)")


if __name__ == "__main__":
    main()
