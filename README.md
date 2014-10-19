Processing tracking system
========================

This is a simple human/pet tracking sketch based on pixel diff between two captures.

1 - Choose your mode 
--------------------

You can set the "coolEffect" variable so as to get the differents level of the process:
 0: A simple following dot
 1: Get center of main moving regions
 2: Get the detail of moving regions
 3: Get the detail of modified pixels
 4: Remove the image
 5: Get only modified pixels
 6: Get only modified regions
 
2 - Set definition level parameters
-----------------------------------

The threshold is the level of difference of colour for a same pixel between two frames so as he can be considered as modified. This has no effet on performances
The blob_scale parameter define the number of squares which will define modified regions. Higher is lower.
The children_threshold parameter define the number of primitive region superimposing each other required so as no to be considered as noise

You can also define the resolution of the camera and the number of frame per second on line 31

3 - Enjoy
---------

Some considerations
===================

When the sketch starts if may be very slow but it's "normal"
If your camera is not stable, the center point will be even less accurate
The main dot only follow one person. If there are multiple moving entities, it will show the average of them.
