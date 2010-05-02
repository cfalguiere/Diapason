# TODO: Add comment
#
# Author: Claude.Falguiere
###############################################################################
# XML Parser
library(XML)
#install.packages("XML", repos = "http://www.omegahat.org/R, dependencies=TRUE")


wasPerfLog.load <-  function(filename) {
    doc <- xmlParse(filename)
}

wasPerfLog.read <- function(doc, nodeName, serverName, metricName, metricType, attribute) {
    serverpath <- sprintf("//Node[@name='%s']/Server[@name='%s']",
                          nodeName, serverName)
    elements <- strsplit(metricName, "\\.")[[1]]
    print(elements)
    last <- length(elements)
    print(last)
    statNames <- sapply(elements,
                       function(x) {sprintf("/Stat[@name='%s']", x) }
                       )
    statNames[last] <- sprintf("/%s[@name='%s']",
                                            metricType,
                                            elements[last])
    metricPath <- Reduce(function(x,e) {paste(x,e,sep="")}, statNames, "/")
    print(metricPath)

    path <- sprintf("%s%s", serverpath, metricPath)
    print(path)
    node <- getNodeSet(doc, path)
    print(node)
    value <- sapply(node, xmlGetAttr, attribute)
}

wasPerfConfig.load <-  function(filename) {
    doc <- xmlParse(filename)
}

wasPerf.export <- function(doc, config, outFileName, ts) {
    print("Entering wasPerf.export")
    instance <- getNodeSet(config, "//instance")
    print(instance)

    metric <- getNodeSet(config, "//metric")
    print(metric)

    # todo fake time

    reading <- as.data.frame(matrix(sapply(instance, wasPerf._readNode, metric=metric, doc=doc, ts=ts),  byrow=TRUE, ncol=5))
    colnames(reading) <- c("node", "server", "metric", "ts", "value")

    print("end of export before t")
    print(reading)

    if (file.exists(outFileName)) {
        write.table(reading, outFileName, row.names=FALSE,
                   col.names=FALSE, sep=";", append=TRUE)
    } else {
        write.table(reading, outFileName, sep=";", row.names=FALSE)
    }
    print("Leaving wasPerf.export")
}

wasPerf._readNode <- function(instance, metric, doc, ts) {
    print("Entering wasPerf._readNode")
    node <- sapply(c(instance), xmlGetAttr, "node")
    server <- sapply(c(instance), xmlGetAttr, "server")

    reading <- sapply(metric, wasPerf._readMetric,
                      node=node, server=server, doc=doc, ts=ts)
    print("end of readNode")
    print(reading)
    print("Leaving wasPerf._readNode")
    reading
}

wasPerf._readMetric <- function(metric, node, server, doc, ts=ts) {
    print("Entering wasPerf._readMetric")
    label <- sapply(c(metric), xmlGetAttr, "label")
    id <- sapply(c(metric), xmlGetAttr, "id")
    path <- sapply(c(metric), xmlGetAttr, "path")
    type <- sapply(c(metric), xmlGetAttr, "type")
    attribute <- sapply(c(metric), xmlGetAttr, "attribute")
    # read value
    value <- wasPerfLog.read(doc, node, server, path, type, attribute)
    print("end of readMetric")
    reading <- c(node=node,
          server=server,
          metric=id,
          ts=ts,
          value=value)
    print("end of readMetric")
    print(reading)
    print("Leaving wasPerf._readMetric")
    reading
}

wasPerf.extractLogInfo <- function(filename) {
    elements <- strsplit(filename, "/")[[1]]
    last <-  length(elements)
    name <- elements[last]
    folder <- elements[last-1]
    print(name)
    print(folder)
    day <- gsub("was_perf_(.+)_.+.xml", "\\1", name )
    time <- gsub("was_perf_.+_(.+)-(.+).xml", "\\1:\\2:00", name )
    logInfo <- list(day=day, time=time, component="waspmi", instance=folder)
}

wasPerf.storeResult <- function(dataFilePath, monitoringReportConfig) {
    logInfo <- monitoringReportConfig$logInfo
    storeDir <- monitoringReportConfig$storeInfo$storeDir
    pmiStoreDir <- sprintf("%s/waspmi/%s", storeDir, logInfo$instance)
    if (!file.exists(pmiStoreDir))
        dir.create(pmiStoreDir, recursive=TRUE)

    elements <- strsplit(dataFilePath, "/")[[1]]
    name <- elements[length(elements)]
    storedFileName <- sprintf("%s/%s", pmiStoreDir, name)
    cat(sprintf("Moving log file %s to %s \n", dataFilePath, storedFileName))
    file.rename(dataFilePath, storedFileName)
    storedFileName
}
