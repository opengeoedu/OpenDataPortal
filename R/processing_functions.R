geocode_nominatim <- function(address, email="info@opengeoedu.de", country=NULL, country_codes="de,ch,at,li" , verbose=FALSE) {
      #address <- htmltools::htmlEscape(address, attribute = TRUE);address
      address <- stringr::str_replace_all(address, "ß","ss")
      #address <- "Europaplatz 1, A-7000 Eisenstadt" #for testing
      # address <- "Stadt Mannheim, Rathaus E 5, D-68159 Mannheim"
      address <- unlist(stringr::str_split(address,", "));address
      len <- length(address)
      result=list(lat=NA_real_, lon=NA_real_, success=FALSE)
      if(len>1){
        
        city <- unlist(stringr::str_split(stringr::str_trim(address[len]),pattern = " "))
        if(length(city)>=2){
          city <- paste0("&city=",paste(city[2:length(city)], collapse = " "),"&postalcode=",city[1])
        }else{
          city <- stringr::str_trim(address[len])
        }
        query <- paste0("street=",address[len-1],city)
      }else{
        query <- paste0("q=",address)
      }
      .url <- paste0("http://nominatim.openstreetmap.org/search?",URLencode(query),"&format=xml")
      if(!is.null(country_codes))
        .url <- .url %>% paste0("&country_codes=",country_codes)
      if(!is.null(email))
        .url <- .url %>% paste0("&email=",email)
      if(!is.null(country))
      .url <- .url %>% paste0("&country=",country)
      success <- TRUE
      desc <- NULL
      tryCatch({
        if(verbose)
          message("Sending request: ",.url)
        con <- url(.url)
        xres <- xml2::read_xml(con)
        if(verbose)
          message(xres)
        xloc <- xml2::xml_find_first(xres, ".//place")
        
        lon <- xml2::xml_attr(xloc,"lon")
        lat <- xml2::xml_attr(xloc,"lat")
        name <- xml2::xml_attr(xloc,"display_name")
        type <- xml2::xml_attr(xloc,"osm_type")
        message("Found coordinates ",lat,", ",lon," for address ", paste(address, collapse = ", "))
        lat <- as.numeric(lat) # TODO: maybe separate try/catch for the conversion
        lon <- as.numeric(lon)
        if(!is.na(lon) && !is.na(lat)){
          result <- list(lat=lat, lon=lon, success=TRUE)
        }else{
          message("Request was not successfull:\n\t:",.url)
        }
        
      }, error = function(e){
        success <- FALSE
        print(e)
      },finally = {
        try(close(con), silent = TRUE)
        
      })
      if (!success) {
        warning("Failed determine geolocation of ",  paste(address, collapse = ", "))
      }
      
      
      return(result)
}

countryname_from_latlon_factory <- function(geonames_countryinfo = read.csv("data/geonames_countryinfo_de.csv", sep="\t")){
  countryname_from_latlon <- function(lat,lon, fatal=FALSE){
   # print(formals())
    
    geocode <- function(lat, lon){
      pt <- sf::st_point(c(lon, lat)) # be careful about the order!!!
      pt <- sf::st_sf(1,list(pt),crs=4326)
      pt <- pt %>% sf::st_transform(3857)
      
      worldmap <- sf::st_as_sf(maps::map("world", fill = TRUE)) %>% sf::st_transform(3857)
      country<-sf::st_filter( worldmap,pt,.predicate=sf::st_contains)
      if(dim(country)[1]>1){
        stop("Ambigous result, multiple countries match the coordinates?!")
      } else if(dim(country)[1]<1){
        stop("cannot find matching country from coordinates ",lat," / ",lon)
      }
      
      cname <- country$ID[1]
      isoalpha <- maps::iso.alpha(cname)
      countryinfo <- geonames_countryinfo %>% subset(iso.alpha2==isoalpha)
      if(dim(countryinfo)[1]!=1){
        #normally should not occur:
        stop("Cannot unambigiously match country code ",isoalpha," with country name. Result:")
        print(countryinfo)
      }
      
      return(countryinfo$name)
    }
    
    if(fatal)
      return(geocode(lat, lon))
    else
      tryCatch(
        return(geocode(lat,lon)),
        error=  function(e){
          warning(e)
          return(FALSE)
        }
      )
  }
  return(countryname_from_latlon)
}

countryname_from_latlon <- countryname_from_latlon_factory()
rm(countryname_from_latlon_factory)



#####
# Dialog functions assuming the "portals"-data.frames as input:
#####

## Some mandatory columns are ommited in the new-entry form but can be inferred 
## using this function:
infer_columns_from_formdata <- function(newentry_data){
  has_laton <- newentry_data$Adresse_Herausgeber %>% str_detect("\\d{1,2}\\.\\d*.+[NS],.+\\d{1,3}\\.\\d*.+[EW]") %>% which()
  message("Lat / lon coordinates were detected for ", length(has_laton), " entries and automatically infered as columns.")
  
  message("adding missing possibly columns: ID, lat, lon and Land")
  if(!"ID" %in% colnames(newentry_data)){
    try(newentry_data <- newentry_data %>% tibble::add_column(ID = NA_character_, .before=1))
  }
  if(!"lat" %in% colnames(newentry_data)){
    if("Adresse_Herausgeber" %in% colnames(newentry_data))
      try(newentry_data <- newentry_data %>% tibble::add_column(lat = NA_real_, .after="Adresse_Herausgeber"))
    else
      try(newentry_data <- newentry_data %>% tibble::add_column(lat = NA_real_))
  } 
  if(!"lon" %in% colnames(newentry_data)){
    try(newentry_data <- newentry_data %>% tibble::add_column(lon = NA_real_, .after="lat"))
  }
  if(!"Land" %in% colnames(newentry_data)){
    try(newentry_data <- newentry_data %>% tibble::add_column(Land = NA_character_, .after="lon"))
  }
  
  
  message("Infering coordinates from user input...")
  newentry_data[has_laton,]$lat <- gsub("(\\d{1,2}\\.\\d*).+N.*","\\1", newentry_data$Adresse_Herausgeber[has_laton])  %>% as.numeric()
  newentry_data[has_laton,]$lon <- gsub(".*[^0-9]*(\\d{1,3}\\.\\d*).+E.*","\\1", newentry_data$Adresse_Herausgeber[has_laton]) %>% as.numeric()
  # note: south and west coordinates may not be relevant here and therefore omitted
  return(newentry_data)
}



# tries to infer missing coordinates and country from address information and opens user dialog if necessary
# presumes that the following input columns are givin: lon, lat, Titel, Land, Adresse_Herausgeber
infer_location_information <- function(newentry_data, ask = TRUE){
  sel_missing_coords <- which(newentry_data$lat %>% is.na() & newentry_data$lon %>% is.na())
  
  always_apply <- !ask
  skip_geocoding <- FALSE
  for(i in sel_missing_coords){
    if(skip_geocoding)
      break;
    message("Entry number ",i," (",newentry_data$Titel[i],") has no coordinates!")
    country <- newentry_data$Land[i]
    if(is.na(country) || country =="" || length(country)==0)
      country <- NULL
    if(!newentry_data$Adresse_Herausgeber[i] %>% is.na()){
      cat("Try geocoding... ")
      result <- geocode_nominatim(address = newentry_data$Adresse_Herausgeber[i], country = country)
    }else{
      message("There is no given address information for gocoding. Please add the location information manually!")
      next
    }
    once_apply = FALSE
    while(TRUE & result$success){
      #print(result)
      if(!always_apply){ #skip dialog if user previously chose to always apply the geocoding data
        message("Should the detected geocoding result be applied to the data?\n\t(y)es, (n)o, yes to (a)ll, (s)kip geocoding for all entries")
        choice <- readline()
        if(choice=="y")
          once_apply <- TRUE
        else if(choice=="a"){
          always_apply <- TRUE
        }
        else if(choice=="n"){
          break;
        } else if(choice=="s"){
          skip_geocoding <- TRUE
          break;
        } else{
          message("Unknown input, please retry!")
          next
        }
      }
      if(always_apply || once_apply){
        newentry_data$lat[i] <- result$lat
        newentry_data$lon[i] <- result$lon
        newentry_data[i,] <- infer_country(newentry_data[i,])
        break;
      }
    }
    cat("\n") #spacing for messages
  }
  # infer country for all other rows, where coordinates are available
  newentry_data <- infer_country(newentry_data)
  return(newentry_data)
}

infer_country<-function(newentry_data){
  sel_missing_country <- which(newentry_data$Land %>% is.na() |
                                 newentry_data$Land %>% is.null() |
                                 newentry_data$Land == "" )
  #  print(newentry_data)
  # print(sel_missing_country)
  for(i in sel_missing_country){
    lat <- newentry_data$lat[i]
    lon <- newentry_data$lon[i]
    #message(lat," ",lon)
    if(!(lat %>% is.na() && lon %>% is.na())){
      country <- countryname_from_latlon(lat = lat, lon = lon)
      #print(country)
      if(!isFALSE(country)){
        message("Inferred country name: ",country," from lat:  ", lat, " and lon:", lon)
        newentry_data[i,"Land"] <- country
      }
    } else(
      message("Country cannot be determined for entry ", i)
    )
  }
  return(newentry_data)
}


