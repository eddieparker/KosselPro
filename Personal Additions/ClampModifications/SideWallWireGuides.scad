
gQuality=200;
gClipDimensions=[40,5,200];


difference()
{

	translate([-gClipDimensions.x,-gClipDimensions.y,0]/2)
	cube(gClipDimensions);

	translate([0,0,15])
	rotate([90,0,0])
	cylinder(r=3.2/2.0,h=200,$fn=gQuality,center=true);
}