# Install JRE
# Function definition

install.open.jre <- function(path.jre = file.path(gsub("\\\\", "/",
                                                       Sys.getenv("HOME")),
                                                  "OpenJRE"),
                             set.env.variable = TRUE,
                             provider = "amazon",
                             version = 11L) {

  x <- rownames(installed.packages())
  if (!"rvest" %in% x) stop("Please install the rvest package!")
  if (!"openssl" %in% x) stop("Please install the openssl package!")

  # Packages
  library(rvest)
  library(openssl)

  # Test OS
  if (.Platform$OS.type != "windows") stop("Works only on Windows")


  # Provider
  provider <- tolower(el(as.character(provider)))

  if (!(provider %in% c("adopt", "zulu", "amazon")))
    stop("Wrong JRE provider specified. Possible values are adopt, zulu, amazon.")

  if (provider == "adopt") {
    cat("Installing AdoptOpenJDK, https://adoptopenjdk.net/\n")
  } else if (provider == "zulu") {
    cat("Installing Zulu JDK, https://www.azul.com/downloads/zulu/\n")
  } else if (provider == "amazon") {
    cat("Installing Amazon Corretto, https://aws.amazon.com/corretto/\n")
  }


  # Version
  version <- as.integer(el(version))
  if (!(version %in% c(8L, 11L))) stop("Version should be 8 or 11")
  cat("Java version:", version, "\n")


  if (provider == "amazon" & version == 11L)
    cat("JDK version is available only\n")


  # Install folder
  cat("Installation in folder:", path.jre, "\n")
  dir.create(path.jre, showWarnings = FALSE)


  # Load HTML doc
  if (provider == "adopt") {
    base.url <- "https://github.com"
    html.doc <- read_html(file.path(base.url,
                                    paste0("AdoptOpenJDK/openjdk", version,
                                           "-binaries/releases")))
  } else if (provider == "zulu") {
    base.url <- "https://cdn.azul.com/zulu/bin"
    html.doc <- read_html(base.url)
  } else if (provider == "amazon") {
    base.url <- NA_character_
    html.doc <- NULL
  }

  if (!is.null(html.doc))
    url.list <- html_nodes(html.doc, "a") %>% html_attr(name = "href")

  if (provider == "adopt") {
    down.list <- grep("jre_x64_windows_hotspot.*(zip|zip.sha256.txt)$",
                      url.list, value = T)
  } else if (provider == "zulu") {
    down.list <- grep(paste0("fx-jre", version, ".*-win_x64.zip$"),
                      url.list, value = T)
  } else if (provider == "amazon") {
    down.list <- NA_character_
  }

  if (length(down.list) == 0L) stop("Installation file was not found")

  down.list <- sort(down.list, decreasing = T)

  if (provider %in% c("adopt", "zulu")) {
    zip.name <- el(grep("zip$", down.list, value = T))
  } else if (provider == "amazon" & version == 8L) {
    zip.name <- "https://corretto.aws/downloads/latest/amazon-corretto-8-x64-windows-jre.zip"
  } else if (provider == "amazon" & version == 11L) {
    zip.name <- "https://corretto.aws/downloads/latest/amazon-corretto-11-x64-windows-jdk.zip"
  }

  zip.base.name <- basename(zip.name)

  cat("Instalation file:", zip.base.name, "\n")

  if (is.na(base.url)) {
    down.url <- zip.name
  } else {
    down.url <- file.path(base.url, zip.name)
  }

  if (!file.exists(file.path(path.jre, zip.base.name))) {
    download.file(url = down.url,
                  destfile = file.path(path.jre, zip.base.name),
                  method = "wininet")
  }

  # Test checksum
  if (provider == "adopt") {
    txt.name <- el(grep("txt$", down.list, value = T))
    con <- url(file.path(base.url, txt.name))
    checksum <- sub(" .*$", "", readLines(con, warn = FALSE))
    close(con)
  } else if (provider == "amazon") {
    if (version == 8L) {
      txt.name <- "https://corretto.aws/downloads/latest_checksum/amazon-corretto-8-x64-windows-jre.zip"
    } else if (version == 11L) {
      txt.name <- "https://corretto.aws/downloads/latest_checksum/amazon-corretto-11-x64-windows-jdk.zip"
    }
    con <- url(txt.name)
    checksum <- readLines(con, warn = FALSE)
    close(con)
  }

  if (provider %in% c("adopt", "amazon")) {
    con <- file(file.path(path.jre, zip.base.name))
  }

  if (provider == "adopt") {
    testsum <- sha256(x = con)
  } else if (provider == "amazon") {
    testsum <- md5(x = con)
  }

  if (provider %in% c("adopt", "amazon")) {
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

# install.open.jre(provider = "adopt" , version = 8L)
# install.open.jre(provider = "amazon", version = 8L)
# install.open.jre(provider = "zulu"  , version = 8L)

# install.open.jre(provider = "adopt" , version = 11L)
# install.open.jre(provider = "amazon", version = 11L)
# install.open.jre(provider = "zulu"  , version = 11L)

install.open.jre(version = 8)
install.open.jre(version = 11)
