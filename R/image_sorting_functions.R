

# I want to get the plant name and the date that the image 
# was taken for each input image. I can get the plant name
# from the QR code through the quadrangle package, and the
# date the image was taken from the file metadata through
# the exiftoolr package
get_image_data <- function(image_file_path){
  
  # The file extension of the input file
  file_extention <- file_ext(image_file_path)
  
  # Get the image metadata and process the qr code
  img_metadata <- exiftoolr::exif_read(image_file_path)
  img_qr       <- quadrangle::qr_scan(image_file_path)
  
  # Get the creation date
  img_creation_dttm <- lubridate::as_date(img_metadata$CreateDate)
  
  # Get the value of the QR code
  qr_code_value <- img_qr$values$value
  print(paste(img_creation_dttm, qr_code_value))
  
  # Get the sample name from the qr code value
  # IMPORTANT: THIS ASSUMES THE SECOND PART OF THE QR CODE IS THE SAMPLE NAME
  # AND THE COMPONENTS OF THE QR CODE ARE SEPARATED BY UNDERSCORES
  sample_name <- strsplit(qr_code_value, "_")[[1]][[2]]
  
  # Make a new filename from the creation date and the qr code value
  new_file_name <- paste(img_creation_dttm, sample_name, sep = "_")
  new_file_name <- paste0(new_file_name, ".", file_extention)
  
  res <- list("old_path"      = image_file_path,
              "sample_name"   = sample_name, 
              "new_file_name" = new_file_name)
  
  return(res)
}

# This function takes in a vector of image file paths, applies the above
# function to each of them to extract the relevant data from each of them
# and then uses this data to rename the images and copy them over to 
# a new directory with a separate folder for each sample
sort_sample_photos <- function(sample_photo_dir, output_dir, ledger_path){
  
  # Read in the image ledger
  image_ledger <- read.csv(ledger_path)
  
  # What images have already been processed
  processed_image_paths <- image_ledger$old_image_path
  
  # Get the paths to all the images in the supplied photo directory
  all_photo_paths <- list.files(sample_photo_dir, full.names = TRUE, recursive = TRUE)
  
  # Remove the paths to the photos that have already been processed
  all_photo_paths <- all_photo_paths[!(all_photo_paths %in% processed_image_paths)]
  
  # Apply the get_image_data function to each of the photos to get 
  # the required data from them
  all_photo_data <- map(all_photo_paths, get_image_data)
  
  # Now, for each of the photos, go through the following process: 
  # 1. Check if there is a folder in the output_dir for the sample 
  #    (check if there is a folder that has the same name as the sample)
  #    If no, make a folder, if yes, do nothing.
  # 2. Check if the image is already inside this folder.
  #    if no, copy and rename the image from it's old location to the new 
  #    location, using the new file name from the photo data output
  
  # A vector to hold all the output file paths
  all_new_file_paths <- vector("character", length = length(all_photo_data))
  
  if(length(all_photo_data)){
    
    # Go through all of the photo data and copy files to the new directories if 
    # necessary
    for(i in 1:length(all_photo_data)){
      
      # Pull out the components of the photo data for easier use
      sample_name   <- all_photo_data[[i]]$sample_name
      new_file_name <- all_photo_data[[i]]$new_file_name
      old_file_path <- all_photo_data[[i]]$old_path
      
      # Check if there is a folder in the output directory for this sample
      sample_out_dir    <- here::here(output_dir, sample_name)
      sample_has_folder <- dir.exists(sample_out_dir)
      
      if(!sample_has_folder){
        dir.create(sample_out_dir)
      }
      
      # Check if the photo already exists in the output directory and copy
      # it to the new directory if it does not
      new_file_path <- here::here(output_dir, sample_name, new_file_name)
      
      # Copy the image to the new location if it is not already there
      if(!file.exists(new_file_path)){
        file.copy(old_file_path, new_file_path)
      }
      
      # Add the path to the new location for the photo to the 
      # all_new_file_paths vector
      all_new_file_paths[[i]] <- new_file_path
      
    }
  }
  
  # Add the paths to the new images that were just processed to the image ledger
  newly_processed_old_paths <- map_chr(all_photo_data, function(x) purrr::pluck(x, "old_path"))
  newly_processed_new_paths <- as.character(unlist(all_new_file_paths))
  
  new_image_ledger <- data.frame(old_image_path = newly_processed_old_paths,
                                 new_image_path = newly_processed_new_paths)
  
  # Add these new paths to the processed image ledger and write this new ledger to
  # the ledger file as a csv
  image_ledger_new <- rbind(image_ledger, new_image_ledger)
  write.csv(image_ledger_new, ledger_path, row.names = FALSE)
  
  # Paths to all the sorted images
  all_new_file_paths <- image_ledger_new$new_image_path
  
  # Retutn the paths to all the new photos
  return(all_new_file_paths)
}

# A function that takes images from multiple days and writes them to a 
# markdown document, sorted by day and sample number
collate_sample_photos <- function(sorted_sample_paths, outfile){
  
  # Sort the photos based on date and sample number
  sorted_names <- sort(basename(sorted_sample_paths))
  
  # css header for obsidian image tile layout
  header <- "---\n cssClass: img-grid\n\n---"
  
  # Write the css header to the output file
  write(header, file = outfile)
  
  # Split the names
  split_names <- strsplit(sorted_names, "_")
  
  # Get the unique first elements of the split names (unique days)
  unique_days <- map_chr(split_names, function(x) x[[1]]) %>% 
    unique() %>% 
    sort()
  
  # For each day, write just the images from that day to the file
  # Also write the day as a header
  for(i in 1:length(unique_days)){
    
    current_day <- unique_days[[i]]
    
    # The header for the current day
    day_header <- paste("#", current_day)
    
    # Write this header to the file
    write(day_header, outfile, append = TRUE)
    
    # Find what files from the sorted sample paths come from the current day
    current_sample_photos <- sorted_names[grep(current_day, sorted_names)]
    current_sample_photos <- sort(current_sample_photos)
    
    # Format these paths as wikilinks for rendering in obsidian and 
    # then write the links to the file
    current_images_wikilinks <- paste(paste0("![[", current_sample_photos, "]]\n"), collapse = "")
    write(current_images_wikilinks, file = outfile, append = TRUE)
    
    # Write a blank line to separate days from oneanother
    write("\n", file = outfile, append = TRUE)
    
  }
  
}
