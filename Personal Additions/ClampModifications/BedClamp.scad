gQuality=200;
gMetricScrewSize=3;
gBedHeight=4.4;
gClipHeightAboveBed=3.25;
gScrewWallThickness=5;
gClipLength=12;

screwRadius=gMetricScrewSize/2*1.1;
outerScrewRadius=screwRadius+gScrewWallThickness/2;
totalHeight=gClipHeightAboveBed+gBedHeight;

difference()
{
	union()
	{
		translate([-outerScrewRadius,0,0])
		cube([outerScrewRadius*2,gClipLength,gClipHeightAboveBed]);
		cylinder(r=outerScrewRadius,h=totalHeight, $fn=gQuality);
	}
	cylinder(r=screwRadius,h=totalHeight, $fn=gQuality);
}