withr::with_dir("../..", 
                source("R/new_entry_form.R")
    )
testthat::test_that("E-Mail messaging works", {
  withr::with_dir("../..", {
    expect_silent(
      expect_true(
        send_mail(from=c("OpenDataPortal (noreply)" = "portal@opengeoedu.de"),
              recipient = "info@opengeoedu.de" ,
              subject = paste0("Test meassage"), message = "message")
      )
    )
  })
})
