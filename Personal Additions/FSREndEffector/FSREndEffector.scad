
/**
  * TODO:
  * 	- Need to design to allow the fan shroud
  * 		- I think my jamming is because I'm not using it.
  * 	- Possibly add the effector ring to this?
  */
$fn=200;

gDebugShowHotEnd=false;
gDebugShowHalfOnly=false;

use <../../../OpenSCADModules/FSR.scad>
include <MCAD/nuts_and_bolts.scad>

// What do you want to export?
kPrintType_All=1;
kPrintType_OnlyBottomBrace=2;
kPrintType_OnlyTopBrace=3;
kPrintType_DebugBottomHole=4;

gPrintType=kPrintType_All;
gPrintType=kPrintType_OnlyBottomBrace; 
//gPrintType=kPrintType_DebugBottomHole;

/**
  * Dimensions of the actual hot end portion that clamps into this.
  *
  * i.e. if this is the top part of your hot end, the parameters below are as such:
  *
  *                 (a)
  *            v--------------v
  *
  *            |--------------|  <
  *            |              |   | (b)
  *          > -----      -----  <
  *         |      |      | 
  *     (c) |      |      | (d)
  *         |      |      |v--v 
  *          > -----      -----
  *            |              |
  *            |              |
  *            |              |
  *
  * Where:
  *
  * 	a = gHotEndDiameter
  * 	b = gHotEndUpperLipHeight
  * 	c = gHotEndGrooveHeight
  * 	d = gHotEndGrooveDepth
  *
  * 	All units are in millimetres.
  */



// Measurements for the bulldog V6, taken from here:
// http://files.e3d-online.com/v6/Drawings/V6-175-SINK.pdf
gHotEndDiameter=16 + 0.35;
//gHotEndUpperLipHeight=3.7;
gHotEndUpperLipHeight=3.7;
gHotEndGrooveHeight=6;
gHotEndGrooveDepth=2.5;
gHotEndDimensionsTolerance=0.1;


gBottomBraceHotEndExtenderLength=20;
// The bolt used to secure the hot end in place from falling out.
gHotEndGrooveBoltHoleSize=3;

// Do you need a flanged nut as part of this, to screw in the PTFE?  Setting the nut size to zero means you want the hot end to be flush.
gFlangedNutSize=0;
gFlangedNutFlangeHeight=0;//1.21;
gFlangedNutFlangeDiameter=0;//11;

gCylinderPunchOutForPushFit=9;

gFSRWallHeight=5;
gBottomBraceDimensions=[56,20,5+gFSRWallHeight];
gBottomBraceBevel=2;

gTopBraceHeight=8;

function VScale(x, y) = [ x[0] * y[0], x[1] * y[1], x[2] * y[2] ];

module Frustum(farPlaneScale, nearPlaneScale)
{
	near=[0,0,-.5];
	far=[0,0,.5];
	polyhedron(points=[ [ .5, .5, 0]*nearPlaneScale+near, [.5, -.5, 0]*nearPlaneScale+near, [-.5, -.5, 0]*nearPlaneScale+near, [-.5, .5, 0]*nearPlaneScale+near, // Top
						[ .5, .5, 0]*farPlaneScale+far, [.5, -.5, 0]*farPlaneScale+far, [-.5, -.5, 0]*farPlaneScale+far, [-.5, .5, 0]*farPlaneScale+far, // Bottom
						],
					faces=[ [2,1,0], [0,3,2], // Bottom
							[5,1,2], [5,2,6], // Back
							[6,2,3], [6,3,7], // Right
							[5,0,1], [4,0,5], // Left
							[3,0,4], [4,7,3], // Front
							[4,5,6], [6,7,4], // Top
					]
					);
}

// Bottom brace foundation
module BraceFoundation(height, bDoExtension)
{
	translate([0,0,height/2])
	minkowski()
	{
		cylinder(r=gBottomBraceBevel,h=0.001);
		cube(VScale(gBottomBraceDimensions,[1,1,0])+[0,0,height]-[1,1,0]*gBottomBraceBevel, center=true);
	}

	if(bDoExtension)
	{
		// Do the actual extension
		translate([0,0,-gBottomBraceHotEndExtenderLength/2])
		scale([1,1,gBottomBraceHotEndExtenderLength])
		// Terrible.
		intersection()
		{
			//Frustum(gBottomBraceDimensions.y+15, gHotEndDiameter+6);
			Frustum(gHotEndDiameter+6, gHotEndDiameter+6);
			translate([0,0,-1500])
			BraceFoundation(3000, false);
		}
	}
}

module FlangedNut(metricSize, flangeHeight, flangeDiameter)
{
	nutHole(metricSize);
	cylinder(r=flangeDiameter/2.0,h=flangeHeight);
}

module HotEndWithFlange(bDrawGroove, hotEndHeight=50)
{
	translate([0,0,hotEndHeight])
	FlangedNut(gFlangedNutSize, gFlangedNutFlangeHeight, gFlangedNutFlangeDiameter);

	difference()
	{
		// The hot end has a notch carved out of it
		cylinder(r=(gHotEndDiameter+gHotEndDimensionsTolerance)/2, h=hotEndHeight);
		translate([0,0,hotEndHeight-gHotEndUpperLipHeight-gHotEndGrooveHeight])

		if(bDrawGroove)
		{
			difference()
			{
				cylinder(r=(gHotEndDiameter+gHotEndDimensionsTolerance)/2*1.1, h=gHotEndGrooveHeight);
				cylinder(r=(gHotEndDiameter+gHotEndDimensionsTolerance)/2-gHotEndGrooveDepth, h=gHotEndGrooveHeight);
			}
		}
	}
}

gHotEndLength=50;

//hotEndOffsetZOffsetFromZero=-gFlangedNutFlangeHeight-gFSRWallHeight-1+gBottomBraceDimensions.z;
//hotEndZOffset=-gHotEndLength+hotEndOffsetZOffsetFromZero;
boltRadius=COURSE_METRIC_BOLT_MAJOR_THREAD_DIAMETERS[gHotEndUpperLipHeight]/2;
boltOffsetFromHotEndT=-gHotEndUpperLipHeight-boltRadius-gHotEndDimensionsTolerance;
boltOffsetFromHotEndTop=gHotEndLength+boltOffsetFromHotEndT;
hotEndZOffset=-gHotEndLength-boltOffsetFromHotEndT + boltRadius+3;
module BottomBraceHotEnd()
{
	translate([0,0,hotEndZOffset+5])
	union()
	{
		HotEndWithFlange(gDebugShowHotEnd, gHotEndLength);

		// Now add screw holes in the side to hold the hot end in place.
		for(i = [-1, 1])
		{
			translate(	[ 
						// Make the bolts go on either side of the hot end grooves
						((gHotEndDiameter/2)-gHotEndGrooveDepth+COURSE_METRIC_BOLT_MAJOR_THREAD_DIAMETERS[gHotEndGrooveBoltHoleSize]/2+gHotEndDimensionsTolerance+1)*i

						, gBottomBraceDimensions.y

						// Make the bolt snug up against the top of the hot end.
						, boltOffsetFromHotEndTop
						])
			rotate([90,0,0])
			boltHole(gHotEndGrooveBoltHoleSize, length=300);
		}
	}
}

module PushFitPunchOut()
{
	// The actual hole for the push fit.
	cylinder(r=(gCylinderPunchOutForPushFit+gHotEndDimensionsTolerance)/2, h=2000, center=true);
	// A hole to use a screw driver to push *in* the pushfit
	translate([0,(gCylinderPunchOutForPushFit+gHotEndDimensionsTolerance)/2, 0])
	cylinder(r=1.5, h=2000, center=true);
}


module BottomBrace()
{
	// TODO: Debug case
	rotate([0,0,0])
	difference()
	{
		BraceFoundation(gBottomBraceDimensions.z, true);

		if(gDebugShowHotEnd)
		{
			translate([0,0,-gBottomBraceHotEndExtenderLength])
			# BottomBraceHotEnd();
		}
		else
		{
			translate([0,0,-gBottomBraceHotEndExtenderLength])
			BottomBraceHotEnd();
		}

		PushFitPunchOut();

		for(i = [-1, 1])
		{
			// Drill holes fromt he top.
			translate([25*i,0,-10])
			union()
			{
				boltHole(gHotEndGrooveBoltHoleSize, tolerance=0.4, length=300);
			}

			// Drill the FSR mount pad spacers.
			translate([13.9*i,20, gBottomBraceDimensions.z-gFSRWallHeight/2+0.1])
			scale([1.02, 1.02, gFSRWallHeight])
			FSR(fsrDiameter=18.3, fsrLength=58.5);
		}
	}
}

if(kPrintType_OnlyBottomBrace == gPrintType || kPrintType_All == gPrintType)
{
	translate([0,0,gBottomBraceDimensions.z+gBottomBraceBevel/2])
	rotate([90,0,0])
	difference()
	{
		BottomBrace();
		if(gDebugShowHalfOnly)
		{
			translate([-1,0,-1]*5000)
			cube([1,1,1]*10000);
		}
	}
}

if(kPrintType_DebugBottomHole == gPrintType)
{
	difference()
	{
		BottomBrace();
		// Torus to kill the other stuff.
		difference()
		{
			cylinder(r=2000, h=2000);
			cylinder(r=gHotEndDiameter+3,h=2000);
		}
	}
}

// Top brace
if(kPrintType_All == gPrintType || kPrintType_OnlyTopBrace == gPrintType)
{
	translate([0,gBottomBraceDimensions.y*2,0])
	difference()
	{
		union()
		{
			BraceFoundation(gTopBraceHeight, false);

			// Cylinders to depress the FSR
			for(i = [-1, 1])
			{
				translate([14*i,0, gTopBraceHeight])
				difference()
				{
					cylinder(r=8.5, h=gFSRWallHeight);

					// Embed a nut in the top, to cause pointed pressure?
					translate([0,0,gFSRWallHeight-METRIC_NUT_THICKNESS[3]/3*2])
					nutHole(3);
				}
			}
		}

		// PTFE tubing
		PushFitPunchOut();

		for(i = [-1, 1])
		{
			// Top holes
			translate([25*i,0,-10])
			boltHole(gHotEndGrooveBoltHoleSize, length=200);

			nutHole(gFlangedNutSize);
		}
	}
}
