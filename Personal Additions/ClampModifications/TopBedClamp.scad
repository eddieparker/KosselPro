gQuality=200;
gMetricScrewSize=3;

gBedClampDimensions=[60,40,7];
gBedClampLipHeight=5;
gGlassPlateDiameter=250;

// What is the diameter of the round part of the FSR head? (in mm)
gFsrDiameter=20;

// The neck is what joins the FSR to the head. (in mm)
gFsrNeckWidth=10;

// How thick should we make the pillar 'cup' the FSR? (in mm)
gFsrThickness=1;

gStuccoPlateDimensions = [gBedClampDimensions.x/1.5,gBedClampDimensions.y/2,3];
gStuccoPlateStuccoCount = [8,2];
gStuccoRadius = 1;
gStuccoHeight = 2;

gShowAllParts=false;
gPartToShow=0;

module Mount_FSR(neckLength=2000)
{
	cylinder(r=gFsrDiameter/2, h=gFsrThickness, center=true, $fn=gQuality);

	translate([0,-(gFsrDiameter/1.5+neckLength)/2,0])
	cube([gFsrNeckWidth,neckLength,gFsrThickness], center=true);
}

function EqualSpread(x, numX, dimX) = (x/(numX-1))*dimX-dimX/2;

module StuccoPlate(dimensions, stuccoGridDimensions, stuccoR, stuccoH, stuccoMargin=10)
{
	cube(dimensions, center=true);
	for(x = [0 : stuccoGridDimensions.x-1])
	{
		for(y = [0 : stuccoGridDimensions.y-1])
		{
			translate([EqualSpread(x,stuccoGridDimensions.x, dimensions.x-stuccoMargin),
EqualSpread(y,stuccoGridDimensions.y,dimensions.y- stuccoMargin),
-stuccoH])
			cylinder(r=stuccoR, h=stuccoH, $fn=gQuality);
		}
	}
}




// STucco plate
if(gShowAllParts || gPartToShow == 0)
{
	translate([0, gBedClampDimensions.y,-gBedClampDimensions.z/2+1.5])
	//translate([0,gBedClampDimensions.y/3,5*$t]) // POsition above the plate
	rotate([0,180,0])
	difference()
	{
		translate([0,0,1])
		StuccoPlate(gStuccoPlateDimensions, gStuccoPlateStuccoCount, gStuccoRadius, gStuccoHeight);

	// Smaller constrictive ring
		translate([0,0,1])
		scale([.7,.7,10])
		Mount_FSR(0);


	// FSR
		rotate([0,180,0])
		translate([0,0,49.5])
		scale([1,1,100])
		Mount_FSR();
	}
}
	// Metric screw sizes are diameter, we need a radius.  1.15 is for clearance.
function MetricScrewHoleClearanceRadius(metricScrewSize) = metricScrewSize/2*1.15;

module MetricScrewHole(metricScrewSize, h=200)
{
	cylinder(r=MetricScrewHoleClearanceRadius(metricScrewSize), h=h, $fn=gQuality, center=true);
}

// STucco plate
if(gShowAllParts || gPartToShow == 1)
{
	difference()
	{
		// Whole block:
		minkowski()
		{
			cube(gBedClampDimensions, center=true);
			cylinder(r=2,h=1, $fn=gQuality);
		}

		// Holes for screws
		for(i = [-1, 0, 1])
		{
			translate([i*gBedClampDimensions.x/3,0,0])
			hull()
			{
				for(n = [0:3])
				{
					translate([0,-gBedClampDimensions.y/5-n*MetricScrewHoleClearanceRadius(gMetricScrewSize)*2,0])
					MetricScrewHole(gMetricScrewSize, gBedClampDimensions.z*2);
				}
			}
		}

		// FSR
		translate([0,gBedClampDimensions.y/3,-.5])
		rotate([0,0,180])
		Mount_FSR();

		// Receiving a slightly larger stucco plate
		difference()
		{
			translate([0,gBedClampDimensions.y/3,1])
			StuccoPlate(gStuccoPlateDimensions, gStuccoPlateStuccoCount, gStuccoRadius, gStuccoHeight);

			// FSR
			translate([0,gBedClampDimensions.y/3,-.5])
			rotate([0,0,180])
			scale([1,1,50])
			Mount_FSR();

		}

		// Cut out for glass plate
		translate([0,+gGlassPlateDiameter/2,gBedClampLipHeight])
		cylinder(r=gGlassPlateDiameter/2,h=10,center=true, $fn=gQuality);
	}
}