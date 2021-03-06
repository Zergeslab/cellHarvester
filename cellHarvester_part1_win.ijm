/*
 * Taking an image resulting from the cellHarvester_Preprocessing macro, this macro will allow the user to quickly extract all the cells in a field of view
 * for further processing into a conglomerate image. See comments at the end for possible changes you might want to make to improve your results.
 */

 // Start with an open image from the preprocessing macro. 

//Lines 8-16 take care of some housekeeping that needs to be done before the macro is run
run("Select None");
count=roiManager("Count");
if (count>0){
roiManager("Deselect");
roiManager("Delete");
}
setBackgroundColor(0,0,0);
setForegroundColor(255,255,255);


fPath=getInfo("image.directory"); //Where is the open file located?
fName=getInfo("image.filename"); //What is the open file's name?
fName=substring(fName,0,lengthOf(fName)-4); //make a variable that excludes '.tif' from the filename
rename("cells"); //give the image a temporary name
setSlice(1); // select the channel that best represents the whole cytoplasm of the cell; this is going to be the basis for finding all the cells
run("Duplicate..."," "); //make a duplicate of this channel
rename("cellMask"); //give this duplicate a temporary name
setAutoThreshold("Intermodes dark"); //Use the Intermodes method to find an appropriate threshold for the cell image
setOption("BlackBackground", false); //Make sure that "black background" is set to false
run("Convert to Mask"); //Make a binary version of the thresholded image
run("Options...", "iterations=3 count=1 pad do=Close"); //"Close" the image to get rid of edge pixels
run("Fill Holes"); //Remove any holes in the cells; this may fill in gaps between cells in clusters of cells
run("Watershed"); //Split cells using the watershed method
run("Analyze Particles...", "size=500-Infinity pixel exclude clear add"); //Create an ROI for each cell

// Lines 34-48 convert the irregular ROIs generated by line 32 into smooth ellipses; new ROIs are created and the existing ones are deleted
count=roiManager("count");
if (count>0){
	for (obj=0;obj<count;obj++){
	
		roiManager("Select",obj);
		run("Fit Ellipse");
		roiManager("add");
	}
	del=Array.getSequence(count); //deletes the original ROIs
	roiManager("Select",del);
	roiManager("Delete");
	close();
	selectWindow("cells");
}

setTool("Ellipse"); //Sets the selection type to an ellipse

//Line 53 allows the user to remove inaccurate ROIs or add cells that have been missed by the previous lines.
waitForUser("Delete or adjust all the inaccurate ROIs.\n This may require you to add new ones with 't'.\nIf you add new ones, remember to delete the original.");
File.makeDirectory(fPath+fName+"_output"); //Makes a new directory
roiManager("Save",fPath+fName+"_output\\"+fName+"_rois.zip"); //Saves the ROIs in this directory; these can be loaded for verification

//The following loop runs across each cell
cellCount=roiManager("count");
for (cell=0;cell<cellCount;cell++){
	selectWindow("cells"); //Select the original fluorescence image
	setSlice(1); //Go into the channel 1
	roiManager("Select",cell); //Select an ROI that corresponds to a cell
	run("Duplicate...","duplicate"); //Duplicate just this cell
	roiManager("Add"); //Make a new ROI that contains the co-ordinates for this cell in its smaller window
	rotAng=findAxes(); //Uses the findAxes function (defined below) to find the short and long axes of the ellipse
	run("Set Measurements...", "area mean centroid integrated redirect=None decimal=3"); //Make sure the measurements are set correctly
	run("Select None"); //Remove the existing selection from the window
	w1=getWidth(); //What is the width of the cell image?
	h1=getHeight(); //What is the height of the cell image?
	run("Rotate... ", "angle="+90-rotAng+" grid=1 interpolation=Bilinear enlarge"); //rotate the image based on the angle found above
	w2=getWidth(); //What is the width of the rotated cell image?
	h2=getHeight(); //What is the height of the rotated cell image?
	dW=(w2-w1)/2; //How much did the image expand in the X direction? Divide it by two
	dH=(h2-h1)/2; //How much did the image expand in the Y direction? Divide it by two
	roiManager("Select",cellCount+cell); //select the ROI that corresponded to this cell beore the image was rotated

    setSelectionLocation(dW, dH); //Move this selection location so it is centred over the cell
	run("Rotate...", "  angle="+90-rotAng); //Rotate this selection so it sits over the cell
	roiManager("Add"); //make this selection into an ROI
	roiManager("Select",cellCount+cell); //Select the original, un-rotated ROI
	roiManager("Delete"); //delete it
	roiManager("Select",cellCount+cell); //select the rotated ROI
	run("Clear Outside"); //delete everything that's not in the ROI (make it black)
	makeRectangle(1,1,floor(w2/2),h2); //Draw a rectangle that accounts for the left half of the image
	run("Measure"); //measure it
	lInt=getResult("RawIntDen",nResults-1); //remember the strength of the signal in the left half of the image
	setSelectionLocation(floor(w2/2), 1); //make a selection that accounts for the right half of the image
	run("Measure"); //measure it
	run("Select None"); //deselect everything
	rInt=getResult("RawIntDen",nResults-1); //remember strength of the signal in the right half of the image
	if (rInt>lInt){ //if the right half of the image is more intense in this channel
		run("Flip Horizontally"); //flip it
	}
	roiManager("Select",cellCount+cell); //select the rotated ROI
	run("Crop"); //crop the image to these bounds
}

//lines 99-104 tidy up the workspace
for (cell=0;cell<cellCount;cell++){
	roiManager("Select",cell);
	roiManager("Delete");
}
selectWindow("cells");
close();

//At this point, there will now be a lot of open windows, each corresponding to a single cell
imList=getList("image.titles"); //Find out the names of the open images
for (image=0;image<lengthOf(imList);image++){ //Save each of these images in the "Output" folder
	selectWindow(imList[image]);
	saveAs("tif",fPath+fName+"_output\\"+fName+"_"+image+"clip.tif"); // the "_output\\" must be changed to "_output/" on a Mac
}


//******** Below this line is the findAxes function *********

/*
 * I hated writing this function. It really seemed like something that must exist already, but I couldn't find it.
 * Due to dealing with objects that have dimensions in the range of 10-100 pixels in one or both dimensions, it
 * was incredibly easy to generate long/short axes that were several degrees out, as the ends of the cell would appear
 * "flat", meaning that multiple points in the coordinate list would generate the same length of axis at different angles,
 * and only the first one (which could never be correct) would be used as the correct one.
 */

function findAxes() { 
	run("Interpolate", "interval=1 smooth"); //Make the pixellated selection as smooth a curve as possible
	getSelectionCoordinates(xpoints, ypoints); //get a list of coords in the elliptical selection

	run("Set Measurements...", "centroid redirect=None decimal=3"); //Sets to the appropriate measurements
	run("Measure"); //Measure the coordinates
	centX=getResult("X",nResults-1); //What is the centre of the described ellipse?
	centY=getResult("Y",nResults-1); //What is the centre of the described ellipse?

	longAx=0; //Set a variable to which to compare the length of the long axis
	shortAx=100000; //Set a variable to which to compare the length of the short axis
	xpoints2=newArray(0); //make a new array to store unique x data 
	ypoints2=newArray(0); //make a new array to store unique y data
	tempLong=0; //initiate a variable which will store the temporary Long axis
	tempShort=0; //initiate a variable which will store the temporary Short axis
for (point=1;point<lengthOf(xpoints)-1;point++){ //for the 2nd to 2nd last point
		
		yLog=newArray(0,0); //these 2-item arrays are for looking at the point after and the point before
		xLog=newArray(0,0);
		//for these logical arrays; difference == 1, same-ness == 0
		if (xpoints[point]!=xpoints[point-1]){ //If the x point before is not the same
			xLog[0]=1; //mark it as different
			//print(point);
		}
		if (xpoints[point]!=xpoints[point+1]){//If the x point after is not the same
			xLog[1]=1;//mark it as different
		}
		if (ypoints[point]!=ypoints[point-1]){
			yLog[0]=1;
		}
		if (ypoints[point]!=ypoints[point+1]){
			yLog[1]=1;
		}
		
		if (xLog[0]+xLog[1]!=0 && yLog[0]+yLog[1]!=0){ //If the XY coords are unique in the list
		xpoints2=Array.concat(xpoints2,xpoints[point]); //record the x coords
		ypoints2=Array.concat(ypoints2,ypoints[point]); //record the y coords
		}

	}
	
for (point=1;point<lengthOf(xpoints2)-1;point++){ //for the 0th to the 2nd to last point
	x1=centX; //get 1st Xcoord
	x2=xpoints2[point]; //get 1st Ycoord
	y1=centY;
	y2=ypoints2[point];
	xDist=(x1-x2)*(x1-x2); 
	yDist=(y1-y2)*(y1-y2);
	len=sqrt(xDist+yDist); //What's the distance between the centre and the given point in the coordinate list

	setResult("distance",nResults,len);
	if (len==longAx && tempLong==len){ //If the calculated length is the same as the existing long axis
		longAx=len; //This is probably unnecessary, but I'm not taking it out
		longX=(xpoints2[point-1]+xpoints2[point])/2; //record the X-origin of the long axis as being halfway between the point we're looking at, and the one before
		longY=(ypoints2[point-1]+ypoints2[point])/2; //record the Y-origin of the long axis as being halfway between the point we're looking at, and the one before
		}
		else if (len>longAx){ //If the calculated length is longer than the existing long axis
		longAx=len; //record the calculated length as the long axis
		longX=xpoints2[point]; //the X-origin of the long axis
		longY=ypoints2[point]; //the Y-origin of the long axis
		}
		
	if (len==shortAx && tempShort==len){//If the calculated length is the same as the existing short axis
		shortAx=len; //This is probably unnecessary, but I'm not taking it out
		shortX=(xpoints2[point-1]+xpoints2[point])/2;//the X-origin of the short axis
		shortY=(ypoints2[point-1]+ypoints2[point])/2;//the Y-origin of the short axis
		}
	else if (len<shortAx){//If the calculated length is shorter than the existing short axis
		shortAx=len;//record the calculated length as the short axis
		shortX=xpoints2[point];//the X-origin of the short axis
		shortY=ypoints2[point];//the Y-origin of the short axis
		tempShort=len;
		}

}
tempLen=len;
yDist=sqrt((centY-longY)*(centY-longY));
xDist=sqrt((centX-longX)*(centX-longX));	
lAxisAngle=atan2((centY-shortY),(centX-shortX))*(180/PI); //this returns the angle between the centre and the short axis XY position in degrees

		
  return lAxisAngle; 
} 

/* Here are some shanges you might make to this script to attune it better to your analysis: 
 *  Line 23 - change the 1 to 2, depending on which channel is better for finding your cells of interest.
 *  Line 26 - Change "Intermodes" to a different threshold determiner, like "Otsu", "Minimum", "Mean", "Default"; this will make a big difference.
 *  Line 110 - change the _output\\ to _output/ if you're using a Mac.
 *  Lines 84-93 make it so the brighter half of the cell is on the left; if your cells are not normally brighter on one side than the other, this 
 *  section of the code can be commented out, or left as-is.
 */