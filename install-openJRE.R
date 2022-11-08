# Install JRE

# Test and load packages
x <- rownames(installed.packages())
if (!"rvest" %in% x) stop("Please install the rvest package!")
if (!"data.table" %in% x) stop("Please install the data.table package!")
if (!"openssl" %in% x) stop("Please install the openssl package!")

library(rvest)
library(data.table)
library(openssl)

# Check for available Java versions
url <-  "https://dev.java/download/releases/"

java <- url %>%
  read_html() %>%
  html_nodes("table") %>%
  html_table(fill = T) %>%
  lapply(., function(x) setNames(x, c("Version", "Initial Release", "Current Release",
                                      "Version Info", "End of Life")))

java_versions <- data.table(java[[1]])[, -c(4)]

java_versions <- java_versions[, `Current Release` := gsub('\n\t\t\t\t\t\t','', `Current Release`)]
java_versions

# Future Release
future_release <- data.table(java[[2]])[, -c(3)]
future_release

# Function definition

# Function parameters for testing
#
# path.jre <- file.path(gsub("\\\\", "/", Sys.getenv("HOME")), "OpenJRE")
# set.env.variable <- TRUE
# provider <- "amazon"
# version <- 11L

install.open.jre <- function(path.jre = file.path(gsub("\\\\", "/",
                                                       Sys.getenv("HOME")),
                                                  "OpenJRE"),
                             set.env.variable = TRUE,
                             provider = provider,
                             version = version) {

  # Test OS
  if (.Platform$OS.type != "windows") stop("Works only on Windows")

  # Provider
  provider <- tolower(el(as.character(provider)))

  if (!(provider %in% c("zulu", "amazon")))
    stop("Wrong JRE provider specified. Possible values are zulu or amazon.")

  if (provider == "zulu") {
    cat("Installing Zulu JDK, https://www.azul.com/downloads/zulu/\n")
  } else if (provider == "amazon") {
    cat("Installing Amazon Corretto, https://aws.amazon.com/corretto/\n")
  }


  # Version
  version <- as.integer(el(version))
  cat("Java version:", version, "\n")



  # Install folder
  cat("Installation in folder:", path.jre, "\n")
  dir.create(path.jre, showWarnings = FALSE)


  # Load HTML doc
 if (provider == "zulu") {
    base.url <- "https://cdn.azul.com/zulu/bin"
    html.doc <- read_html(base.url)
  } else if (provider == "amazon") {
    base.url <- NA_character_
    html.doc <- NULL
  }

  if (!is.null(html.doc))
    url.list <- html_nodes(html.doc, "a") %>% html_attr(name = "href")

  if (provider == "zulu") {
    down.list <- grep(paste0("fx-jre", version, ".*-win_x64.zip$"),
                      url.list, value = T)
  } else if (provider == "amazon") {
    down.list <- NA_character_
  }

  if (length(down.list) == 0L) stop("Installation file was not found")

  down.list <- sort(down.list, decreasing = T)

  if (provider %in% c("zulu")) {
    zip.name <- el(grep("zip$", down.list, value = T))
  } else if (provider == "amazon" & version == 8L) {
    zip.name <- "https://corretto.aws/downloads/latest/amazon-corretto-8-x64-windows-jre.zip"
  } else if (provider == "amazon" & version >= 8L) {
    zip.name <- file.path(paste0("https://corretto.aws/downloads/latest/amazon-corretto-",version,"-x64-windows-jdk.zip"))
  }

  zip.base.name <- basename(zip.name)

  cat("Instalation file:", zip.base.name, "\n")

  if (is.na(base.url)) {
    down.url <- zip.name
  } else {
    down.url <- file.path(base.url, zip.name)
  }

  download.file(url = down.url,
                destfile = file.path(path.jre, zip.base.name),
                method = "wininet")

  # Test checksum
  if (provider == "amazon") {
    if (version == 8L) {
      txt.name <- "https://corretto.aws/downloads/latest_checksum/amazon-corretto-8-x64-windows-jre.zip"
    } else if (version >= 11L) {
      txt.name <- paste0("https://corretto.aws/downloads/latest_checksum/amazon-corretto-",version,"-x64-windows-jdk.zip")
    }
    con <- url(txt.name)
    checksum <- readLines(con, warn = FALSE)
    close(con)
  }

  if (provider %in% c("amazon")) {
    con <- file(file.path(path.jre, zip.base.name))
  }

  if (provider == "amazon") {
    testsum <- md5(x = con)
  }

  if (provider %in% c("amazon")) {
    if (gsub(":", "", testsum) == checksum) {
      cat("Checksum test: OK")
    } else {
      stop("Checksum test failed")
    }
  }

  # unzip
  dir.name <- file.path(path.jre,
                        unzip(zipfile = file.path(path.jre, zip.base.name),
                              list = T)[1, "Name"])
  if (dir.exists(dir.name)) unlink(dir.name, recursive = T)
  unzip(zipfile = file.path(path.jre, zip.base.name), exdir = path.jre)

  # set JAVA_HOME
  if (set.env.variable) {
    java_home <- normalizePath(dir.name)
    system(command = paste("setx JAVA_HOME", java_home))
    cat("JAVA_HOME:", java_home, "\n")
  }

  cat("Instalation is complete\n")
}


# install.open.jre(provider = "amazon", version = 11L)
# install.open.jre(provider = "zulu"  , version = 11L)

# Install Java
install.open.jre(provider = "amazon", version = 11L)


# Different versions of Java can be installed
# The last installed Java version will be set with JAVA_HOME as default
