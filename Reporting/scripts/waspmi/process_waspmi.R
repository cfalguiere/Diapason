# TODO: Add comment
#
# Author: Claude.Falguiere
###############################################################################
source("scripts/waspmi/util_waspmi_data.r")
source("scripts/waspmi/util_waspmi_html.r")
source("scripts/common/util_monitoring_config.r")

processFile <- function(dataFilePath) {

    print(dataFilePath)

    logInfo <- wasPerf.extractLogInfo(dataFilePath)
    print(logInfo)

    monitoringReportConfig <-
        monitoringReportConfig.new(homeDir,
                                   logInfo)

    configFilename <- "./inbox/hewqalive/was_perf_config.xml"
    cat(sprintf("reading config in %s \n", configFilename))
    config <- wasPerfConfig.load(configFilename)

    cat(sprintf("reading metrics in %s \n", dataFilePath))
    doc <- wasPerfLog.load(dataFilePath)
    storeDir <- monitoringReportConfig$storeInfo$storeDir
    outFileName <- sprintf("%s/%s/was_pmi_%s_%s.csv",
                           storeDir, logInfo$component, logInfo$day,  logInfo$instance)
    wasPerf.export(doc, config, outFileName, logInfo$time)

    #htmlFilePath <- jbossReport.make(dataFilePath, monitoringReportConfig)

    cat(sprintf("storing file %s \n", dataFilePath))
    storedDataFilePath <- wasPerf.storeResult(dataFilePath,
                                                   monitoringReportConfig)

}

homeDir <- getwd()
print(homeDir)


wasFiles <- list.files(path = "./inbox", pattern = "was_perf_.*_.*.xml",
           all.files = FALSE,
           full.names = TRUE, recursive = TRUE,
           ignore.case = FALSE)
print(wasFiles)

logInfo <- wasPerf.extractLogInfo(wasFiles[1])
print(logInfo)
monitoringReportConfig <- monitoringReportConfig.new(homeDir, logInfo)
print(monitoringReportConfig)
filename <- sprintf("%s/%s/was_pmi_%s_%s.csv",
                           monitoringReportConfig$storeInfo$storeDir, 
                           logInfo$component, logInfo$day, logInfo$instance)
print(filename)
file.remove(filename)

lapply(wasFiles, processFile)

#logInfo <- wasPmiReport.extractLogInfo(filename)
#monitoringReportConfig <-
#        monitoringReportConfig.new(".", logInfo)
print("generating reports")
print(filename)
mainHtmlFilePath <- wasPmiReport.make(filename, monitoringReportConfig)
