

#portale$lat[i] <- as.numeric(lat)
#portale$lon[i] <- as.numeric(lon)
#lat=8.462776847502461
#lon=49.4895779


#setwd("../..")
withr::with_dir("../..",{
source("R/processing_functions.R")
})

test_that("geocoding works", {
  withr::with_dir("../..",{
  result <- geocode_nominatim("Stadt Mannheim, Rathaus E 5, D-68159 Mannheim")
  expect_true(result$success)
  expect_equal(round(result$lat,2),49.49)
  expect_equal(round(result$lon,2),8.46)
  expect_false(geocode_nominatim("FALSE TEST ADDRESS")$success)
  })
})

test_that("inferring missing/implicit data works", {
  withr::with_dir("../..",{
    library(magrittr)
    portale_example <- read.csv("data/portale_geocoded4_backup.csv", stringsAsFactors = FALSE)
    example_entry <- read.csv("data/user_input/Edits_Beispiel.csv", stringsAsFactors = FALSE)
    example_entry$Adresse_Herausgeber <- "Aachen"
    example_entry %>% infer_columns_from_formdata() 
    portale_example <- merge(portale_example, example_entry, all=TRUE)
    infered_data <- portale_example %>% infer_location_information(ask=FALSE)
  })
})




test_that("country names can be inferred from lat/lon coordinates", {
  withr::with_dir("../..",{
    country_name <- countryname_from_latlon(30,-90)
    expect_equal(country_name,"USA")
    country_name <- countryname_from_latlon(52,12)
    expect_equal(country_name, "Deutschland")
  })
})
