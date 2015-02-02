gQuality=200;
gHeightBetweenExtrusions=75;
gThickness=3;
gMetricScrewSize=3;
gScrewHoleOffsetFromEnd=7;

function ScrewClearanceRadius(screwSize) = screwSize*1.2/2;

cubeDimensions=[ScrewClearanceRadius(gMetricScrewSize)*2+4, gThickness, gHeightBetweenExtrusions];

difference()
{
	cube(cubeDimensions,center=true);

	for(z = [-1,1])
	{
		translate([0,0,z*gHeightBetweenExtrusions/2 - z*gScrewHoleOffsetFromEnd])
		rotate([90,0,0])
		# cylinder(r=ScrewClearanceRadius(gMetricScrewSize), h=200, $fn=gQuality, center=true);
	}
}