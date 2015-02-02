$fn=200;

include <MCAD/nuts_and_bolts.scad>
use <../../OpenSCADModules/FSR.scad>

// Roughly centered
module StockEffector()
{
	translate([-39.7528,-35.5,9])
	rotate([-90,0,0])
	//import("C:/Users/Eddie/Sync/Personal/Projects/Git/KosselPro/submodules/OpenBeam_Kossel_Reprap/OBMKR-0010 - Kossel End Effector, J-Head.STL");
	import("../submodules/OpenBeam_Kossel_Reprap/OBMKR-0010 - Kossel End Effector, J-Head.STL");
}

// TODO: One day...
/*
module ParametricEffector(effectorRadius=40, effectorHeight=10, metricScrewSize=3)
{
	difference()
	{
		// The base radius of the effector
		cylinder(r=effectorRadius,h=effectorHeight);

		for(i = [0 : 2])
		{
			// The effective circles that the 'joints' are spaced out by.
				// TODO: Parameterize the arm width, to decide where the circle goes
				rotate([0,0,90+120*(i)])
				translate([effectorRadius*PI/2,0,0])
				cylinder(r=effectorRadius, h=effectorHeight);

			// The inner rectangle that you put the nuts in.
				rotate([0,0,30+120*i])
				translate([effectorRadius,0,effectorHeight/2])
				# cube([METRIC_NUT_AC_WIDTHS[metricScrewSize]*2,10,effectorHeight], center=true);
		}

		// Build location for carbon fibre tubes to attach
		for(i = [0: 6])
		{
			rotate([0,0,360/6*i])
			translate([effectorRadius-METRIC_NUT_AC_WIDTHS[metricScrewSize],0,effectorHeight/2])
			rotate([90,0,30+(i%2)*120])
			union()
			{
				# nutHole(3);

				rotate([0,180,0])
				# boltHole(3, length=20);
			}
		}
	}


}

% StockEffector();
ParametricEffector(effectorRadius=40);
*/

module SymmetricalEffector()
{
	for(a = [0,1])
	{
		mirror([a,0,0])
		union()
		{
			for(i = [0:2])
			{
				rotate([0,0,i*120])
				StockEffector();

				// Hacky hole filling
				rotate([0,0,30+i*120])
				translate([22.5,0,4.5])
				cube([7,15,9],center=true);
			}
		}
	}


}

module FSREffector(tolerance=0.1, outerMountHoles=6)
{
	// The outer ring.
	difference()
	{
		union()
		{
			SymmetricalEffector();
			// Plank for the mount holes to go on.
			for(i = [0 : 2])
			{
				rotate([0,0,360/3*i+30])
				translate([-35/2,0,4.5])
				cube([35,15,9], center=true);
			}
		}


		cylinder(r=16+tolerance/2, h=40);

		// M3 mount holes for things like fans.
		for(i = [0: outerMountHoles-1])
		{
			rotate([0,180,360/outerMountHoles*i])
			translate([22,0,+METRIC_NUT_THICKNESS[3]-9])
			boltHole(3, length=20);
		}

		// M3 mount holes for floating hot end mount
		for(i = [0: 2])
		{
			rotate([0,180,360/3*i+30])
			translate([30,0,-18])
			boltHole(3, length=20);

			// TODO: captive nut hole on the opposite side?
		}
	}


	// The floating hot end mount
	if(1)
	{
		difference()
		{
			union()
			{
				translate([0,0,18])
				rotate([0,180,0])
				intersection()
				{
					SymmetricalEffector();
					cylinder(r=16-tolerance/2, h=40);
				}
				translate([0,0,13.5]) 
				difference()
				{
					for(i = [0: 2])
					{
						rotate([0,0,360/3*i-30])
						translate([35/2,0,0])
						difference()
						{
							cube([35,25,9],center=true);
							rotate([0,180,0])
							translate([-12.5,0,-18])
							boltHole(3, length=2000);
						}
					}
					cylinder(r=15,h=200, center=true);
				}
			}

			if(1)
			{
				translate([0,0,13])
				for(i = [-1,1])
				{
					rotate([0,0,30])
					translate([13*i,20,4.5])
					FSR();
				}
			}
		}
	}


}

//% StockEffector();

FSREffector();


