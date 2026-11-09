BUILD22 — MOBILE CONTROLS + CAMERA + MINIMAP + REFERENCE INTERIOR

Fixes in this build:
1. Mobile joystick now captures Android touch/drag globally in its own area.
2. Right-side camera look now captures touch/drag independently of the HUD buttons.
3. Action icons were re-cropped from the supplied Gameplay reference so each TextureButton contains only its own circle/icon, without neighboring-button pixels.
4. Action-button positions were recalibrated to the 2816x1584 Gameplay reference.
5. Crouch now changes the player collision height, lowers the visual character, and lowers the camera while crouched.
6. Minimap tap is handled from viewport coordinates; tapping the minimap opens a centered square 1:1 full-screen map and tapping the map closes it.
7. Hall and library wall visuals now use multiple 1920x1080 photographic surfaces derived from the supplied hall_clean / library reference images instead of visible graybox wall meshes. Collision geometry remains underneath.

Important: Godot 4.7.2 executable is not available in the build environment, so this archive was not Android-tested here.
