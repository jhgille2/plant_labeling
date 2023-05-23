# Automatic plant image labeling
Code to handle automatically labeling and organizing images of plants from our greenhouse studies with using QR codes and image metadata

# Problem description

![[Automating collation of individual plant images]]

The code in this directory solved both of those problems I described earlier.
# Code overview
The code for this is all in the [[sort_images.R]] file. To run, you just need to set some variables to point to input/output folders and files and then source the file. Specifically, you need to set these variables: 

- unsorted_img_folder: This is the path to the folder where all the unsorted images are kept. I have the code set up so that you can just dump all the images into one folder and it will go through and sort them appropriately. 
- sorted_img_folder: Where do you want output to go? The code will make one folder for each sample in this directory and put all of the images for each sample in those folders.
- combined_image_folder: The script also outputs a document that has the images for every sample laid out in a day x sample grid. This variable says what folder you want the output report to go to. 
- combined_image_name: What do you want to name the combined output report? **MUST END IN .md**

Once those variables are set, just source the script and the images will be sorted to folders in the output directory. 

## What is actually happening?
### Sample identifiers
The script works by extracting data from [[Avery label printing|QR codes]] that are included in each image, and extracting metadata from the image itseld. These QR codes MUST encode some text string that has the sample name in the second position in a string that is separated by underscores. In the case of the [[Washed sand nutrient dropout experiment 1]], the QR codes render a string that looks like

**experiment name_sample name** 

For example, the QR code for plant 1 looks like this when it's scanned: 

**Washed sand nutrient dropout 1\_Plant 1**

It;s important that if you use this code as-is in the future, whatever is in the second part of that underscore-separated string is some information that you want to use to keep the images together. For my uses, I wanted to keep the images from each plant together in a folder.

The actual qr codes I printed are [[plant qr codes.pdf|here]], and the csv file I used to make them are found [[qr_code_table.csv|here]]. More information about how I made these codes can be found in the [[Avery label printing]] note.

### Image dates
The second component of the script extracts the date the image was taken and adds this to the sample name. I get this from the image metadata. 

## Combining everything
Once I have the sample ID from the QR code, and the date the image was taken from the file metadata, I can combine the two to make a new filename that looks like:

**date image was taken\_sample id.jpg**

and then use this new name to copy the image from it's old location in the unsorted folder where it has it's confusing name, into a folder that is named after the sample it is an image of, with a new name that makes it much easier to find and sort.

The final part of the script is just a bit of markdown rendering. I wrote this code mainly to organize the output in my obsidian vault and one thing I can do with that is make notes that use image grids to embed the newly sorted images via [internal links](https://help.obsidian.md/Linking+notes+and+files/Internal+links). The last part of the script just takes the paths to all the newly renamed and sorted photos and arranges the paths to them on a markdown document in a way that can be rendered through obsidian. 

The script that does these steps is [[sort_images.R]], but the definitions for the functions I use in that script are in [[image_sorting_functions.R]].