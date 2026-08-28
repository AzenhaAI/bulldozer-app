# BullDozer for Windows

A window around the live site, the same idea as the Mac build: it opens
`azenha.ai/bulldozer` rather than carrying a copy of the data, so it never shows
stale numbers and never needs rebuilding when a dataset is refreshed.

Built by `.github/workflows/build-windows.yml` on a Windows runner (Tauri → NSIS
installer), because an `.exe` cannot be produced from macOS. Run it from the
Actions tab; the installer is committed to `store/windows/` and attached to the
run.

Why a wrapper rather than a Flutter Windows build: the Flutter app has no
`windows/` target set up, and a native build would have to be rebuilt and
re-shipped for every data change. The wrapper is ~2 MB and always current.
