BUILD23 — gameplay fixes

1. Crouch visual now uses one cached standing floor reference, so toggling crouch cannot lift the character tens of centimeters.
2. Current Rokoko locomotion clip is looped before its turn section to prevent the character from turning while the player continues forward/backward.
3. Hall and library photographic surfaces were rebuilt as continuous overlapping room skins using the supplied 1920x1080 reference-derived textures; prototype wall gaps are covered.
4. Boss no longer chases the player after the survivor is healed. The player must approach the stationary boss.
5. Boss HP reduced to 350 and boss collision enlarged; aiming also has a narrow forward-cone fallback so a nearly-centered boss is reliably damaged.
6. GP walking speed is 1.75 m/s and is slightly faster than the 1.70 m/s enemy and 1.72 m/s boss speeds; run remains faster.
7. Minimap touch handling remains independent from action buttons.

Godot 4.7.2 Android runtime testing was not available in the build environment.
