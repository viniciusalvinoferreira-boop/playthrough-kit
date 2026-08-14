# Context for AI assistants

This file is meant to be pasted whole into an assistant (ChatGPT, Claude,
Copilot) together with the user's question. It describes the Playthrough Kit:
what each piece does, why it was built that way, and where it tends to break.

If you are an AI reading this: the user is probably trying to install or fix
something here. The **Failure modes** and **Do not suggest this** sections cover
most cases. Prefer the answers below over your own assumptions, because several
decisions here are counterintuitive and were made for a reason.

## Ask for these two things before theorizing

The kit ships with its own diagnostics. Use them instead of asking the user to
describe symptoms.

**1. The environment report.** In REAPER: `Actions > Show action list >
playthrough_diagnostico`. It changes nothing and prints REAPER's version, the
ffmpeg path, the sample rate and an analysis of the selected items, already
tagged with the relevant error codes. Ask for the whole text.

**2. The result of the bundled test.** The `Teste/` folder has two files with a
known 3 second offset. Dragged into REAPER at position 0 and synced, the console
must print `+3000.0 ms`, give or take a millisecond or two. People who installed
via ReaPack do not get these files: they live in the repository, under `Teste/`.

That test splits the diagnosis in half:

- **Got 3000:** the install is fine. The problem is in the user's recording, and
  in almost every case it is the marker (see the section about it below).
- **Did not get 3000:** the problem is the install or the environment, and the
  report from step 1 will point at it.

Do not skip that test. It kills half the hypotheses in two minutes.

---

## What the kit does

It automates guitar playthrough production in REAPER:

1. Automatically syncs the camera video with the audio recorded in the DAW
2. Exports the final video **without re-encoding the video stream**

Item 2 is the core value. The final video is bit for bit identical to what came
out of the camera, only with the audio track replaced.

## Files, and where they live

| File | Destination | Role |
|---|---|---|
| `playthrough_sync_video.lua` | `%APPDATA%\REAPER\Scripts\` | aligns video and audio |
| `playthrough_export_mux.lua` | `%APPDATA%\REAPER\Scripts\` | renders and muxes |
| `playthrough_diagnostico.lua` | `%APPDATA%\REAPER\Scripts\` | environment report, changes nothing |
| `Playthrough.RPP` | `%APPDATA%\REAPER\ProjectTemplates\` | project template |
| `Teste/` | stays in the repo | two files with a known 3 s offset |
| `INSTALAR.bat` | installs nothing of itself | copies the above |

The three scripts are independent of each other: each works alone, with no
shared module. The ffmpeg lookup is duplicated in the export and the diagnostic
on purpose, so installing one without the other never breaks anything.

Scripts still have to be registered manually through
`Actions > Show action list > New action > Load ReaScript`, unless installed via
ReaPack, which registers them for you. This is deliberate: registering from
outside would mean editing `reaper-kb.ini`, and REAPER rewrites that file on
exit, so an external edit with the program open would be discarded or would
corrupt existing shortcuts.

## Message language

Each script has a `local LANG = "pt"` line near the top, which switches all
messages between Portuguese and English. Error codes are identical in both
languages.

If a user reports a message in a language you did not expect, that is why. The
code between brackets is what identifies the problem, not the wording.

---

## How the sync works

It expects two selected items: one video (detected by extension) and one audio.

For each one it:

1. Opens an `AudioAccessor` over the take
2. Scans the first `SEARCH_WINDOW` seconds (12 by default) building a coarse
   envelope, one peak every 20 ms
3. Takes the **noise floor** from the 20th percentile of that envelope
4. Sets the threshold at `noiseFloor * 10`, with a safety floor of 5% of the
   window peak and a ceiling so something always crosses
5. Finds the **first** point crossing that threshold, and moves the video item

An implementation detail that matters: samples are read with `numchannels = 1`.
With a single channel, interleaved and planar layouts coincide, so the
transient position is correct regardless of REAPER's internal buffer
convention. With 2 channels the result would depend on that convention. **Do
not "optimize" this into stereo reading.**

### Why the threshold comes from silence, not from the peak

Earlier versions took the window peak and looked for the first point above 50%
of it. That works on pickup audio, where the initial hit is the loudest event,
and **fails on camera microphone audio**, where the music is far louder than the
hit. The hit never got near 50%, and the script marked a random point inside the
music.

Anchoring on the room noise instead survives music that ends up ten times louder
than the marker.

### The marker must exist in both signals

This is the concept everyone gets wrong, AIs included.

The video carries the camera's microphone. REAPER carries the instrument's
pickup. Two different worlds. For the sync to have an anchor, the event must
appear in both.

- **A hand clap does not work** with a pickup or DI. It reaches the camera mic,
  never the pickup.
- **A clapperboard does not work.** Same reason.
- **What works:** a hard, dry hit on muted strings. It leaves through the pickup
  and travels through the air at the same time.

**Important exception:** if the user records through a **microphone** (drums,
vocals, a mic'd amp, acoustic guitar), then a clap works perfectly, because
their mic hears the room just like the camera does. The rule is not "always hit
the strings", it is "the marker must exist in both signals".

If a user reports the sync got it wrong, the first question is always whether
there was a marker and whether it was loud.

### When the video would land before zero

Whoever hits record on the camera before hitting record in REAPER (that is,
everyone) ends up with a video that would need a negative position to line up.
REAPER does not accept that: it clamps the item at 0 and the alignment silently
goes wrong.

The script detects this, puts the video at 0 and moves **every other item**
forward by the same amount. Alignment between audio tracks is preserved because
they all move together. Both recording orders work identically.

---

## How the export works

1. Sets a time selection over the video item, plus a 100 ms tail
2. Configures the render and renders **audio only** for that range, as 24 bit WAV
3. Calls ffmpeg to join the original video with that WAV, using `-c:v copy`
4. Deletes the temporary file it used to build the command

The command is:

```
ffmpeg -y -i <video> -i <wav> -map 0:v:0 -map 1:a:0 \
       -c:v copy -c:a aac -b:a 320k -movflags +faststart -shortest <output>
```

`-c:v copy` is the heart of everything. The video stream never goes through a
decoder or an encoder.

### Why the 100 ms tail

REAPER's render comes out a few microseconds **shorter** than the requested
range, from sample rounding. `-shortest` cuts by the shortest stream, so in a
real take **12 microseconds** were enough for ffmpeg to drop the last video
frame.

With the tail, the video is always the shortest stream, the cut lands on the
spare audio, and no frame is lost.

### Why a temporary .bat

Building that command line with quotes directly through `ExecProcess` is
fragile, especially with paths containing spaces or accented characters.

---

## Magic values, and why they are what they are

**`1024` and `1026` in the template's `REC` line.** REAPER encodes the record
input like this: `0..N` are mono inputs (0-based), and `1024 + N` is a stereo
pair starting at channel N. So:

- stereo input 1/2 = `1024 + 0` = **1024** (what the template ships with)
- stereo input 3/4 = `1024 + 2` = **1026**
- mono input 3 = **2**

MIDI input is **4096**.

**`ZXZhdxgAAQ==` in `RENDER_FORMAT` and in the `.RPP`.** That is REAPER's render
config for 24 bit WAV. Decoding the base64: `evaw` ("wave" backwards, the format
cookie) followed by byte `0x18`, which is 24 in decimal, the bit depth. Setting
it from the script makes the export independent of whatever the user has open in
the render dialog.

**`41824` in `Main_OnCommand`.** The "render using the most recent settings"
command, which renders without opening a dialog.

**The video track ships muted.** Intentional. The sync reads audio straight from
the file through the `AudioAccessor`, which works fine on a muted track. Muted,
the camera mic never leaks into the final mix. Anyone who unmutes it to check
alignment must mute it again before exporting.

**`VIDEO_AUDIO_OFFSET_MS = 21.3` in the sync.** AAC priming compensation, and
not a made up number.

AAC encoders insert a block of silence at the start of the stream, called
priming, typically 1024 samples. At 48 kHz that is 21.33 ms. Players that read
the metadata discard it; REAPER **does not** when serving audio through the
audio accessor. So the video audio arrives about 21 ms late relative to the
picture, and without compensation the alignment inherits that error.

Verify it on any file with
`ffprobe -show_entries stream=initial_padding`.

If the video audio is PCM (some `.mov` files), the right value is `0`. If it is
AAC at 44.1 kHz, it is `23.2` (1024/44100).

Do not remove this compensation thinking it is a hack. Without it the sync is
systematically 21 ms off on any phone video.

**Where ReaPack installs.** Not the same folder as `INSTALAR.bat`. The installer
writes to `Scripts\`, ReaPack writes to a subfolder of its own. That is why the
diagnostic locates files through `get_action_context()` (where am I) instead of
checking a fixed path. Checking a fixed path produced false "NOT FOUND" reports
for people who had installed correctly through ReaPack.

---

## The PATH problem, and why the script hunts for ffmpeg

A Windows process inherits the `PATH` that existed when it started. Anyone who
installs ffmpeg while REAPER is already open ends up with a REAPER that cannot
see ffmpeg, even with a perfect install. Calling plain `ffmpeg` would fail with
a message that helps nobody.

On top of that, winget installs into a folder with the version in its name
(`ffmpeg-9.0-full_build`), which changes on every update.

So `findFFmpeg()` looks, in order: next to the script itself, in winget's
package folder (matching the `Gyan.FFmpeg` prefix), in winget's links folder, in
common manual install paths, and finally asks Windows with `where ffmpeg`. It
returns an absolute path, which works regardless of the process PATH.

## Sync assumptions

The math assumes:

- `playrate = 1.0` on both items
- items not trimmed at the start (`D_STARTOFFS = 0`)
- the marker sits within the first 12 seconds

The script detects the first two and asks before continuing. The guidance is
always **sync first, trim later**.

## Sample rate, and a mistake we already made here

`PROJECT_SRATE` is **not** the rate the audio is running at. It only applies
when `PROJECT_SRATE_USE` is on; with that flag off, the number sits in the
project with no effect and the audio interface is in charge.

Up to version 1.2 the scripts read only `PROJECT_SRATE` and raised PT-06 at
people whose interface was correctly at 48 kHz. The correct read is:

```lua
local _, devSr = reaper.GetAudioDeviceInfo("SRATE", "")
local actual = (projUse ~= 0) and projSr or tonumber(devSr)
```

If a user complains about PT-06 swearing they set 48 kHz, ask for the kit
version. Below 1.3, the alarm may be false.

Fix in REAPER: `Options > Preferences > Audio > Device`, **tick the box**
`Request sample rate` with 48000, and restart. The box is what matters: typing
the number with the box unticked changes nothing.

Clock drift note: the camera and the audio interface have independent clocks. On
takes of 3 to 5 minutes the deviation is irrelevant. On takes of 20 minutes or
more it can add up to a few frames by the end. The guidance is to record per
song, not per session.

---

## Failure modes

Every message carries a `[PT-xx]` code. If the user quotes a code, go straight
to that row.

| Code | Cause | Fix |
|---|---|---|
| **PT-01** | wrong selection | sync wants 2 items (video and audio), export wants 1 (video only) |
| **PT-02** | could not tell video from audio | recognized extensions: mp4, mov, m4v, mkv, avi, webm |
| **PT-03** | no marker, or too weak | re-record with a hard hit on muted strings |
| **PT-04** | REAPER cannot decode that file's audio | install LAV Filters, or record H.264 instead of HEVC |
| **PT-05** | item trimmed or playrate other than 1.0 | sync first, trim later |
| **PT-06** | audio running outside 48 kHz | `Preferences > Audio > Device`, **tick** `Request sample rate` with 48000 and restart |
| **PT-07** | ffmpeg missing, or installed while REAPER was open | `winget install Gyan.FFmpeg`, then reopen REAPER |
| **PT-08** | background render still running | wait and run again |
| **PT-09** | ffmpeg failed to mux | full error in the console: `View > Show console output` |
| **PT-10** | marker found near the end of the window, likely the first note | louder hit, wait longer before playing |

Two symptoms with no code:

- **camera mic audio in the final file:** the video track was unmuted. Mute it
  again before exporting
- **in sync at the start, drifting by the end:** project outside 48 kHz, or a
  take long enough for the clocks to drift. Record per song

---

## Do not suggest this

Things that look like good ideas and are not, in this specific context:

**Do not suggest re-encoding the video.** The whole point of the kit is
`-c:v copy`. Any suggestion to "export through Resolve" or "render the video
from REAPER" undoes the only real gain it delivers. If the user needs cuts or
color work, then an editor is necessary, but that is a different workflow, not a
fix for this one.

**Do not suggest a clap, clapperboard or flash** as the sync marker for pickup
or DI recording. See the marker section above, including the microphone
exception.

**Do not edit `reaper-kb.ini` or `reaper.ini` while REAPER is open.** It
rewrites those files on exit, so the edit is lost, or worse, conflicts with what
was in memory.

**Do not bundle the ffmpeg binary with the kit.** The gyan.dev full build is
GPL-3, and redistributing brings license obligations. Installing via
`winget install Gyan.FFmpeg` avoids the whole problem, since nothing is
redistributed.

**Do not switch the sync to 2 channel reading.** See the algorithm section.

**Do not tell people to transfer video over WhatsApp or Telegram.** They
recompress and throw away exactly the quality the kit exists to preserve. Use a
cable.

**Do not invent hardware requirements.** The kit does not care what makes the
sound. Any modeler, multi-effects unit, mic'd amp, or DI with a plugin works,
and any camera that records sound works. The camera's microphone does not even
need to be good: that audio never reaches the final file, it exists only as a
sync reference and is discarded on export.

---

## Reference environment

Software the kit was developed and tested on:

- Windows 11
- REAPER 7.73 x64
- ffmpeg 9.0 (gyan.dev full build, via winget)

That is the whole requirement list. REAPER 7 on Windows matters because the
scripts call `cmd.exe` and build paths with backslashes. Porting to macOS means
changing the process call and the path handling.
