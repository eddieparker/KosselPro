gQuality=200;
gHandleRadius=6;
gHandleLength=200;

gBladeDimensions=[gHandleRadius*12,gHandleRadius*1.5,gHandleRadius];

gHandleBladeInsertionOffset=gBladeDimensions.y/1.8;

gIndexFingerGrooveRadius=3;
gIndexFingerDistanceAlongShaft=gHandleLength/1.5;

gMiddleFingerGrooveRadius=gIndexFingerGrooveRadius;
gMiddleFingerDistanceAlongShaft=gIndexFingerDistanceAlongShaft-10;

gPrintAllParts=true;
gPartToPrint=1;

module Blade()
{
	// Blade
	rotate([0,0,180])
	scale(gBladeDimensions)
	translate([0,-.5,0])
	linear_extrude(height=1, center=true)
	polygon(points=[[-1,0]/2,[1,0]/2, [.5,1]/2, [-.5,1]/2], paths=[[0,1,2,3]]);
}

module FingerGroove(radius, distanceDownHandle, zSide=1)
{
	translate([0,distanceDownHandle/2,zSide*gHandleRadius])
	rotate([0,90,0])
	scale([1,2,1])
	cylinder(r=gIndexFingerGrooveRadius, h=2000, center=true, $fn=gQuality);
}


if(gPrintAllParts || gPartToPrint==0)
{
	// Handle
	difference()
	{
		rotate([90,0,0])
		cylinder(r=gHandleRadius, h=gHandleLength, center=true, $fn=gQuality);
	
	// Carve out a spot for the blade to be accepted.
		translate([0,gHandleLength/2+gBladeDimensions.y/2-gHandleBladeInsertionOffset,])
		Blade();

	// Finger groove
		FingerGroove(gIndexFingerGrooveRadius, gIndexFingerDistanceAlongShaft);

		FingerGroove(gMiddleFingerGrooveRadius, gMiddleFingerDistanceAlongShaft, -1);
	}
}


if(gPrintAllParts || gPartToPrint==1)
{
	// Blade
	translate([0,gHandleLength/2+gBladeDimensions.y/2+($t),0])
	Blade();
}