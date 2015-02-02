gSimulate=false;
gOpening=3;
gFanAngle=45;
gFanDimensions = [40,40,10];
gFanScrewHoleDistance=32;
gFanMountHolesSeparationInEffector=20;
gFanMountHolesDistanceToHotEnd=40;
gHotEndRadius = 10;
gExposedHotEndHeight = 50;
gEndEffectorThickness=10;

gFanDuctSkewAmount = [0,15,0];


$fn=200;

use <MCAD/nuts_and_bolts.scad>

tinyValue=0.001;

function RenderFanAngle(angle) = 180-angle;
function FanBoundingDimensionWhenAngled(angle) = sin(RenderFanAngle(angle))*(gFanDimensions.z+gFanDimensions.y)/2;

module Fan()
{
	cube(gFanDimensions, center=true);
}

module HotEnd()
{
	translate([0,0,gExposedHotEndHeight/2])
	cylinder(r=gHotEndRadius, h=gExposedHotEndHeight, center=true);
}

module EndEffector()
{
	translate([0,0,gExposedHotEndHeight])
	cylinder(r=gHotEndRadius+gFanMountHolesDistanceToHotEnd, h=gEndEffectorThickness);
}

module SkewedCone(outerRadius, height, innerRadius, skewDirection)
{
	hull()
	{
		cylinder(r=outerRadius, h=tinyValue, center=true);

		translate([0,0,height]+skewDirection)
		cylinder(r=innerRadius, h=tinyValue, center=true);
	}

	// Debug draw 'airflow'
	% 
	color([0,0,1],0.25)
	translate([0,0,height]+skewDirection)
	hull()
	{
		cylinder(r=innerRadius, h=tinyValue, center=true);

		// TODO: Do this with math when you're not tired.
		translate([0,0,35]+skewDirection)
		cylinder(r=tinyValue, h=tinyValue);
	}
}

module FanMountHoles()
{
	for(x = [ -1, 1])
	{
		for(y = [-1, 1])
		{
			translate([x,y,0]*gFanScrewHoleDistance/2)
			union()
			{	
				translate([0,0,-0.75]) // Fudge
				nutHole(3);
				translate([0,0,-3]) // Fudge
				boltHole(3, length=20);
			}
		}
	}
}

function RingJointTotalWidth(numRings, ringThickness) = (numRings*2-1)*ringThickness;

module RingJoint(ringRadius=3, numRings=2, ringThickness=3, holeRadius=3.2/2, walkwayLength=5)
{
	difference()
	{
		union()
		{
			// Square walkway.
			translate([0,0,(ringRadius+walkwayLength)/2])
			cube([RingJointTotalWidth(numRings, ringThickness), ringRadius*2, ringRadius+walkwayLength], center=true);

			// Ring top
			translate([0,0,walkwayLength+ringRadius])
			rotate([0,90,0])
			cylinder(r=ringRadius, h=RingJointTotalWidth(numRings, ringThickness), center=true);
		}

		// Cut out middle sections
		for(i = [2 : numRings])
		{
			// Cut out the ring spacing
			translate([(i-2)*RingJointTotalWidth(numRings,ringThickness)/(numRings*2-1)-RingJointTotalWidth(numRings,ringThickness)/2+ringThickness*(i-1),
						-(ringRadius*2+1)/2,
						0,
						])
			cube([ringThickness, ringRadius*2+1, walkwayLength+ringRadius*2]);
		}

		// Cut out the hole 
		translate([0,0,(ringRadius+walkwayLength)])
		rotate([0, 90, 0])
		cylinder(r=holeRadius, h=RingJointTotalWidth(numRings, ringThickness)+1, center=true);
	}
}

module FanDuct()
{
	// Base
	translate([0,0,1.5])
	difference()
	{
		cube([40,40,3], center=true);

		FanMountHoles();
		cylinder(r=20-1.5, h=3, center=true);
	}

	// Sloping duct
	translate([0,0,3])
	difference()
	{
		SkewedCone(outerRadius=20, innerRadius=5, height=30, skewDirection=gFanDuctSkewAmount);
		SkewedCone(outerRadius=20-1.5, innerRadius=5-1.5, height=30, skewDirection=gFanDuctSkewAmount);
	}

	// Swivel mount
	translate([0,17.5,5])
	rotate([-90,0,0])
	RingJoint(numRings=3);
}

module EndEffectorSwivel()
{
	translate([0,0,-2.5])
	difference()
	{
		// Base
		cube([30,10,5], center=true);
		translate([0,0,-2.5]) // Fudge
		for(x = [-1, 1])
		{
			translate([x*10,0,0])
			union()
			{
				nutHole(3);
				translate([0,0,10]) // Fudge, but we just want the hole.
				rotate([0,180,0])
				boltHole(3, length=30);
			}
		}
	}

	translate([0,0,-5])
	rotate([180,0,0])
	RingJoint(numRings=2, walkwayLength=2);
}

if(gSimulate)
{
	% EndEffector();

	% HotEnd();

	translate([
		0,
		// Push us out by the hot end radius, plus the width of the fan, and then out to the mounting holes distance.
		gHotEndRadius + FanBoundingDimensionWhenAngled(gFanAngle) + gFanMountHolesDistanceToHotEnd,
		gExposedHotEndHeight - FanBoundingDimensionWhenAngled(gFanAngle)
		])

	%
	translate([0,-11,-5]) // Fudge to line things up.
	rotate([RenderFanAngle(gFanAngle),0,0])
	Fan();

	translate([
		0,
		// Push us out by the hot end radius, plus the width of the fan, and then out to the mounting holes distance.
		gHotEndRadius + FanBoundingDimensionWhenAngled(gFanAngle) + gFanMountHolesDistanceToHotEnd,
		gExposedHotEndHeight - FanBoundingDimensionWhenAngled(gFanAngle)
		]
		+
		[0,-11,-5] // Fudge to line things up.
		)
	rotate([RenderFanAngle(gFanAngle),0,0])
	translate([0,0,5])
	FanDuct();

	translate([0, 
		gHotEndRadius + gFanMountHolesDistanceToHotEnd-20,
		gExposedHotEndHeight
		])
	EndEffectorSwivel();
}
else
{
	FanDuct();

	translate([0,50,0])
	rotate([180,0,0])
	EndEffectorSwivel();
}

