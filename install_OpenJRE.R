# Install JRE

# Packages
require(rvest)
require(openssl)


install.open.jre <- function(path.jre = file.path(Sys.getenv("HOME"),
                                                  "OpenJRE"),
                             set.env.variable = TRUE,
                             provider = "amazon") {

  provider <- tolower(el(as.character(provider)))

  if (!(provider %in% c("adopt", "zulu", "amazon"))) {
    stop("Nepareizs JRE provider nosaukums")
  }

  if (provider == "adopt") {
    cat("Instalējam AdoptOpenJDK, https://adoptopenjdk.net/ \n")
  } else if (provider == "zulu") {
    cat("Instalējam Zulu JDK, https://www.azul.com/downloads/zulu/ \n")
  } else if (provider == "amazon") {
    cat("Instalējam Amazon Corretto, https://aws.amazon.com/corretto/ \n")
  }

  cat("Instalācija tiek veikta folderī:", path.jre, "\n")
  dir.create(path.jre, showWarnings = FALSE)

  if (provider == "adopt") {
    base.url <- "https://github.com"
    html.doc <- read_html(file.path(base.url,
                                    "AdoptOpenJDK/openjdk8-binaries/releases"))
  } else if (provider == "zulu") {
    base.url <- "https://cdn.azul.com/zulu/bin"
    html.doc <- read_html(base.url)
  } else if (provider == "amazon") {
    base.url <- NA_character_
    html.doc <- read_html("https://docs.aws.amazon.com/corretto/latest/corretto-8-ug/downloads-list.html")
  }

  url.list <- html_nodes(html.doc, "a") %>% html_attr(name = "href")

  if (provider == "adopt") {
    down.list <- grep("jre_x64_windows_hotspot_8u.*(zip|zip.sha256.txt)$",
                      url.list, value = T)
  } else if (provider == "zulu") {
    down.list <- grep("fx-jre8.*-win_x64.zip$", url.list, value = T)
  } else if (provider == "amazon") {
    down.list <- grep("windows-x64-jre.zip$", url.list, value = T)
  }

  down.list <- sort(down.list, decreasing = T)

  zip.name <- el(grep("zip$", down.list, value = T))
  zip.base.name <- basename(zip.name)

  cat("Instalācijas fails:", zip.base.name, "\n")

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

  # Pārbaude
  if (provider == "adopt") {
    txt.name <- el(grep("txt$", down.list, value = T))

    if (!file.exists(file.path(path.jre, basename(txt.name)))) {
      download.file(url = file.path(base.url, txt.name),
                    destfile = file.path(path.jre, basename(txt.name)),
                    method = "wininet")
    }

    checksum <- read.table(file.path(path.jre, basename(txt.name)))$V1
    con <- file(file.path(path.jre, zip.base.name))
    if (gsub(":", "", sha256(x = con)) != checksum) stop("Neparezs fails")
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

  cat("Instalācija ir pabeigta\n")
}

# install.open.jre()
# install.open.jre(provider = "adopt")
# install.open.jre(provider = "amazon")
# install.open.jre(provider = "zulu")
