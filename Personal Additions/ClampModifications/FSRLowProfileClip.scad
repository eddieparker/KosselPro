use <../../../OpenSCADModules/FSR.scad>
use <../../../OpenSCADModules/OpenBeam.scad>
use <MCAD/nuts_and_bolts.scad>


$fn=200;
gTopThickness = 2;
gSideWallThickness = 20;
gPlateWidth=40;

gOpenBeamDimensions = [0,15,15];
gMountDimensions = gOpenBeamDimensions + [gPlateWidth,gSideWallThickness, gTopThickness];


differenceCubeDimensions = gMountDimensions-[0,gSideWallThickness, gTopThickness]+[100,1,1]*.1;

fsrTopLength=27;

difference()
{
	// Outer describing cube
	translate([0,gSideWallThickness/2,gTopThickness/2])
	minkowski()
	{
		cube(gMountDimensions, center=true);
		cylinder(r=0.5, h=0.5);
	}

	// Inner cube to remove
	cube(differenceCubeDimensions, center=true);

	// FSR on top of the openbeam
	translate([0,(fsrTopLength-gMountDimensions.y+gSideWallThickness)/2, gMountDimensions.z/2+gTopThickness/2])
#	FSR(fsrLength=fsrTopLength);

	// Cut out for neck
	translate([45,gMountDimensions.y-gSideWallThickness/3,0])
	rotate([-45,0,0])
	scale([10,10,1])
	FSR();

	// Bolt holes for sides
	for(i = [-1 , 1])
	{
		translate([gMountDimensions.x/3*i,differenceCubeDimensions.y/2+gSideWallThickness/2,0])
		rotate([90,0,0])

		union()
		{
			scale([1,1,100])
			boltHole(3);
// This sucks, but the boltholes don't meet up so I need to do another one further back.
			translate([0,0,-5])
			scale([1,1,100])
			boltHole(3);
		}
	}
}



rotate([0,90,0])
scale([1,1,500])
% OpenBeam();