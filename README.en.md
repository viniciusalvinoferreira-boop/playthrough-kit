*[Leia em português](README.md)*

# Playthrough Kit

Record guitar playthrough videos without syncing audio by hand, and without
losing quality on export.

Two REAPER scripts: one aligns the camera video with the DAW audio on its own,
the other exports the final video **without re-encoding the picture**.

---

## Why it exists

People recording playthroughs usually pick between two bad options.

**Recording everything through OBS** with a phone as webcam avoids syncing, but
the video goes through a webcam app that recompresses it, and what reaches the
PC is a shadow of what the sensor captured. No OBS setting fixes that.

**Recording separately** keeps the camera quality, but costs half an hour
lining up waveforms by eye, every take.

This kit keeps the quality of the second and the speed of the first.

## What makes it different

On export, the kit never runs the video through an encoder. It uses
`ffmpeg -c:v copy`, which copies the video stream **bit for bit** and only
swaps the audio track.

The final file is literally the original camera video with different sound. You
can prove it by comparing the hash of both streams:

```
md5 of the ORIGINAL video : 97B94F22620753D5ABBF3967DAF39EA7
md5 of the FINAL video    : 97B94F22620753D5ABBF3967DAF39EA7
```

DaVinci Resolve, Premiere and REAPER's own render all re-encode the video. Here
it is never touched, and there is no such thing as better than untouched.

## Install

The recommended way is [ReaPack](https://reapack.com), which installs and
updates on its own. Under `Extensions → ReaPack → Import repositories`, paste:

```
https://raw.githubusercontent.com/viniciusalvinoferreira-boop/playthrough-kit/main/index.xml
```

Then `Browse packages`, filter by `playthrough` and install. The actions get
registered for you, no need to load scripts by hand.

Without ReaPack, download the repository and run `INSTALAR.bat`.

Either way you also need ffmpeg:

```
winget install Gyan.FFmpeg
```

**Messages in English:** open each script and change the line near the top:

```lua
local LANG = "pt"   -- change to "en"
```

## Before your first take: the muted-string hit

This is the one thing that usually goes wrong, and it is not a bug.

The sync looks for **the same sound in both files**. The video carries the
camera microphone; REAPER carries the pickup. For the alignment to have an
anchor, the event has to exist on both sides.

**A hand clap does not work.** It reaches the camera microphone, but it never
passes through the guitar pickup.

**What works** is a hard, dry hit on muted strings, that percussive "chunk". It
leaves through the pickup and travels through the air at the same time.

If you record with a **microphone** instead of a pickup (drums, vocals, a mic'd
amp), then a clap works fine, because your mic hears the room just like the
camera does.

Per take: hit record on the camera, hit record in REAPER, strike the strings
hard, wait two seconds, play. The order of the first two does not matter.

## How to use it

1. Open `File → Project templates → Playthrough`
2. Record the take, with the hit at the start
3. Move the camera file to your PC **over a cable**. Never through WhatsApp or
   Telegram, which recompress and throw away everything you saved
4. Drag the video onto the VIDEO track
5. Select **both** items and run the **sync**
6. Select **only** the video and run the **export**

## Required setting: 48 kHz

Video is always 48 kHz. Under `Options → Preferences → Audio → Device`, **tick
the box** `Request sample rate` and set **48000**, then restart REAPER.

The ticked box is what matters, not the number. Typing 48000 and leaving the
box unticked does nothing.

## Docs

| File | What for |
|---|---|
| [MANUAL-en.md](MANUAL-en.md) | full manual and the error code table |
| [TROUBLESHOOTING-en.txt](TROUBLESHOOTING-en.txt) | 4 steps when something breaks |
| [AI-CONTEXT.md](AI-CONTEXT.md) | paste into an AI along with your question |
| [CHANGELOG.md](CHANGELOG.md) | what changed in each version |
| [Teste/](Teste/) | two files to validate the install without recording |

Stuck? Run the `playthrough_diagnostico` script, which writes an environment
report, and take that report plus `AI-CONTEXT.md` to any AI assistant. That
combination solves most cases without anyone else involved.

## Requirements

- REAPER 7 on Windows (tested on 7.73)
- ffmpeg
- Any camera that records video with sound, a phone is fine
- Any way to get your instrument into REAPER: modeler, multi-effects, a mic'd
  amp, or DI with a plugin. The kit does not depend on any particular gear

## Support

The kit is free and stays free. If it saved you time, you can buy me a coffee:

**[ko-fi.com/vinialvino](https://ko-fi.com/vinialvino)**

No obligation at all. Reporting a bug, or just telling me it worked, helps
plenty too.
