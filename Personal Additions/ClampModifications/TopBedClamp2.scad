gQuality=400;
gMetricScrewSize=3;

gBedClampDimensions=[80,40,10];
gBedClampLipHeight=5;
gGlassPlateDiameter=250;

// What is the diameter of the round part of the FSR head? (in mm)
gFsrDiameter=20;

// The neck is what joins the FSR to the head. (in mm)
gFsrNeckWidth=10;

// How thick should we make the pillar 'cup' the FSR? (in mm)
gFsrThickness=1;

gShowAllParts=true;
gPartToShow=1;

use <MCAD/nuts_and_bolts.scad>

module Mount_FSR(thickness=gFsrThickness, neckLength=2000, clearance=0)
{
	cylinder(r=gFsrDiameter/2+clearance, h=thickness, center=true, $fn=gQuality);

	translate([0,-(gFsrDiameter/1.5+neckLength)/2,0])
	cube([gFsrNeckWidth,neckLength,thickness], center=true);
}

// Metric screw sizes are diameter, we need a radius.  1.15 is for clearance.
function MetricScrewHoleClearanceRadius(metricScrewSize) = metricScrewSize/2*1.15;

module MetricScrewHole(metricScrewSize, h=200)
{
	cylinder(r=MetricScrewHoleClearanceRadius(metricScrewSize), h=h, $fn=gQuality, center=true);
}

if(gShowAllParts || gPartToShow == 0)
{
	// Attempt at a different clamp.  One where the screws are underneath the glass/FSR, and the back plate lets you clamp on.

	difference()
	{
		// Whole block:
		minkowski()
		{
			cube(gBedClampDimensions, center=true);
			cylinder(r=2,h=1, $fn=gQuality);
		}

		// FSR
		translate([0,gBedClampDimensions.y/3,-gBedClampDimensions.z/8])
		rotate([0,0,180])
		Mount_FSR(gBedClampDimensions.z/2);

		// Holes for side screws
		for(i = [-1, 1])
		{
			translate([i*gBedClampDimensions.x/3,0,0])
			union()
			{
				// Actual clearance
				cube([gMetricScrewSize*1.15,gBedClampDimensions.y*.9,100], center=true);
				// Counter sink hole
				translate([0,0,45])
				cube([gMetricScrewSize*2,gBedClampDimensions.y*.9,100], center=true);
			}
		}

		// Holes for back screws
		for(i = [-1, 1])
		{
			translate([i*gBedClampDimensions.x*.8/4,-gBedClampDimensions.y*.8/2,0])
			union()
			{
				// Actual screw holes
				MetricScrewHole(gMetricScrewSize, gBedClampDimensions.z*2);
				// Captive nut
				translate([0,0,-gBedClampDimensions.z/2])
				nutHole(gMetricScrewSize);
			}
		}

		// Cut out for glass plate
		translate([0,gGlassPlateDiameter/2-gBedClampDimensions.y*.75/2,gBedClampLipHeight])
		cylinder(r=gGlassPlateDiameter/2,h=10,center=true, $fn=gQuality);
	}
}

gGlassClampStart=-gBedClampDimensions.y/2+5;
gGlassClampThickness=2;

// Bed clamp.
if(gShowAllParts || gPartToShow == 1)
{
	translate([0,$t-20,gBedClampDimensions.z])
	difference()
	{
		minkowski()
		{
			cube(gBedClampDimensions, center=true);
			cylinder(r=2,h=1, $fn=gQuality);
		}

		// Inner glass plate
		translate([0,gGlassPlateDiameter/2-gGlassClampStart,-gBedClampDimensions.z/2])
		cylinder(r=gGlassPlateDiameter/2,h=10,center=true, $fn=gQuality);

		difference()
		{
			translate([0,gGlassPlateDiameter/2-gBedClampDimensions.y*1.95/2,-gBedClampLipHeight])
			cylinder(r=gGlassPlateDiameter/2,h=10,center=true, $fn=gQuality);

			translate([0,gGlassPlateDiameter/2-gGlassClampStart-gGlassClampThickness,-gBedClampLipHeight])
			cylinder(r=gGlassPlateDiameter/2,h=10,center=true, $fn=gQuality);
		}

		// Back screw slots
		for(i = [-1, 1])
		{
			translate([i*gBedClampDimensions.x*.8/4,-gGlassClampThickness,0])
			// Actual clearance
			cube([gMetricScrewSize*1.15,gBedClampDimensions.y+gGlassClampStart/2,100], center=true);
		}
		
	}
}

if(gShowAllParts || gPartToShow == 2)
{
	translate([0, 0, gBedClampDimensions.z*2])
	Mount_FSR(neckLength=0, clearance=-0.5);
}

