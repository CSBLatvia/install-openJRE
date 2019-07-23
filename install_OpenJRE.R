# Install JRE

# Packages
require(rvest)
require(openssl)


install.open.jre <- function(path.jre = file.path(Sys.getenv("HOME"), "OpenJRE"),
                             set.env.variable = TRUE) {

  dir.create(path.jre, showWarnings = FALSE)

  # AdoptOpenJDK/openjdk8-binaries
  html.doc <- read_html("https://github.com/AdoptOpenJDK/openjdk8-binaries/releases")
  url.list <- html_nodes(html.doc, "a") %>% html_attr(name = "href")
  down.list <- grep("OpenJDK8U-jre_x64_windows_hotspot_8u.*(zip|zip.sha256.txt)$", url.list, value = T)

  zip.name <- el(basename(grep("zip$", down.list, value = T)))
  txt.name <- el(basename(grep("txt$", down.list, value = T)))

  for (i in 1:2) download.file(url = file.path("https://github.com", down.list[i]),
                               destfile = file.path(path.jre, basename(down.list[i])),
                               method = "wininet")

  # Pārbaude
  checksum <- read.table(file.path(path.jre, txt.name))$V1
  con <- file(file.path(path.jre, zip.name))
  if (gsub(":", "", sha256(x = con)) != checksum) stop("Neparezs fails")


  # unzip
  unzip(zipfile = file.path(path.jre, zip.name), exdir = path.jre)


  # set JAVA_HOME
  if (set.env.variable) {
    java_home <- normalizePath(tail(list.dirs(path = path.jre, full.names = T, recursive = F), 1))
    system(command = paste("setx JAVA_HOME", java_home))
  }
}

install.open.jre()
