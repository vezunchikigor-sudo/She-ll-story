BUILD19 - mobile/gameplay fixes based on XRecorder_Edited_20261002_01.mp4

Fixed in this iteration:
1. Main menu buttons no longer draw duplicate yellow text. Labels remain in the artwork; press feedback is a subtle dark/inset press overlay.
2. Intro cutscene is displayed at true 9:16, preserving portrait composition. Tapping anywhere on screen skips it.
3. Live camera keeps the same tighter composition as the final cinematic frame instead of snapping back to the old wide camera on transition.
4. Rokoko locomotion no longer loops while the player is standing still. Idle holds a neutral frame; locomotion plays only while the joystick is moved.
5. Mobile action buttons are image-only circular buttons matching the supplied Gameplay.jpeg visual language. No text labels. Crouch is a dedicated high-z TextureButton and directly calls player.toggle_crouch().
6. Backward mobile movement now reaches the same top speed as forward movement when the joystick is pushed fully backward.
7. Imported Rokoko visual has a stronger floor offset safeguard to reduce sinking under the floor at spawn.

The final skinned GP is intentionally NOT added in this build; this remains the Rokoko integration test character as requested.
Menu music slot remains ready for the user's later custom music.
