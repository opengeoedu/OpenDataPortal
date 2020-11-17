require(svDialogs)
require(blastula)
config_file <- "~/.config/.blastula.creds"

create_config_dialog <- function(config_file) {
  message("Please type config:")
  form <- list(
    "host:TXT" = "www.example.com",
    "port:NUM" = 587,
    "user:TXT" = "user@example.com",
    "use_ssl:CHK" = TRUE
  )
  email.conf <- dlg_form(form, "My data")$res
  with(email.conf,
       create_smtp_creds_file(config_file, host = host, port = port, user = user, use_ssl = use_ssl)
  )
}

if(file.exists(config_file)){
  message("E-Mail config exists at location ", config_file)
  while(TRUE){
    message("(s)how old config, (k)eep / (r)eplace with new config?")
    choice <- readline()
    if(startsWith(choice,"k")){
      break
    }else if(startsWith(choice,"r")){
      create_config_dialog(config_file)     
      break;
    }else if(startsWith(choice,"s")){
      print(creds_file(config_file))     
    }
  }
}else{
  message("E-Mail config does not exist at  ", config_file)
  while(TRUE){
    message("(c)reate new config? Type any other key to abort")
    choice <- readline()
    if(startsWith(choice,"c")){
      create_config_dialog(config_file)     
      break;
    }
    else{break;}
  }
}


