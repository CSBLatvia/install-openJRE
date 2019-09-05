# Test JRE

# Pēc instalācijas vajag RStudio restart

Sys.getenv("JAVA_HOME")

shell(cmd = "echo %JAVA_HOME%")
shell(cmd = "%JAVA_HOME%/bin/java -version")
