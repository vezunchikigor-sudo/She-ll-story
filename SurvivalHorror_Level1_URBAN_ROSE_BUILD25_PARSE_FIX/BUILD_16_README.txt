BUILD 16 — based on BUILD 14 controls/combat baseline

Preserved from the successful BUILD 14 path:
- independent mobile touch handling for AIM / BAG / CROUCH / RELOAD / FIRE;
- camera and movement math baseline;
- weapon switching and long-range raycast combat;
- menu button alignment.

Changes in this build:
1. AIM and BAG are handled independently of the movement joystick again.
2. Crouch is handled independently of the movement joystick.
3. Main-menu button normal/hover/focus rectangles are fully transparent; press feedback remains without the yellow rectangle.
4. Player visual offset lowered to 0.18 so the feet meet the floor more closely than BUILD 15.
5. Walking/running/crouch speeds reduced again; lateral movement and rotation are additionally slowed, while the normal forward/camera convention remains unchanged.
6. Camera automatically pulls farther back while moving backward so the player remains visible.
7. Crouch-walk clip is trimmed from about 4 seconds onward; pistol-walk is shortened and root-motion position tracks are suppressed more broadly.
8. Shotgun keeps Shotgun_reload. Pistol/Uzi/Rocket use separate procedural reload motions instead of the shotgun clip.
9. Weapon hand attachment is moved closer to the palm.
10. Fire raycast range increased to 300 m; beyond 20 m there is an additional 5% miss chance. Obstacles still block the shot.
11. Zombie movement speed reduced by 10% in level spawn values.
12. Added a square 3 m-radius local minimap backed by the supplied mansion_floor1_map.jpg. It overlays walls, doors, static decor/furniture points, player, enemies and survivor. Tapping it opens a square full-level map; tapping again closes it. Mobile action buttons use their own UI touch targets instead of competing with the movement joystick.

Important source limitation:
The supplied 26 FBX files contain Shotgun_reload.fbx but do not contain dedicated Pistol/Uzi reload FBX clips. Therefore this build uses distinct procedural reload motions for pistol and Uzi rather than falsely reusing the shotgun animation.
