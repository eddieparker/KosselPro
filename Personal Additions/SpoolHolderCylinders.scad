$fn=200;

gOuterDiameter=22;
gInnerDiameter=19;

gIncrements=10;

for(x = [1 : 5])
{
	translate([(gOuterDiameter+1)*(x-1),0,0])
	difference()
	{
		cylinder(r=gOuterDiameter/2, h=x*gIncrements);
		cylinder(r=gInnerDiameter/2, h=x*gIncrements);
	}
}