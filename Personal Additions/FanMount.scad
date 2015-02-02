// TODO: Make circular hole for fan, and flip nuts for fan mount.

use <MCAD/nuts_and_bolts.scad>

$fn=200;

angle=45;
thickness=5;
bottomWidth=15;
sidePlateLength=20;

module EndEffector()
{
	translate([-39.75,-35.5,0])
	rotate([-90,0,0])
	import("C:/Users/edparker/Sync/Personal/Projects/Git/KosselPro/submodules/OpenBeam_Kossel_Reprap/OBMKR-0010 - Kossel End Effector, J-Head.STL");
}

module FanMount()
{
	difference()
	{
		// THe 'bottom' of the clamp.
		cube([40,bottomWidth,thickness], center=true);

		// Pair it with the extruder holes
		translate([-3,0,0])
		for(x = [0, 1])
		{
			translate([x*18,0,0])
			union()
			{
				translate([0,0,.11])
				nutHole(3);

				cylinder(r=2, h=200, center=true);
			}
		}
	}

	difference()
	{
		translate([0,cos(angle)*-sidePlateLength+1.5,sin(angle)*sidePlateLength/2-0.75])
		rotate([-angle,0,0])
		cube([40,sidePlateLength,thickness], center=true);
	
	
		// Holes for the fan.
		for(x = [-1, 1])
		{
			rotate([-45,0,0])
			translate([x*16, -sidePlateLength*.9, 0])
			union()
			{
				translate([0,0,-4.36])
				nutHole(3);
				cylinder(r=2, h=200, center=true);
			}
		}
	}
}

% EndEffector();

translate([0,-23.5,thickness/2])
FanMount();