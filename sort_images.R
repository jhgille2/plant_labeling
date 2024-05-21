## Load your packages, e.g. library(targets).
source("./packages.R")

## Load your R files
lapply(list.files("./R", full.names = TRUE), source)


## Section: Input/output paths
##################################################
# The folder where you have the input, unsorted photos
unsorted_img_folder <- "G:\\My Drive\\phd_notes\\Projects\\Sand sizes\\Max\\Watering regime and potassium phosphate experiment\\Photos\\Unsorted"

# The folder where you want to output sorted images to
sorted_img_folder <- "G:\\My Drive\\phd_notes\\Projects\\Sand sizes\\Max\\Watering regime and potassium phosphate experiment\\Photos\\Sorted"

# Path to the image path ledger
image_ledger_path <- "G:\\My Drive\\phd_notes\\Projects\\Sand sizes\\Max\\Watering regime and potassium phosphate experiment\\Photos\\max_sand_size_image_ledger.csv"

# Where you want the combined image to go
combined_image_folder <- sorted_img_folder
combined_image_name   <- "All plant images.md"
combined_image_path   <- paste0(combined_image_folder, "\\", combined_image_name)

# Sort the photos
all_output_paths <- sort_sample_photos(unsorted_img_folder, sorted_img_folder, image_ledger_path)

# Combine the photos into a report separated by day
collate_sample_photos(all_output_paths, combined_image_path)
