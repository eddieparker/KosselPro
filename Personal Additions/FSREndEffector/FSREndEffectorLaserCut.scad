$fn=200;

include <MCAD/nuts_and_bolts.scad>
use <../../../OpenSCADModules/FSR.scad>

gDebugShowOriginal=false;

kAllLayers=4;
kTopLayer=3;
kMiddleLayer=2;
kBottomLayer=1;

gRenderLayers=kAllLayers;
gRenderLayers=kMiddleLayer;

translateOffset = [0, 0, 10];

module Original()
{
	import("C:/Users/edparker/Sync/Personal/Projects/Git/KosselPro/Personal Additions/FSREndEffector/Originals/effector.stl");
}

module BasePlate(r=29.5)
{
    difference()
    {
        cylinder(r=r, h=1);
        
        // Mount holes to grip the hot end
        for(i = [0:5])
        {
            if(i%2 == 0)
            {
                rotate([0,0,-29.8+i*(360/6)])
                translate([12,0,-150])
                boltHole(3, length=300);
            }
        }

        // Mount holes to effector
        for(i = [0:2])
        {
            rotate([0,0,29.8+(360/3)*(i+0.5)])
            translate([25.2,0,0])
            cylinder(r=2,h=200);
        }
    }
}

module HotEndDiameter()
{
	// Hot end diameter
	cylinder(r=(16 + 0.35)/2,200);
}

module PushFitDiameter()
{
	cylinder(r=8/2,h=200);
}

module SandwichedPlate()
{        
    difference()
    {
        BasePlate();


        HotEndDiameter();
        
        for(i = [0:2])
        {
			rotate([0,0,60+120*i])
			translate([0,35,0])
			scale([1,1,5])
			translate([0,-61/2,0])
			rotate([0,0,45])
			translate([0,61/2,0])
			# FSR();
        }
    }
}

module TopClamp()
{
	difference()
	{
		BasePlate();
		PushFitDiameter();
	}
}

module BottomClamp()
{
	difference()
	{
		BasePlate(r=17);
		HotEndDiameter();
	}
}


if(gRenderLayers == kAllLayers || gRenderLayers == kTopLayer)
{
	translate(translateOffset*(kTopLayer-1))
	TopClamp();
}

if(gRenderLayers == kAllLayers || gRenderLayers == kMiddleLayer)
{
	translate(translateOffset*(kMiddleLayer-1))
	SandwichedPlate();
}

if(gRenderLayers == kAllLayers || gRenderLayers == kBottomLayer)
{
	translate(translateOffset*(kBottomLayer-1))
	BottomClamp();
}

if(gDebugShowOriginal)
{
	translate([0,0,-15])
	% Original();
}
