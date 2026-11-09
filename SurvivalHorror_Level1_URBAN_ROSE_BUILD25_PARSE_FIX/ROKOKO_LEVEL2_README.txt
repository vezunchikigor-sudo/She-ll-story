ROKOKO_LEVEL2 TEST BUILD

This build replaces the old large greybox with a finished two-room prototype:
- central hall
- library
- finished wood/parquet-style floors
- wainscot and crown trim
- carved-style doors/door panels
- archway between hall and library
- bookshelves, books, ladder, tables, busts, plants
- chandeliers and warm lights
- one light enemy in the library

Player:
- Visual source switched from the old pink Mixamo placeholder to the supplied Rokoko FBX 1790016838188.
- Rokoko exports 1790016838188, 1000117136, 1000117137 are included.
- AnimationBank imports the three Rokoko FBX clips alongside the existing clips.
- Controls/camera logic is otherwise preserved from BUILD16.

Important limitation:
The supplied project contains reference photos/videos of the intended GP appearance but does not contain a skinned 3D model of that exact woman/outfit. The Rokoko FBX exports contain the Rokoko/Newton actor mesh/skeleton, not the final game character. This build therefore uses the Rokoko actor as the mocap integration test body. Once the final GP 3D model is supplied, the same Rokoko animations can be retargeted to it.
