
#############
# Prepare contingency tables for data portals by country, type and range
###############
portale <- read.csv("data/portale_geocoded4.csv")
table_meta <- jsonlite::read_json("data/table_meta.json", simplifyVector = TRUE)

source("R/utils.R")
portale <- convertFactors(portale)

portale$label = htmlEscape(paste(portale$Titel, "|", portale$Ort))
portale$Typ_names <- portale$Typ
levels(portale$Typ_names) <- table_meta$typ_names

#Statistik über die eingetragenen Datenportale:

#blue table (matching the design color)
colorP <- colorRampPalette(colors = c("white","#009de0"))

#'old' blue table
#colorP <- colorRampPalette(colors = c("white","#044e96"))
#gray table
#colorP <- colorRampPalette(colors = c("white","gray"))
tab_colors <- colorP(10)

#selector for country-values that involve multiple values (not one of either austria, swiss or germany)
sel <- which(!(portale$Land %in% c("Deutschland", "Österreich", "Schweiz")))
# create simplified categories for the statistics
Land <- as.character(portale$Land)
Land[sel] <- "Sonstige"
Land <- factor(Land, levels = c("Deutschland", "Österreich","Schweiz", "Sonstige"), ordered = TRUE)
Typ <- portale$Typ_names

portale.types <- data.frame(Typ = Typ, Land = Land, Reichweite = portale$Reichweite)
ftab <- ftable(portale.types)

# add summary per Typ and Country
aggr.num <- ftable(portale.types[,c("Typ","Land")]) %>% as.numeric()

#statistics per country:
country_stat <- paste0("(",paste(c("DE","AU","CH", "Sonst"),summary(Land), sep = ": ",collapse = ", "),")")


############################
## Render frequency table using the Flextable-package 
###########################

library(flextable)
library(officer)
source("R/flextable_helper.R")
render_stat_table <- function(freq_table){
    
    big_border = fp_border(color="black", width = 2)
    border_v = fp_border(color="black")
    border_h = fp_border(color="black")
    
    portale.flextable <- ftable_to_flextable(freq_table, include_rowsums=TRUE) %>%
              theme_zebra(odd_header = tab_colors[5] ,odd_body = tab_colors[2]) %>%
              add_footer_lines(values = paste("Datenportale insgesamt:",dim(portale)[1], country_stat)) %>%
              bg(part="footer", bg=tab_colors[5]) %>%
              border_inner_h(part="body", border = border_h ) %>%
              border_inner_h(part="footer", border = big_border ) %>%
              border_inner_v(part="body", border = border_v ) %>%
              border_outer(part="all", border = big_border ) %>%
              border_inner_v(part="footer", border = big_border ) %>%
             # font(fontname = "Helvetica, Arial, Geneva, sans-serif", part="all") %>%
            #  fontsize(size=15, part = "all") %>%
              align(align="center")
}
portale.flextable <- render_stat_table(ftab)
portale.flextable

stat.typ.reichweite <- render_stat_table(
  ftable(portale.types[,c("Typ","Reichweite")])
  )
stat.typ.reichweite

stat.typ.land <- render_stat_table(
  ftable(portale.types[,c("Typ","Land")])
)
stat.typ.land


stat.reichweite.land <- render_stat_table(
  ftable(portale.types[,c("Reichweite","Land")])
)
stat.reichweite.land




#######################################
## Writing Tables into DOCX and CSV file
####
if(!dir.exists("out"))
  dir.create("out")

library(officer)

autonum <- run_autonum(seq_id = "tab", bkm = "datenportale")
read_docx()  %>% body_add_par("Übersicht über das Open Data Suchportal", style="heading 1" ) %>%
  body_add_flextable(
    portale.flextable %>% 
      set_caption(caption = "Anzahl der Datenportale nach Portal-Typ, Land und Reichweite", autonum = autonum) %>%
      autofit() 
    ) %>%
  body_add_flextable(
    stat.typ.reichweite %>% 
      set_caption(caption = "Anzahl der Datenportale nach Portal-Typ und Reichweite", autonum = autonum) %>%
      autofit() 
  ) %>%
  body_add_flextable(
    stat.typ.land %>% 
      set_caption(caption = "Anzahl der Datenportale nach Portal-Typ und Land", autonum = autonum) %>%
      autofit() 
  ) %>%
  body_add_flextable(
    stat.reichweite.land %>% 
      set_caption(caption = "Anzahl der Datenportale nach Reichweite und Land", autonum = autonum) %>%
      autofit() 
  ) %>% print(target="out/verzeichnis_statistik.docx")


write.csv(data.frame(ftab), "out/verzeichnis_haeufigkeitsverteilung.csv")

#render statistics table
statistics_html <- htmltools_value(portale.flextable)






