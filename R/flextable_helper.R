# thanks to David Gohel
# see https://stackoverflow.com/questions/52661289/is-there-an-easy-way-to-convert-flat-contingency-tables-ftable-to-flextable

ftable_to_flextable <- function( x , include_rowsums=FALSE){
  
  row.vars = attr( x, "row.vars" )
  col.vars = attr( x, "col.vars" )
  rows <- rev(expand.grid( rev(row.vars), stringsAsFactors = FALSE ) )
  cols <- rev(expand.grid( rev(col.vars), stringsAsFactors = FALSE ))
  
  xmat <- as.matrix(x)
  cols$col_keys = dimnames(xmat)[[2]]
  
  ############
  # this addition by M. Hinz adds row sums in to the grouping columns
  ###########
  if(include_rowsums)
    for(i in 1:length(rows)){
      if(i>1){
        group_values <- apply(rows[,1:i], 1, paste, collapse="_")
      }else{
        group_values <- rows[,1]
       }
      rowsums <- rowSums(rowsum(xmat, group = group_values))
      rows[,i] <- paste0(rows[,i]," (", rowsums[group_values],")")
    }
  ############
  xdata <- cbind(
    data.frame(rows, stringsAsFactors = FALSE),
    data.frame(xmat, stringsAsFactors = FALSE)
  )
  names(xdata) <- c(names(row.vars), cols$col_keys)
  

  
 # xdata$Land <- paste0(xdata$Land," (", aggr.num,")")
  
  ft <- flextable::regulartable(xdata)
  ft <- flextable::set_header_df(ft, cols)
  ft <- flextable::theme_booktabs(ft)
  ft <- flextable::merge_v(ft, j = names(row.vars))
  ft
}
