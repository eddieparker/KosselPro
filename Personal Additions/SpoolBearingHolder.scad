$fn=200;

bearingInnerDiameter=7.85;
rodDiameter=5.7;

bearingWidth=6.98;
tolerance=0.001;

difference()
{
	cylinder(r=(bearingInnerDiameter-tolerance)/2,h=bearingWidth);
	cylinder(r=(rodDiameter-tolerance)/2,h=bearingWidth);
}
