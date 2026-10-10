---
name: geomesh-zeit-log
description: Log worked time into the GeoMesh Zeiterfassung via its HTTP API. Use only when explicitly invoked.
disable-model-invocation: true
argument-hint: '[scope, e.g. "heute", "seit dem letzten Report" or "add meeting from 13:30, 3h"]'
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion
---

# Zeit eintragen

1. Fix the period. Invoked **mid-conversation**, log this session's work, timed from T3 turns and commit timestamps because the conversation carries no clock. Invoked **standalone**, reconstruct the scope in the argument, defaulting to today. "Seit dem letzten Report" starts the day after Paul's newest own entry. Invoked **direct** ("add our meeting from 13:30, ging etwa 3 Stunden"), take the stated time and duration as fact and only work out what it was about.
2. Gather evidence for that period from every source below, T3 first.
3. `GET /api/entries` for the period. Skip or `PATCH` what is already there rather than creating a second copy, including shared meetings Simon already logged with Paul listed.
4. Show the draft as a table of date, time, duration, tags and note, with per-project totals. Raise every open point in one round, each with the reading you consider likeliest so answering is quick. Every entry that reaches the tracker is one the user has seen and confirmed.
5. `POST` the confirmed batch and report the ids.

Done when every hour of the working span is logged or dismissed by the user. Calls, mail on the phone and in-person sessions leave no trace on this PC, so a day accounted for only as far as the logs prove is not done.

## Counting rules

- An agent session is work from the first prompt to the end of the last turn. Gaps under 45 minutes between turns belong to the session, and so does whatever ran in the foreground meanwhile, League included.
- Projects that ran in parallel each get their full span, pinned with their own start and end. The overlap counts twice, on purpose.
- Duration only, without start and end, is for work done in scattered pieces with no clear span.
- An entry may cross midnight. It takes the start day as `date`, and `endMinutes` is smaller than `startMinutes`.
- Private work gets no entry: `bachelor-thesis` and anything else from Uni or HHU, the Rust projects under `D:\Programming\Rust`, `nix-config`, and the account migration in `Desktop\Migration`. Everything under `D:\Programming\GeoMesh\` is work.

Notes are German, in the shape `Projekt: kurze Sache`: `Kalender: WCAG / Accessibility work`, `Homepage: Update und Werbe klausel`. A few words, taken from the commit subjects of that span.

## API

Base `https://fastidious-bat-244.eu-west-1.convex.site`, header `Authorization: Bearer <key>`.

The key is not stored in this file. Read it from `D:\Programming\GeoMesh\time-tracker\README.md`, where it is the `key=` parameter of the live URL. A 401 means it was rotated, so read that file again.

| | |
|---|---|
| `GET /api/context` | `{people[], tags[]}`, the names that may be used |
| `GET /api/entries?from=&to=` | `{entries:[…]}` in an inclusive `YYYY-MM-DD` range |
| `POST /api/entries` | `{"entries":[…]}` returns `{ids:[…]}` |
| `PATCH /api/entries/<id>` | any subset of the same fields |
| `DELETE /api/entries/<id>` | returns the removed entry |

```json
{"date":"2026-07-27","startMinutes":540,"endMinutes":690,"durationMinutes":150,"people":["Paul"],"tags":["Chatpott","development"],"note":"Fehlerauswertung eingebaut"}
```

Times and durations are integer minutes, `startMinutes` and `endMinutes` counted from midnight. Send any two of start, end and duration; the third is derived and cannot be set independently.

Only Paul's work is tracked here, so every entry gets `"people":["Paul"]`, with others listed alongside him for shared meetings. Commits by `obzocker` are Simon's and are his to log.

`tags` must be non-empty, and mixes projects with activity types (`development`, `meeting`, `Orga`, `Marketing`, …). Entries usually carry one of each. Names must already exist, since the API returns 400 with the available list; they match case-insensitively. Repo to tag: `alumni-platform` is `Heine-Alumni`, `calendar` is `Kalender`, `survey` is `GeoMesh-Survey`, and the rest match by name. Work that fits no existing tag is a question for the user.

Umlauts passed inline to `curl -d` arrive as `U+FFFD`, so write the body to a UTF-8 file and send it with `--data-binary @file`.

## Evidence

**T3 Code** is the meta-harness Paul runs Claude Code and Codex through, and its database holds every turn of every project. This is the main source for development time. Query it with `bun` (Python is not installed), grouping turns per project with the 45-minute rule:

```ts
import { Database } from "bun:sqlite";
const db = new Database("C:/Users/paul/.t3/userdata/state.sqlite", { readonly: true });
const rows = db.query(`select p.title proj, tu.requested_at a, coalesce(tu.completed_at, tu.started_at, tu.requested_at) b
  from projection_turns tu join projection_threads t on t.thread_id = tu.thread_id
  join projection_projects p on p.project_id = t.project_id
  where tu.requested_at >= ?1 order by p.title, tu.requested_at`).all("2026-09-16T22:00");
```

Timestamps are UTC. `projection_threads.title` names what a thread was about.

**Codex sessions** started outside T3 live in `~/.codex/sessions/YYYY/MM/DD/*.jsonl`, with `cwd` and the first prompt near the top. Most are private errands in `~/Documents/Codex`.

**Git.** Commit subjects give the notes. Read a plain `git log`, since T3's per-turn checkpoints on `refs/t3/` would flood an `--all`:

```bash
for d in /d/Programming/GeoMesh/*/; do
  git -C "$d" log --since=2026-07-27T00:00 --until=2026-07-28T00:00 \
    --pretty="$(basename $d) %an %ad %s" --date=format:%H:%M
done
```

**ActivityWatch** at `localhost:5600` covers work without an agent: browser research, Discord meetings, the tracker itself. Buckets are `aw-watcher-window_phos`, `aw-watcher-afk_phos` and `aw-watcher-web-chrome_phos`. Send the `+` of the offset as `%2B`, because a literal one is rejected as invalid rfc3339, and add the Berlin offset to the UTC timestamps. `.data.title` and `.data.url` show which project a window belonged to. Use it to find non-agent work and to date it, and leave agent sessions to T3.

**Standup reports** from the WhatsApp Arbeitsreport group, when the user pastes them, list what each day was planned for. Plans slip by days, so match items to the evidence by content, not by weekday, and ask about items with no trace.

**Protokolle.** `D:\GeoMesh\Firmendokumente\Protokolle`, in subfolders per person and topic, is what a meeting was actually about.

**E-Mail.** The `protonmail` MCP (account `proton`) covers the business layer, but the bridge is often offline, and Paul often answers mail on his phone. Treat that as a gap to ask about.

**Projekte.** `D:\GeoMesh\Projekte\` on the NAS holds a folder per project, most of which map onto a tag and cover work that never touches a repo.
