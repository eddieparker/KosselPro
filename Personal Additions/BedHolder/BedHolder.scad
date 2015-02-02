$fn = 200;

gForSVGExport=true;

use <MCAD/nuts_and_bolts.scad>

gGlassDimensions = [125,3.5];
gHolderDimensions = [gGlassDimensions.x+10,2];
gMagnetRadius = 8;
gWireHoleRadius = 7;

module CylinderByDimensions(x) { cylinder(r=x.x, h=x.y, center=true); }

module GlassPlate()
{
	color([0,1,1, 0.5])
	CylinderByDimensions(gGlassDimensions);
}

module BasePlate()
{
	difference()
	{
		CylinderByDimensions(gHolderDimensions);
		for(i = [0: 5])
		{
			rotate([0,0,360/6*i])
			translate([1,0,0]*(gHolderDimensions.x-(gHolderDimensions.x-gGlassDimensions.x)/2))
			boltHole(3, length=200);
		}
	}
}

module TopPlate()
{
	color([1,0,0, 0.5])
	difference()
	{
		// Outer cylinder
		BasePlate();
		// Hollow out the difference
		CylinderByDimensions(gHolderDimensions-[(gHolderDimensions.x-gGlassDimensions.x)*2,0]);
	}
}

module SpacerRing()
{
	difference()
	{
		BasePlate();
		GlassPlate();
	}
}

module BottomPlate()
{
	color([0,1,0, 0.5])
	difference()
	{
		// Outer cylinder
		BasePlate();

		for(i = [0: 5])
		{
			rotate([0,0,360/6*(i+0.5)])
			translate([1,0,0]*(gGlassDimensions.x*3/4))
			cylinder(r=gMagnetRadius, h=2000, center=true);
		}

		// Where do I want this?
		translate([1,0,0]*gGlassDimensions.x*3/4)
		cylinder(r=gWireHoleRadius, h=2000, center=true);

	}
}
module Text(t)
{
	linear_extrude(height=1)
	text(t, halign="center");
}

if(!gForSVGExport)
{
	translate([0,0,(gGlassDimensions.y+gHolderDimensions.y)/2])
	TopPlate();

	GlassPlate();
	SpacerRing();

	translate([0,0,-(gGlassDimensions.y+gHolderDimensions.y)/2])
	BottomPlate();
}
else
{


	union()
	{
		TopPlate();
		translate([0,-(gHolderDimensions.x+20), 0])
		Text("Top Plate");
	}

	translate([gHolderDimensions.x*2 + 10, 0, 0])
	union()
	{
		SpacerRing();
		translate([0,-(gHolderDimensions.x+20), 0])
		Text("Spacer Ring");
	}

	translate([2*(gHolderDimensions.x*2 + 10), 0, 0])
	union()
	{
		BottomPlate();
		translate([0,-(gHolderDimensions.x+20), 0])
		Text("Bottom Plate");
	}
}
