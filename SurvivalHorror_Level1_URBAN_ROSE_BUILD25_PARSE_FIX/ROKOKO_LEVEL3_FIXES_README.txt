URBAN ROSE — Hall + Library / Rokoko + Intro Cutscene Fix

This build is a targeted test build based on the Hall/Library prototype.

FIXES IN THIS BUILD
- New Game now starts the supplied intro cinematic (converted to OGV for Godot VideoStreamPlayer/mobile-safe playback).
- Intro cinematic is trimmed before its final fade-to-black and crossfades into the live game camera.
- Live camera is temporarily framed to match the cinematic's final third-person knife shot, then restores the normal gameplay camera values.
- Player starts at the same hall entrance transform used by the cinematic transition and equips Knife before the transition.
- Rokoko test character no longer copies animation tracks from unrelated Mixamo/Rokoko skeleton paths. The embedded animation in the selected Rokoko FBX is used instead, avoiding the T-pose caused by invalid track paths.
- Player visual floor placement is calculated from imported mesh bounds so the test character does not start below the floor; CharacterBody baseline remains unchanged.
- Backward movement factor increased from 0.90 to 0.95 while preserving the existing movement/camera structure.
- Main-menu buttons now have text-only pressed feedback; no visible yellow focus/hitbox rectangle.
- Menu music remains routed through AudioManager so the later custom track can replace the current menu track without changing menu logic.

NOTES
- This is NOT the final skinned GP. The current Rokoko test mesh remains temporary, as requested.
- Full retargeting onto the final GP clothing/mesh is a separate next stage.
- The hall/library geometry remains a prototype reconstruction; it is not being presented as final photorealistic asset work.
