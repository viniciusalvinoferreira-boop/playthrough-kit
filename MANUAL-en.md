*[Manual em português](LEIA-ME.md)*

# Playthrough Kit v1.6

Record guitar playthrough videos without syncing audio by hand, and without
losing quality on export.

Works on **REAPER 7 / Windows**.

---

## The problem

People recording playthroughs usually pick between two bad options.

**Option 1, OBS.** You use the phone as a webcam, record everything at once and
skip syncing. But the phone goes through a webcam app that recompresses, and
what reaches the PC is a shadow of what the sensor captured. No OBS setting
fixes it, it is a ceiling of that route.

**Option 2, recording separately.** The camera records at full quality, REAPER
records good audio, and then you spend half an hour lining up waveforms by eye,
every take.

This kit keeps the quality of option 2 and the speed of option 1.

---

## What it does

**1. Syncs by itself.** One script finds the same transient in both files and
moves the video into place. Takes a second.

**2. Exports without re-encoding the video.** This is the part that matters. The
script renders audio only and uses ffmpeg in `-c:v copy` mode, which copies the
video stream **bit for bit**, never decoding or re-encoding.

The final file is literally the original camera video with a different audio
track. Not "almost identical", identical: you can compare the hash of both
streams and they match. Resolve, Premiere and REAPER's own render all
recompress. There is no such thing as better than not touching it.

---

## Requirements

- REAPER 7 (tested on 7.73), Windows
- ffmpeg (the installer offers to install it for you)
- Any camera that records video with sound, a phone is fine
- Any way to get your instrument into REAPER: modeler, multi-effects unit, a
  mic'd amp, or DI with an amp plugin. The kit does not depend on any particular
  gear

The camera's audio does not need to be good. It serves only as a sync reference
and is discarded on export, never reaching the final file.

---

## Install

Run **INSTALAR.bat**. It copies the files and offers to install ffmpeg. It only
touches two folders inside `%APPDATA%\REAPER`, nothing else.

Then, inside REAPER, register the scripts:

1. `Actions` → `Show action list`
2. `New action` → `Load ReaScript...`
3. Pick the three files in `%APPDATA%\REAPER\Scripts\`:
   - `playthrough_sync_video.lua`
   - `playthrough_export_mux.lua`
   - `playthrough_diagnostico.lua`

Worth assigning shortcuts to the first two (`Add shortcut`, same window).
Suggestion: `Shift+S` for sync, `Shift+E` for export.

The template shows up on its own under `File` → `Project templates` →
`Playthrough`.

**Installing through [ReaPack](https://reapack.com) instead** skips the manual
registration entirely. Import this repository URL:

```
https://raw.githubusercontent.com/viniciusalvinoferreira-boop/playthrough-kit/main/index.xml
```

## Message language

Script messages ship in Portuguese. To switch to English, open each script and
change the line near the top:

```lua
local LANG = "pt"   -- change to "en"
```

Error codes are identical in both languages, so `PT-03` means the same thing
either way.

---

## Test the install without recording

Before your first real take, spend two minutes here. This separates "installed
wrong" from "recorded wrong", which are very different problems.

The `Teste/` folder holds two files with a **known** 3 second offset.

1. Drag `TESTE_video.mp4` and `TESTE_guitarra.wav` into REAPER
2. Leave both starting at position **0**
3. Select both
4. Run `playthrough_sync_video`

The console must show:

```
video moved          : +3000.0 ms
```

A millisecond or two either way is normal. What it must not do is land far from
that.

**Got 3000:** clean install. If something fails later, it is the recording, and
almost always the marker.

**Did not:** the problem is the install or the environment. Run
`playthrough_diagnostico` and read `TROUBLESHOOTING-en.txt`.

---

## READ THIS: the muted-string hit

This is the one thing that usually goes wrong, and it is not a bug.

For the sync to work there must be **an event that appears in both signals at
the same time**. The video carries the camera's microphone. REAPER carries the
pickup. The script looks for the same transient in both.

**A hand clap does not work** with a pickup or DI. It reaches the camera
microphone, but never passes through the guitar pickup. On REAPER's side there
is nothing to match.

**What works:** a hard, dry hit on muted strings, that percussive "chunk". It
leaves through the pickup and travels through the air at the same time.

**If you record through a microphone** (drums, vocals, a mic'd amp, acoustic
guitar), a clap works perfectly, because your mic hears the room just like the
camera does. The real rule is not "hit the strings", it is **the marker must
exist in both signals**.

So the ritual for each take is:

1. Record on the camera
2. Record in REAPER
3. **Hit**, hard
4. Wait one or two seconds
5. Play

The order of the first two does not matter. If you hit record in REAPER after
the camera, the video would need to start before zero on the timeline, and the
script handles that by pushing the other items forward. It lines up either way.

Do the hit **early**, in the first few seconds. The script looks for the marker
in the first 12 seconds, and the more silence there is before the music comes
in, the easier it is to tell the hit apart from everything else.

---

## Workflow

1. `File` → `Project templates` → `Playthrough`
2. Record the take, with the hit at the start
3. Move the camera file to your PC **over a cable**. Never through WhatsApp or
   Telegram, which recompress and throw away everything you saved
4. Drag the file onto the VIDEO track
5. Select **both** items (video and audio) and run the **sync**
6. Select **only** the video item and run the **export**

A `name_final.mp4` file appears in the same folder as the original video.

---

## Adjusting for your interface

The template ships with the instrument on **stereo input 1/2**, the most common
case. If yours arrives on other inputs, click the track's record arm button and
pick the right one. Save it as your own template afterwards, under
`File` → `Project templates` → `Save as project template`.

If your processor is mono (no stereo delay or reverb), use a mono input and save
half the file size.

---

## Required setting: 48 kHz

Video is always 48 kHz. If your project or interface sit at 44.1 kHz, REAPER
resamples silently and long takes can drift.

`Options` → `Preferences` → `Audio` → `Device`: **tick the box**
`Request sample rate` and leave **48000** in it. Then **restart REAPER**,
because changing the rate requires reopening the driver.

The ticked box is what matters, not the number. Typing 48000 and leaving the box
unticked does nothing: REAPER keeps accepting whatever rate the interface is
using, and the number just sits there for decoration.

The scripts warn you if the audio is running outside 48 kHz.

---

## Common problems

Every error message from the kit carries a code in brackets, like `[PT-03]`.
Look the code up here:

| Code | What happened | Cause | Fix |
|---|---|---|---|
| **PT-01** | Wrong selection | Number of selected items does not match | Sync wants 2 items (video and audio). Export wants 1 (video only) |
| **PT-02** | Could not tell video from audio | Both are video, neither is, or the extension is not recognized | Valid extensions: mp4, mov, m4v, mkv, avi, webm |
| **PT-03** | Marker not found | No hit, or too weak | Re-record with a hard hit on muted strings at the start |
| **PT-04** | Silent audio, or not decoding | REAPER cannot read the audio in that file | Install LAV Filters, or record H.264 instead of HEVC |
| **PT-05** | Item trimmed or playrate changed | The math assumes a whole item at normal speed | Sync first, trim later |
| **PT-06** | Audio running outside 48 kHz | Video is always 48 kHz | `Preferences` → `Audio` → `Device`: **tick** `Request sample rate` with 48000, then restart REAPER |
| **PT-07** | ffmpeg not found | Not installed, or installed while REAPER was open | `winget install Gyan.FFmpeg`, then close and reopen REAPER |
| **PT-08** | The render did not produce the WAV | Background rendering is on | Wait for it to finish and run again |
| **PT-09** | ffmpeg failed to mux | Several possible reasons | Full error goes to the console: `View` → `Show console output` |
| **PT-10** | Suspicious marker | Found near the end of the search window, possibly the first note instead of the hit | Check by ear. Hit harder and wait longer before playing |

One symptom with no code: **in sync at the start, drifting by the end**. That is
a sample rate outside 48 kHz, or a take long enough for the camera and interface
clocks to drift apart. Record per song, not per session.

Stuck on something not listed? Open **TROUBLESHOOTING-en.txt**, which has the
full routine, including how to ask an AI for help in a way that actually works.

---

## Using an AI to help?

There is an **AI-CONTEXT.md** file next door. It explains the architecture, the
magic values and the known failure modes of this kit.

Paste its contents into ChatGPT, Claude or whatever you use, along with your
question. The AI will understand what each piece does instead of guessing,
because the less obvious parts (why the marker must be a string hit, why the
script hunts for ffmpeg instead of just calling it) are documented there.

---

## Notes

ffmpeg does **not** ship inside this package, on purpose. The installer calls
winget and the binary comes straight from the source. That way nobody is
redistributing third party software, and you get updates normally.

The scripts are open source and commented. Tweak away: the tuning parameters all
sit at the top of each file.
