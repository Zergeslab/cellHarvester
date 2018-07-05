/*
 * Having assembled a large number of cells that are all oriented correctly, put them into a single folder that only contains cells from one
 * condition/timepoint/genotype. This macro will then open all the images in a folder, scale them appropriately in X, Y and intensity, and 
 * then generate various projections and save those as .tifs.
 * 
 */
 
 run("Close All"); //make sure all images are closed
fPath=getDirectory("Choose a Directory"); //select a directory
fList=getFileList(fPath); // make a list of the contents of the directory

File.makeDirectory(fPath+"output\\");//make a directory in the directory being analysed
run("Clear Results"); //clear existing results
updateResults();

imWidths=newArray(lengthOf(fList)); //make an array to store image Widths
imHeights=newArray(lengthOf(fList));

for (image=0;image<lengthOf(fList);image++){ //for each item in the file list
	if (fList[image]!="output\\"){ //if it's name is not output\\
	open(fPath+fList[image]); //open it
	imWidths[image]=getWidth(); //remember its width and height
	imHeights[image]=getHeight();
	}
}

imList=getList("image.titles"); //make a variable containing the name of all open images
wRank=Array.rankPositions(imWidths); //the widest image is last in the array
hRank=Array.rankPositions(imHeights); //the tallest image is last in the array

widePos=wRank(lengthOf(wRank)-1); //remember the width of the widest image (i.e. the longest cell)
heightPos=hRank(lengthOf(hRank)-1); //remember the height of the tallest image (i.e. to widest cell)

dims=newArray(2); //make a new array to store width and height
dims[0]=imWidths[widePos];
dims[1]=imHeights[heightPos];

//Lines 46 and 47 normalise the intensity of all images so that dim images contribute to the final projections as much as bright ones

for (image=0;image<lengthOf(imList);image++){ //for every open image

	selectWindow(imList[image]); //select the window
	run("Select None"); //make sure nothing is selected
	setSlice(1); //select the first channel
	getRawStatistics(nPixels, mean, min, max, std, histogram); //get info about the channel
	run("Subtract...", "value="+min); //subtract the minimum intensity from all pixels
	run("Multiply...","value="+4095/max); //make the maximum value 4095
	run("Size...", "width="+dims[0]+" height="+dims[1]+" average interpolation=Bilinear"); //rescale the image size in X and Y to the size of the biggest image
	setSlice(2); //repeat lines 44-48 for the second channel
	run("Select None");
	getRawStatistics(nPixels, mean, min, max, std, histogram);
	run("Subtract...", "value="+min);
	run("Multiply...","value="+4095/max);
	run("Size...", "width="+dims[0]+" height="+dims[1]+" average interpolation=Bilinear");
}

//The user will give the output images a title that reflects the group/timepoint/genotype/treatment from which they come
imTitle=getString("Enter the title here (e.g. 2H)", "Title"); 
run("Concatenate...", "all_open title=["+imTitle+"]"); //Make a stack of images from all open images

run("Z Project...", "projection=[Sum Slices]"); //Make a Sum projection and save the image in the output folder
saveAs("tif",fPath+"output\\"+getTitle()+".tif");
selectWindow(imTitle);
run("Z Project...", "projection=[Average Intensity]"); //Make a Mean projection and save the image in the output folder
saveAs("tif",fPath+"output\\"+getTitle()+".tif");
selectWindow(imTitle);
run("Z Project...", "projection=[Min Intensity]"); //Make a Minimum projection and save the image in the output folder
saveAs("tif",fPath+"output\\"+getTitle()+".tif");
selectWindow(imTitle);
run("Z Project...", "projection=[Max Intensity]"); //Make a Maximum projection and save the image in the output folder
saveAs("tif",fPath+"output\\"+getTitle()+".tif");