$fn=200;

bracketDimensions=[15,30,27.5];
bottomBase=50;

use <MCAD/nuts_and_bolts.scad>

function InchesToMmm(inches) = inches*25.4;

difference()
{
	minkowski()
	{
		hull()
		{
			cube(bracketDimensions-[4,4,0], center=true);
			translate([0,0,-bracketDimensions.z/2])
			cube([15, bottomBase, 0.0001], center=true);
		}
		cylinder(r=2, h=0.0001, center=true);
	}

	// Mount holes
	for(y = [-1, 1])
	{
		translate([0, bracketDimensions.y/3*y,bracketDimensions.z/2-2.375])
		rotate([0,180,0])
		boltHole(3, length=bracketDimensions.z+1);
	}

	// Hole for thread
	cylinder(r=InchesToMmm(1/4)/2, h=bracketDimensions.z, center=true);
}
