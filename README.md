# cellHarvester
The Cell Harvester Macro was written for the express purpose of determining the average XY distribution of signals in populations of Chlamydomonas Reinhardtii cells, though it should be able to be used with any population of cells that are roughly elliptical in XY section, and have reproducible shapes. It will *not* work with diversely-shaped cells, though it could be used to examine signal distribution in organelles.

The macro set consists of 3 parts:

cellHarvester_preProcessing - this script essentially re-organises 2 deconvolved Z-stacks containing multiple cells into a single 2-channel hyperstack. This should be run on each field of view.

cellHarvester_part1_win - this script finds the individual cells in a maximum intensity projection of an input image, isolates them, aligns them so their long axis is parallel to the X-Axis, and saves them as individual tif files. This needs to be run on each image created by cellHarvester_Preprocessing.

cellHarvester_part2_win - this script opens every image in a folder (assuming that each image is a single cell, as produced by cellHarvester_part1_win), and re-scales each cell to be the same dimensions as the largest. The intensity of each image is scaled so that the full 12-bit range is used, and each cell contributes equally to the final projections. Each cell is then overlayed into a stack, and different projections (mean,sum,max,min) are made and saved as tif files. It is assumed that the user will put all of the cells belonging to one experimental group into the same folder, and process them all together.

Questions regarding this macro set should be addressed to chris[dot]law[dot]works[at]gmail[dot]com.
