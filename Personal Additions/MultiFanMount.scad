use <MCAD/nuts_and_bolts.scad>

gHotEndBracketRadius=20;
gHotEndRadius=10;
gNumFans=3;

$fn=200;

module FanBracket()
{
	difference()
	{
		cube([40,10,10],center=true);
		for(x = [-1, 1])
		{
			translate([x*16,0,-2.75])
	
			union()
			{
				boltHole(3, length=20);
				translate([0,0,-1])
				boltHole(3, length=20);
			}

			nutHole(3);
		}
	}
}

module MultiFanMount()
{
	difference()
	{
		union()
		{
			cylinder(r=gHotEndBracketRadius, h=10, center=true);
			for(x = [0 : gNumFans])
			{
				rotate([0,0,360/gNumFans*x])
				translate([0, gHotEndBracketRadius, 0])
				FanBracket();
			}
		}
		cylinder(r=gHotEndRadius, h=200, center=true);
	}
}

difference()
{
/*
	hull()
	{
		MultiFanMount();
	}*/
	MultiFanMount();
}