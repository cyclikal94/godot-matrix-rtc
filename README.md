# Godot x MatrixRTC

This is a sample project and associated Godot Plugin which can be used to interact with MatrixRTC.

The sample project and scenes can be used to have a pre-created UI (Join / Leave) via the exported project which will resize nicely size within any widget layout (Horizontal / Vertical).

## How to use

You can install this plugin by either:

1. Downloading the latest [release](https://github.com/cyclikal94/godot-matrix-rtc/releases) from GitHub
1. Installing via the Godot Asset Library

## Element Call SDK dist

This addon expects `addons/godot-matrix-rtc/dist` to exist.

- Release builds: `.github/workflows/release.yml` clones `element-hq/element-call`, runs `yarn build:sdk`, and packages the generated `dist` into the addon zip.
- Local development: if `dist` is missing, build it manually:
  1. Clone `https://github.com/element-hq/element-call/`
  1. Run `yarn build:sdk`
  1. Copy `dist` to `addons/godot-matrix-rtc/dist`

During web export, the editor plugin copies `addons/godot-matrix-rtc/dist` into the export output folder as `dist/`.
