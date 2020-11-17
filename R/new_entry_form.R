outputDir <- "data/user_input"

saveData <- function(data) {
  if(!dir.exists(outputDir)){
    dir.create(outputDir)
  }
  data <- t(data)
  # Create a unique file name
  fileName <- sprintf("Edits_%s_%s.csv", as.integer(Sys.time()), digest::digest(data))
  # Write the file to the local system
  write.csv(
    x = data,
    file = file.path(outputDir, fileName), 
    row.names = FALSE, quote = TRUE
  )
}

send_mail<- function(from = creds_file("config/.blastula.creds")$user, recipient = creds_file("config/.blastula.creds")$user,subject,message){
  tryCatch({
      require(blastula)
      email <-
        compose_email(
          body = md(message)
          )
      
      email %>%
        smtp_send(
          from = from,
          to = recipient,
          subject = subject,
          credentials = creds_file("config/.blastula.creds")
        )
  }, error=function(e){ 
    if(shiny::isRunning()){  
      shinyjs::alert(e)
    } else{
      print(e)
    }
  })
}

email_to_user <- function(data, dry_run = FALSE) {
  email <- data[["Email"]]
  autor <- data[["Autor"]]
  newsletter <- as.logical(data[["Newsletter"]])
  message <-  readLines("config/message.html")
  ## create visual summary table of the submission:
  summary_table <- data[!names(data) %in% c("Email", "Autor","Newsletter","Einverstaendnis")] #%>% t() %>% as.data.frame()
  summary_table <- data.frame(Attribute=names(summary_table) %>% sapply(URLdecode), Werte=as.character(summary_table))
  summary_table
  #rownames(summary_table) <- NULL
  html_table <- flextable(
    summary_table
  ) %>% 
    theme_box() %>%
    fontsize(size=15,part = "all") %>%
    font(fontname = "Roboto, Helvetica, sans-serif",part = "all") %>%
    htmltools_value()
  
  compose_email(html_table) # for test-displaying the table
  summary_text <- html_table %>% as.character()
  ## Add Email-Newsletter notification to confirmation email
  if(newsletter){
    summary_text <- paste0(summary_text,
                           tags$br(), 
                           tags$b("Ihrem Wunsch gemäß werden wir Ihre E-Mail-Adresse dem Newsletter-Verteiler von OpenGeoEdu hinzufügen. Mit einer kurzen Nachricht an info@opengeoedu.de können diese jederzeit wieder austragen lassen.")
    )
  }
  message <- str_replace(message, "\\[ZUSAMMENFASSUNG\\]", summary_text) %>%
   str_replace("\\[ANREDE\\]", paste0("Guten Tag ",autor,",")) %>% 
   paste(collapse = "\n")
  
  # compose_email(md(message)) # for test-displaying the table
  if(str_detect(email, "^.*@.*\\..*$") && !dry_run){
    send_mail(recipient = email,subject = "[OpenGeoEdu] Vielen Dank für Ihren Beitrag!", message = message) 
  }else{
    return(compose_email(md(message)))
  }
}


email_to_team <- function(data, dry_run=FALSE) {
  email <- data[["Email"]]
  autor <- data[["Autor"]]
  ##thanks mailto: (template for confirmation after merging submission)
  thanks_mailto <- ""
  if(file.exists("config/thanks_message.txt")){
    thanks_message <-  readLines("config/thanks_message.txt") %>%
      str_replace("\\[AUTOR\\]", autor) %>%
      str_replace("\\[BEITRAG\\]", data[["Titel"]])
    thanks_message <- tags$a(href=
                               #paste0("mailto:",autor," <",email,">",
                               paste0("mailto:",email,
                                      "?subject=[OpenGeoEdu] Ihr Beitrag wurde veröffentlicht",
                                      "&body=",thanks_message
                               ),
                             "Nach Veröffentlichung Dank-Email verfassen!")
    thanks_mailto <- tags$p("PS:", thanks_message)
  }
  
  html_table <- data.frame(Attribute=names(data) %>% sapply(URLdecode), Werte=as.character(data)) %>% 
    flextable() %>%
    theme_box() %>%
    fontsize(size=15, part = "all") %>%
    font(fontname = "Roboto, Helvetica, sans-serif",part = "all") %>%
    align(part = "all", align = "left") %>%
    htmltools_value() 
  
  message <- paste0(
    "Liebes OpenGeoEdu-Team,",
    tags$p("ein Nutzer hat einen Neuen Beitrag zum OpenDataPortal eingesendet."),
    html_table,
    tags$p("Bitte kontrollieren Sie die Angaben."),
    tags$p("Es grüßt"),
    tags$p("das OpenDataPortal"),
    thanks_mailto,
    collapse="\n")
  
  ## personalize email subject if autor is given
  vonautor <- ""
  if (!is.na(autor) && autor != ''){
    vonautor <- paste(" von",autor)
  }
  if(!dry_run)
      send_mail(from=c("OpenDataPortal (noreply)" = "portal@opengeoedu.de"),
            recipient = "info@opengeoedu.de" ,
            subject = paste0("Neuer Eintrag",vonautor), message = message)
  else
    return(compose_email(md(message)))
}

# automated emails will only work with email-templates and server setup configured
create_emails <- function(data){
  #save(data, file="test_emails.rdata") ## use for saving test data
 # load("test_emails.rdata")
  require(blastula)
  require(jsonlite)
  require(stringr)
  

  # print(summary(data))
  # print(data)
  # print(names(data))
  # print(class(data))
  # dnames <- names(data)
  # data <- t(data.frame(data))
  # colnames(data) <- dnames
  #data <- data[,!colnames(data) %in% c("Email", "Autor")]
  #print(data)
  
  #shinyjs::alert(dim(data)[1])
  #data <- t(data)
  #data <- data[!names(data) %in% c("Email", "Autor")]
  nms <- names(data)
  nms <- str_replace(nms,"^Oeffentlich$","&Ouml;ffentlich")
  nms <- str_replace(nms,"^Staatlich_Öffentlich$","Staatlich / &Ouml;ffentlich")
  nms <- str_replace(nms,"^Adresse_Herausgeber$","Adresse / Koordinaten des Herausgebers")
  names(data) <- nms
  data[["Typ"]] <- table_meta$typ_names[which(table_meta$typ == data[["Typ"]])]
  
  if(file.exists("config/.blastula.creds") && file.exists("config/message.html") ){
    # shinyjs::alert("Try sending mail!")
    
    ## Send confirmation Email
    email_to_user(data)
    
    ## Mail to OGE-TEAM
    email_to_team(data)
    
    
  }
}


load_form_entry_data <- function(include_example=TRUE, public_information=TRUE, creator_information_only=FALSE , filename_col=FALSE) {
  # Read all the files into a list
  files <- list.files(outputDir, full.names = TRUE)
  if(!include_example) # the example entry may not be processed
    files <- files[stringr::str_detect(files,"^((?!Beispiel).)*\\.csv$")];files
  files <- files[stringr::str_detect(files,"\\.csv$")]
  if(length(files)==0)
    return(NULL)
  data <- lapply(files, 
                 function(file){
                   entry <- read.csv(file, stringsAsFactors = FALSE)
                   col_names <- colnames(entry)
                   col_names <- str_replace(col_names, "^Oeffentlich$", "Staatlich_Öffentlich")
                   colnames(entry) <- col_names
                   if(creator_information_only){
                     entry <- entry[colnames(entry) %in% c("Autor","Email", "Einverstaendnis","Newsletter")] 
                   } 
                   if(public_information)
                      #exclude personal data columns from being returned
                      entry <- entry[!colnames(entry) %in% c("Email", "Einverstaendnis","Newsletter")]
                   if(filename_col){
                     entry$file <- file
                   }
                   entry
                 }) 
  # Concatenate all data together into one data.frame
 # data <- do.call(rbind, data)
  data <- data.table::rbindlist(data, fill = TRUE)
  data
}

