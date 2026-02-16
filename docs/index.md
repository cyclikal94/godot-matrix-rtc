---
layout: page
title: Godot Matrix RTC
---

This is a sample project and associated Godot Plugin which can be used to interact with MatrixRTC.

The sample project and scenes can be used to have a pre-created UI (Join / Leave) via the exported project which will resize nicely size within any widget layout (Horizontal / Vertical).

## How to use

You can install this plugin by either:

1. Downloading the latest [release](https://github.com/cyclikal94/godot-matrix-rtc/releases) from GitHub
1. Install via the Godot Asset Library

## Element Call SDK dist

This addon expects `addons/godot-matrix-rtc/dist` to exist.

- Release builds: `.github/workflows/release.yml` clones `element-hq/element-call`, runs `yarn build:sdk`, and packages the generated `dist` into the addon zip.
- Local development: if `dist` is missing, build it manually:
  1. Clone `https://github.com/element-hq/element-call/`
  1. Run `yarn build:sdk`
  1. Copy `dist` to `addons/godot-matrix-rtc/dist`

During web export, the editor plugin copies `addons/godot-matrix-rtc/dist` into the export output folder as `dist/`.

## Deloying as a widget in Matrix

Deploy your exported build then use:

```
/addwidget https://example.com/GodotMatrixRTC.html?widgetId=$matrix_widget_id&perParticipantE2EE=true&userId=$matrix_user_id&deviceId=$org.matrix.msc3819.matrix_device_id&baseUrl=$org.matrix.msc4039.matrix_base_url&roomId=$matrix_room_id
```

Replacing `example.com` with where you have deployed and `GodotMatrixRTC.html` with the name of the exported HTML, if you have changed from the default name defined by the Export Preset.

## Credits

- This was largely a refactor (turning into a Godot plugin) of the UI polish I did to [toger5/Godot-MatrixRTC-Keyboard-Kart](https://github.com/toger5/Godot-MatrixRTC-Keyboard-Kart). So all credit goes to [@toger5](https://github.com/toger5) for the original code 👍
- See the FOSDEM'26 talk by Timo Kandra, Valere Fedronic and Robin Townsend - [MatrixRTC x Godot - A Battle Royale](https://fosdem.org/2026/schedule/event/UW9GKA-matrixrtc-godot-battle-royale/)
- Nadine Minigawa for the `[mRTC]` logo and design advice for overal logo 🙏
- [Matrix Workation, Thailand Edition 🇹🇭](https://matrix.org/blog/2026/02/13/this-week-in-matrix-2026-02-13/#matrix-workation-thailand-edition-th)
- You should check out [Matrix](https://matrix.org/)