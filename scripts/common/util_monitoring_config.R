
monitoringReportConfig.new <- function(homeDir, logInfo) {
    cat("Setting up monitoring config \n")
    reportInfo <- monitoringReportConfig._newReportInfo(homeDir, logInfo)
    storeInfo <- monitoringReportConfig._newStoreInfo(homeDir, logInfo)

    monitoringReportConfig <- list(homeDir=homeDir,
                                   logInfo=logInfo,
                                   reportInfo=reportInfo,
                                   storeInfo=storeInfo
                                   )

    cat("Monitoring config DONE \n")
    monitoringReportConfig
}

monitoringReportConfig._newStoreInfo <-  function(homeDir, logInfo) {
    storeDir=sprintf("%s/results/%s", homeDir, logInfo$day)
    if (!file.exists(storeDir))
        dir.create(storeDir, recursive=TRUE)

    storeInfo <- list(storeDir=storeDir)
}

monitoringReportConfig._newReportInfo <-  function(homeDir, logInfo) {
    cat("Setting up monitoring config - report info \n")
    reportDirValue <- sprintf("%s/reports/%s/%s/%s", homeDir,
                              logInfo$day, logInfo$component, logInfo$instance)
    cssFolder <- "css"
    cssFile <- "main.css"
    cssFileUrl <- sprintf("%s/%s", cssFolder, cssFile)

    reportInfo <- list(reportDir=reportDirValue,
                       htmlFileName=sprintf("%sReport.html", logInfo$component),
                       cssFolder=cssFolder,
                       cssFile=cssFile,
                       cssFileUrl=cssFileUrl,
                       imagesFolder="images",
                       plotsFolder="plots")

    reportDir <- reportInfo$reportDir

    cat(sprintf("Creating report dir %s \n", reportDir))
    if (!file.exists(reportDir))
        dir.create(reportDir, recursive=TRUE)
    if (!file.exists(reportDir))
        cat(sprintf("ERROR creating directory %s \n", reportDir))
    else {
        cat(sprintf("INFO directory %s has been created \n", reportDir))
    }

    cssDir <- sprintf("%s/%s", reportDirValue, cssFolder)
    if (! file.exists(cssDir) ) {
        cat(sprintf("Creating directory %s \n", cssDir))
        dir.create(cssDir, recursive=TRUE)
    }

    cssSource <- sprintf("%s/config/css/main.css", homeDir)
    if (! file.exists(cssSource) )
        cat("ERROR css file %s does not exist \n", cssSource)
    cssDestination <- sprintf("%s/%s", reportDirValue, cssFileUrl)
    cat(sprintf("Copying %s to %s \n", cssSource, cssDestination))
    file.copy(cssSource, cssDestination, overwrite=TRUE, recursive=TRUE)

    imagesDir <- sprintf("%s/%s", reportDirValue,
                         reportInfo$imagesFolder)
    if (! file.exists(imagesDir) ) {
        cat(sprintf("Creating directory %s \n", imagesDir))
        dir.create(imagesDir, recursive=TRUE)
    }

    reportInfo
}
