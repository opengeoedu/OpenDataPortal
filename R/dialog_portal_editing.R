library(shiny)
# devtools::install_github("matthiashinz/DTedit")
library(DTedit)
library(stringr)
library(shinyjs)
library(daff)
library(dplyr)
library(xml2)
source("R/utils.R")
source("R/processing_functions.R")
#source("R")

tableeditor1 <- function(mydata, additionalContent="") {

  #mydata$Land <- lapply(mydata$Land,function(str){
   # str_split(str,",") %>% unlist() %>% as.character() %>% str_trim()
  #})
  ##### Create the Shiny server
  server <- function(input, output) {
  
    #mydata$Land <-sapply(mydata$Land,function(str) paste(str, collapse = ", "))
  #  mydata <- #data.frame(name = character(),
               #          email = character(),
                #         useR = factor(levels = c('Yes', 'No')),
                 #        notes = character(),
                  #       stringsAsFactors = FALSE)
    
    ##### Callback functions.
    my.insert.callback <- function(data, row) {
      #mydata <<- rbind(data, mydata)
      mydata <<- data
      return(mydata)
    }
    
    my.update.callback <- function(data, olddata, row) {
      #print(list(data=data, olddata=olddata, row=row))
      mydata[row,] <<- data[row,]
      return(mydata)
    }
    
    my.delete.callback <- function(data, row) {
      mydata <<- mydata[-row,]
      return(mydata)
    }
    # special input types and select-choices to define the editor's behavior. Other inputs are inferred from the column data type if not specified manually
    my.input.types <- list(Beschreibung='textAreaInput', Reichweite = "selectInput", Staatlich_Öffentlich ="selectInput") #requires added work: #Land="selectInputMultiple"),
    my.input.choices = list(Typ = unique(mydata$Typ), Reichweite = unique(mydata$Reichweite), Staatlich_Öffentlich = unique(mydata$Staatlich_Öffentlich), Land=unique(unlist(mydata$Land)))
    
    # filter out input definitions not present in input data - that is to prevent the code from breaking when column names do not match:
    my.input.types <- my.input.types[names(my.input.types) %in% names(mydata)]
    my.input.choices <- my.input.choices[names(my.input.choices) %in% names(mydata)]
    
    my.input.choices = list()
    my.input.types = list()
    
    ##### Create the DTedit object
    DTedit::dtedit(input, output,
                   name = 'portaledit',
                   thedata = mydata,
                   edit.cols = colnames(mydata),
                   edit.label.cols = colnames(mydata),
                   input.types = my.input.types,
                   view.cols = colnames(mydata),
                   input.choices = my.input.choices,
                    textarea.width = "850px",
                   textarea.height = "100px",
                   callback.update = my.update.callback,
                   callback.insert = my.insert.callback,
                   modal.size="l",
                   callback.delete = my.delete.callback, selectize = TRUE)
    
    observeEvent(input$endEditing, {
      js$closeWindow()
      stopApp()
    })
  }
  
  ##### Create the shiny UI
  ui <- bootstrapPage(
    h3('Portaldaten-Editor'),
    actionButton('endEditing','Quit!',align="center", class="btn-success"),
    tags$br(),
    tags$br(),
    useShinyjs(),
    extendShinyjs(text =  "shinyjs.closeWindow = function() { window.close(); }", functions = c("closeWindow")),
    additionalContent,
    uiOutput('portaledit')
    #actionButton('endEditing','Quit!',class="btn-success")
  )
  
  ##### Start the shiny app
  #shinyApp(ui = ui, server = server, )
  runApp(list(ui = ui, server = server), launch.browser = TRUE)
  return(mydata)
}


edit_portale <- function(sourcefile="data/portale_geocoded4.csv"){
  portale <- read.csv(sourcefile, as.is = TRUE) %>% convertFactors(order_it = FALSE)
  result <- editDialog(portale)
  if(result$data_changed){
    write.csv(result$new_data, file = "data/portale_geocoded4.csv", row.names = FALSE)
    message("CSV is written. Updating data...")
    source("R/generate_all_data.R")
  }
}

#check location information may only work properly for portal data
editDialog <- function(input_data, check_location_information = FALSE) {
  new_data <- input_data
  editing <- TRUE
  data_changed <- FALSE
  while(TRUE){
    if(editing){
      new_data <- tableeditor1(new_data)
      new_data <- infer_location_information(new_data)
      editing <- FALSE
    }else{
      message("[Editor dialog] Unknown choice. Pleas type again!")
    }
  # 
    diff_result <- daff::diff_data(input_data,new_data)
    message("[Editor dialog] Summary of changes:")
    print(summary(diff_result))
    message("[Editor dialog] How do you want to continue?")
    message("(c)ontinue editing (r)eview changes (s)ave changes and re-write data (d)iscard changes")
    choice <- readline() %>% str_trim()
    if(choice=="c"){
      editing <- TRUE
      next
    } else if(choice=="s"){
      data_changed = TRUE
      break
    } else if(choice=="r"){
      diff_result %>% render_diff() 
      next 
    } else if(choice=="d"){
      new_data <- input_data
      break 
    }
    
  }
  return(list(new_data=new_data, data_changed=data_changed))
}
#editDialog(portale)



merge_new_entries <- function(){
    
    source("R/utils.R")
    source("R/new_entry_form.R")
    source("R/processing_functions.R")
    
    message("reading new data:")
    newentry_data <- load_form_entry_data(include_example = FALSE, public_information = TRUE, filename_col = TRUE) # %>% convertFactors(order_it = FALSE)
    creator_information <- load_form_entry_data(include_example = FALSE, creator_information_only = TRUE, filename_col = TRUE, public_information = FALSE)
    
    if(is.null(newentry_data) || nrow(newentry_data) == 0){
      message("There are no entries to be merged. All done! :)")
      return(invisible())
    }
    # infer implicit information and add mandatory columns
    # also asks the user to confirm given locations/coordinates
    newentry_data <- infer_columns_from_formdata(newentry_data)
    ## tries to geocode where addresses are given and coordinates are missing
    newentry_data <- infer_location_information(newentry_data)
    portale_new <- portale <- readPortalDataCSV()
    ## TODO: maybe validate if country and coodinates are matching?
    oldentry_data <- newentry_data ## keep state of data in order to compare user changes
    while(TRUE){
      message("There are ",dim(newentry_data)[1], " new entries. How do you proceed?")
      message("\t1. open (e)ditor for viewing and all new entries before the review \n\t (changes will only persist until quit)")
      message("\t2. (m)erge all entries if possible")
      message("\t3. (q)uit this dialog.")
      
      choice <- readline()
      if(choice=="e"){
        changed_data <- tableeditor1(newentry_data)
        difftable <- daff::diff_data(newentry_data, changed_data)
        summary(difftable) %>% print()
        difftable %>% render_diff()
        newentry_data <- changed_data
        newentry_data <- infer_location_information(newentry_data)
        message("Entry data is changed temporarily, the differences are displayed.")
        message("Note that the changes will only be permanent upon completing the review process.\n")
      } else if(choice=="q"){
          break;
      } else if(choice=="m"){
       
        
        #overwriting_rows <- 
          
      
          
          # new entries require a new ID. If the entry has an existing ID,
          # users/admin will be asked whether the original entry shall be overwritten,
          # edited or, whether a new entry should be created or wheter the entry shall be discarded 
          sel_overwriting_rows <- newentry_data$ID %in% portale$ID
          
          new_rows <- newentry_data[!sel_overwriting_rows,]
          overwriting_rows <- newentry_data[sel_overwriting_rows,]
          
          merged_rows <- overwriting_rows[0,]
          
          if(nrow(overwriting_rows)>0)
          for(i in nrow(overwriting_rows)){
            overwriting_row <- overwriting_rows[i,]
            original_entry <- portale %>% subset(ID==overwriting_row$ID)
            # new row, as it will be merged
            #, preserving additional fields if available in original data
            # IMPORTANT: column names of the right must match
            preview_row <- original_entry
            preview_row[, colnames(overwriting_row[,-c("file","Autor")])] <- overwriting_row[,-c("file","Autor")]  
            
            while(TRUE){
              message("A new entry would overwrite the existing portal entry with ID ", overwriting_row$ID)
              message("Please make a choice:")
              message("\t1. (c)ontinue. The original entry will be overwritten!")
              message("\t2. (s)how differences between old and new entry")
              message("\t3. (e)dit the new entry")
              message("\t4. (d)iscard the new entry")
              message("\t5. (c)reate new entry instead")
              message("\t6. (q)uit merge dialog (all current edits will be lost!)")
              choice <- readline()
              if(choice=="c"){
                portale_new[overwriting_row$ID, ] <- preview_row
                #keep track of merges:
                merged_rows <- merge(merged_rows, overwriting_row, all = TRUE) 
                break;
              } else if(choice=="s"){
                daff::diff_data(original_entry, preview_row) %>% render_diff()
                next;
              }else if(choice=="e"){
                difftable <- daff::diff_data(original_entry, preview_row) 
                summary(difftable) %>% print()
                diff_html <- difftable %>% render_diff(fragment = TRUE)
                preview_row <- tableeditor1(preview_row, additionalContent =
                                              list(tags$h2("Summary of changes:"), tags$style(".modify{  background-color:#5555ff;}"), shiny::HTML(diff_html), tags$br()))
                preview_row <- infer_location_information(preview_row)
                difftable <- daff::diff_data(original_entry, preview_row) 
                summary(difftable) %>% print()
                diff_html <- difftable %>% render_diff(fragment = TRUE)
                next;
              }else if(choice=="d"){
                #by not adding the row to "merged entries", the entry will be discarded later
                break;
              }else if(choice=="c"){
                overwriting_row$ID <- NA # removing the misleading ID
                new_rows <- merge(new_rows, overwriting_row) # will be treated just like other new rows
                break;
              }else if(choice=="q"){
                message("Merge abborted by user")
                return(invisible())
              }else{
                message("Unknown input, please retry!")
                next
              }
              
            }
          }
          
        
          print(new_rows)
          new_rows$ID = (max(portale_new$ID)+1):(max(portale_new$ID)+dim(new_rows)[1])
          message("Generated new ids for new entries:\n\t", new_rows$ID %>% paste(collapse = " "))
          #names(portale)
          portale_new <- merge(portale_new, new_rows[, -c("file","Autor")], all = TRUE)
          merged_rows <- merge(merged_rows, new_rows, all=TRUE)
          
          while(TRUE){
             difftable <- daff::diff_data(portale, portale_new) 
             summary(difftable) %>% print()
             difftable %>% render_diff()
         
          message("Please review the final changes at the dataset and choose:")
          message("\t1. (c)ontinue merge\n\t2. (e)dit the new table further\n\t(q)uit and discard all changes")
          choice = readline()
          if(choice=="c"){
              break;
          }else if(choice=="e"){
              portale_new <- tableeditor1(portale_new)
              portale_new <- infer_location_information(portale_new)
              difftable <- daff::diff_data(portale, portale_new) 
              summary(difftable) %>% print()
              difftable %>% render_diff()
             next
          } else  if(choice=="q"){
            message("Merge abborted by user")
            return(invisible())
          } else{
              message("Unknown input, please retry!")
              next
          }
        }
      ## each form submission is stored in a file within the data/user_input directory
      ## this code keeps track of wich contributions were accepted or discarded by the admin/user
    
      sel_discarded_files <- which(!oldentry_data$file %in% merged_rows$file)
      sel_accepted_files <- which(oldentry_data$file %in% merged_rows$file)
      
      if(sel_discarded_files %>% length() > 0){
          message("The following submission files be archived to the folder data/user_input/discarded,")
          message("you may consider writing feedback/thanks")
          print(creator_information[sel_discarded_files, ])
          discarded_files <- creator_information[sel_discarded_files, "file"] %>% unlist()
          target_dir <- fs::path("data/user_input/deprecated")
          if(!dir.exists(target_dir))
            dir.create(target_dir)
          fs::file_move(discarded_files,
            fs::path(target_dir, fs::path_file(discarded_files)))
      }
      if(sel_accepted_files %>% length() > 0){
        message("The following submission files be archived to the folder data/user_input/accepted")
        message("you may consider writing feedback/thanks")
        print(creator_information[sel_accepted_files, ])
        accepted_files <- creator_information[sel_accepted_files, "file"] %>% unlist()
        target_dir <- fs::path("data/user_input/accepted")
        if(!dir.exists(target_dir))
          dir.create(target_dir)
        fs::file_move(accepted_files,
                      fs::path(target_dir, fs::path_file(accepted_files)))
      }
      ## this part is critical
      write.csv(portale_new, file = "data/portale_geocoded4.csv", row.names = FALSE)
      source("R/generate_all_data.R")
      message("All done! :)")
      
      break;#critical (still inside the loop)
      
      }else{
            message("Unknown input, please retry!")
            next
      }
    }
}
