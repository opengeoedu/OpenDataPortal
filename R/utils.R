
convertFactors  <- function(portale, order_it=TRUE){
  table_meta <- jsonlite::read_json("data/table_meta.json", simplifyVector = TRUE)
  
  portale$Reichweite <- factor(portale$Reichweite, levels=table_meta$reichw, ordered =order_it)
  portale$Typ <- factor(portale$Typ, levels=table_meta$typ, ordered = order_it)
  portale$Staatlich_Öffentlich <- factor(portale$Staatlich_Öffentlich, levels = table_meta$staatl)
  return(portale)
}

readPortalDataCSV <- function(){
  read.csv("data/portale_geocoded4.csv", as.is = TRUE) %>% convertFactors(order_it = FALSE)
}
