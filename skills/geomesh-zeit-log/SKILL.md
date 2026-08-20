---
name: geomesh-zeit-log
description: Log worked time into the GeoMesh Zeiterfassung via its HTTP API. Use only when explicitly invoked.
disable-model-invocation: true
argument-hint: [scope, e.g. "heute" or "add meeting from 13:30, 3h"]
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion
---

# Zeit eintragen

1. Fix the period. Invoked **mid-conversation**, log this session's work, timed from ActivityWatch and commit timestamps because the conversation carries no clock. Invoked **standalone**, reconstruct the scope in the argument, defaulting to today. Invoked **direct** ("add our meeting from 13:30, ging etwa 3 Stunden"), take the stated time and duration as fact and only work out what it was about.
2. Gather evidence for that period from every source below.
3. `GET /api/entries?from=<day>&to=<day>`. Skip or `PATCH` what is already there rather than creating a second copy.
4. Show the draft as a short list of time, duration, tags and note. Raise every open point in one round, each with the reading you consider likeliest so answering is quick: which tags fit, whether a block counts as work, where one entry ends and the next begins, whether a gap was a break. Every entry that reaches the tracker is one the user has seen and confirmed.
5. `POST` the confirmed batch and report the ids.

Done when every block in the working span is logged or dismissed by the user. Calls, sensor work and admin can leave no trace at all, so a day accounted for only as far as git proves it is not done.

Notes are German, in the shape `Projekt: kurze Sache`: `Kalender: WCAG / Accessibility work`, `Homepage: Update und Werbe klausel`. A few words, not a sentence. They read like the standup items the day was planned from, and that plan doubles as a checklist, so items with no trace in the evidence are worth asking about.

Work that ran in parallel with another block, or in scattered pieces, goes in with duration only and no `startMinutes` or `endMinutes`, rather than pinned to an invented slot.

## API

Base `https://fastidious-bat-244.eu-west-1.convex.site`, header `Authorization: Bearer <key>`.

The key is not stored in this file. Read it from `D:\Programming\GeoMesh\time-tracker\README.md`, where it is the `key=` parameter of the live URL. A 401 means it was rotated, so read that file again.

| | |
|---|---|
| `GET /api/context` | `{people[], tags[]}`, the names that may be used |
| `GET /api/entries?from=&to=` | entries in an inclusive `YYYY-MM-DD` range |
| `POST /api/entries` | `{"entries":[…]}` returns `{ids:[…]}` |
| `PATCH /api/entries/<id>` | any subset of the same fields |
| `DELETE /api/entries/<id>` | returns the removed entry |

```json
{"date":"2026-07-27","startMinutes":540,"endMinutes":690,"durationMinutes":150,"people":["Paul"],"tags":["Chatpott","development"],"note":"Fehlerauswertung eingebaut"}
```

Times and durations are integer minutes, `startMinutes` and `endMinutes` counted from midnight. Send any two of start, end and duration; the third is derived and cannot be set independently.

This is Paul's laptop and only his work is tracked here, so every entry gets `"people":["Paul"]`. Work belonging to Simon or Ben is theirs to log, and a shared meeting still goes in as Paul's entry with the others listed alongside him.

`tags` must be non-empty, and mixes projects (`Chatpott`, `Time Tracker`, `Kalender`, `Alumni`, …) with activity types (`development`, `meeting`, `Orga`, `Marketing`, …). Entries usually carry one of each, and project tags line up with the repos under `D:\Programming\GeoMesh\`. Person and tag names must already exist, since the API does not create them and returns 400 with the available list; names match case-insensitively. Work that fits no existing tag is a question for the user.

Umlauts passed inline to `curl -d` arrive as `U+FFFD`, so write the body to a UTF-8 file and send it with `--data-binary @file`.

## Evidence

Start with `GET /api/context` for the allowed names, and a two-week `GET /api/entries` range to see how notes are phrased.

**Git.** Commits across all repos, as a plain `git log`. T3 Code's per-turn checkpoints live on `refs/t3/` and would flood an `--all`:

```bash
for d in /d/Programming/GeoMesh/*/; do
  git -C "$d" log --since=2026-07-27T00:00 --until=2026-07-28T00:00 \
    --pretty="$(basename $d) %ad %s" --date=format:%H:%M
done
```

**ActivityWatch.** `localhost:5600`, buckets `aw-watcher-window_phos`, `aw-watcher-afk_phos` (active vs. away), `aw-watcher-web-chrome_phos`. Send the `+` of the offset as `%2B`, because a literal one is rejected as invalid rfc3339. Timestamps come back in UTC, so add the Berlin offset when reading them:

```bash
curl -s "http://localhost:5600/api/0/buckets/aw-watcher-window_phos/events?start=2026-07-27T00:00:00%2B02:00&end=2026-07-27T23:59:59%2B02:00&limit=-1" \
  | jq -r 'group_by(.data.app)|map({app:.[0].data.app,min:(map(.duration)|add/60|round)})|sort_by(-.min)|.[]|"\(.min)\t\(.app)"'
```

Drop `group_by` and read `.data.title` to see which project an editor or browser block belongs to. Exclude personal use (`fallingsand`, games, private browsing).

**Protokolle.** `D:\GeoMesh\Firmendokumente\Protokolle`, in subfolders per person and topic, is what a meeting was actually about.

**E-Mail.** The `protonmail` MCP (account `proton`) covers the business layer, but the bridge is often offline. Treat that as a gap rather than blocking on it.

**Projekte.** `D:\GeoMesh\Projekte\` on the NAS holds a folder per project (`CCF`, `Bürgerbeteiligung Oberhausen`, `Jung und Parkinson`, `KI-Werkstatt`, …), most of which map onto a tag and cover work that never touches a repo.
