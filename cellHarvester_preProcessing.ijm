/*
 * To run this macro, you should have two windows open, each containing a different channel of a deconvolved Z-stack. 
 * Perhaps obviously, these must have the same number of Z-slices and bit-depth.
 */
 
imList=getList("image.titles"); //Makes a list of both open windows
run("Concatenate...", "  title=[Concatenated Stacks] image1=["+imList[0]+"] image2=["+imList[1]+"] image3=[-- None --]"); //Concatenates those images into a single stack
sCount=nSlices(); // Counts how many slices thre are in the concatenated stack
run("Stack to Hyperstack...", "order=xyztc channels=2 slices="+sCount/2+" frames=1 display=Composite"); //Re-organise that stack so that it is a hyperstack with 2 channels
run("Z Project...", "projection=[Max Intensity]"); //Make a Max intensity projection; there will be a single-plane, 2-channel image.
setSlice(1); //Reset the Min and Max to appropriate levels so that when the image is next opened, it looks good.
resetMinAndMax();
setSlice(2)
resetMinAndMax();
saveAs("Tif"); //Allows the user to specify where and with what name to save the image.