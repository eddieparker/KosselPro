// TODO: Cut down the screw hole depth.
$fn=200;
module Original()
{
	import("C:/Users/edparker/Sync/Personal/Projects/Git/KosselPro/Personal Additions/FSREndEffector/Originals/effector.stl");
}

module RingOnly()
{
	difference()
	{
		linear_extrude(height=60)
		projection()
		Original();

		// Inverse torus to cut out the knobs
		scale([1,0.95125,1])
		difference()
		{
			cylinder(r=30000, h=2000, center=true);
			cylinder(r=31, h=2000, center=true);
		}

		// Take a chance at hollowing out the corners where the screws are.
		for(i = [ 0 : 6])
		{
			rotate([0,0,30+360/6*i])
			translate([24.5,0,0])
			cube([20,7,2000], center=true);
		}
	}
}

for(i = [0, 1])
{
	translate([0,-20,0]*i)
	difference()
	{
		RingOnly();

		// Cut different sections dependent on which strain relief we want.
		translate([0,-7.5,0]*i)
		rotate([0,0,-45]*i)
		union()
		{
			translate([-104,20,0])
			cube([200,200,2000], center=true);

			translate([-10,-92,0])
			rotate([0,0,90])
			cube([200,200,2000], center=true);
		}

		// Cut holes for zap straps.
		rotate([0,0,-60*i])
		translate([0,-5,0])
		for(z = [-1,  1])
		{
			for(x = [-1, 1])
			{
				translate([x*5,0,30+20*z])
				rotate([90,0,-25-5*x])
				cylinder(r=2.5, h=2000, center=true);
			}
		}
	}
}
