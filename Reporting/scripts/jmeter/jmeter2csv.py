import sys, os, re
from xml.sax import make_parser
from xml.sax.handler import ContentHandler
from datetime import datetime
from datetime import date
import csv

def indexLookup(entry, name):
    return entry[name] == name


class JMeterSampleHandler(ContentHandler):
    """
      parse jmeter records (sample, httpsample, httpsample as sub result)
      output the record as csv file
      columns are added :
      - st stands for sample type (T, P, D)
      - id and pid (parent id)
      - ts as date + time + microseconds

      TODO
      link transactions with pages
      link cycle with transactions
    """
    record = {}
    jmeterAttributes = ['ts','t','lt','s','lb','rc','rm','tn','dt','by','na','ng',
        'search__phrase','productId','productUrl','catLevel1Url','catLevel2Url']
    recordAttributes = ['st', 'id','pid','tsdate','tstime','tsms','wh'] + jmeterAttributes
    transactionCount = 0
    pageCount = 0
    detailCount = 0
    delimiter='|'
    quotechar='"'
    index = [ ]
    openedFilesIndex = [ ]

    def __init__ (self, sas) : #, param, csvWriter
        self.index = [ ]
        self.openedFilesIndex = [ ]
        self.sas = sas
        self.isTransactionSampleElement, self.isPageSampleElement, self.isDetailSampleElement = False, False,False

    def extractSample(self,attrs) :
        for attr in self.jmeterAttributes :
          self.record[attr]  = attrs.get(attr,"")
        self.convertTimeStamp(self.record)
        return


    def closeFiles(self):
        for entry in self.openedFilesIndex :
            file = entry["file"]
            file.close()
        self.openedFilesIndex = []
        self.index = []

    def writeRecord(self):
        if not self.record['st'] == 'T':
            return

        if (self.transactionCount % 5000) == 0:
            print("transaction count = %d" % self.transactionCount)

        record = []
        for attr in self.recordAttributes:
            record.append(self.record[attr])

        label = self.record['lb']
        #entry = filter(lambda entry: entry["name"]==label, self.index)
        entries = [x for x in self.index if x["name"] == label]
        #print("files %s" % entries)
        i = len(entries)
        #print(i)
        new_file = False
        if i<1:
            #print("new label %s" % label)
            i = len(self.index)+1
            file_name = "T%d.csv" % (i)
            self.index.append({"name":label, "file": file_name})
            new_file = True
        else:
            entry = entries[0]
            file_name = entry["file"]
            #print(file_name)

        output_file_name = os.path.join(self.sas, file_name) #todo
        if new_file:
            output_file = open(output_file_name, 'w')
            writer = csv.writer(output_file, delimiter=self.delimiter,
                          quotechar=self.quotechar, quoting=csv.QUOTE_MINIMAL)
            self.openedFilesIndex.append({"name":label, "file": output_file})
            writer.writerow(self.recordAttributes)
            print("Creating file " + output_file_name)
        else:
            entries = [x for x in self.openedFilesIndex if x["name"] == label]
            #print("opened files %s " % entries)
            entry = entries[0]
            output_file = entry["file"]
            #print("Adding to writer " + label)
            writer = csv.writer(output_file, delimiter=self.delimiter,
                          quotechar=self.quotechar, quoting=csv.QUOTE_MINIMAL)
        writer.writerow(record)

    def convertTimeStamp(self, record) :
        """
          convert ts to ISO 8601 format splitted in 3 fields
          date  2009-07-31
          time 14:05:01
          ms 567
          python expect seconds whereas java date is in ms. Both are base year 1970
        """
        java_timestamp = int(record['ts'])
        seconds = java_timestamp / 1000
        sub_seconds  = (java_timestamp % 1000.0) / 1000.0
        ts = datetime.fromtimestamp(seconds + sub_seconds)
        #print(ts)
        self.record['tsdate'] = ts.strftime('%Y-%m-%d')
        self.record['tstime'] = ts.strftime('%H:%M:%S')
        self.record['tsms'] = ts.strftime('%f')
        hour = ts.hour
        self.record['wh'] = 'N'
        if (hour >= 7 and hour <= 20) :
            self.record['wh'] = 'Y'
        return

    def startElement(self, name, attrs) :
        if name == 'sample':
            self.isTransactionSampleElement = True
            self.transactionCount += 1
            self.extractSample(attrs)
            self.record['st'] = 'T'
            self.record['id'] = 'T' + str(self.transactionCount)
            self.record['pid'] = ""
            self.writeRecord()
        elif name == 'httpSample' and self.isPageSampleElement :
            self.isDetailSampleElement = True
            self.detailCount += 1
            self.record['st'] = 'D'
            self.record['id'] = 'D' + str(self.detailCount)
            self.record['pid'] = 'P' + str(self.pageCount)
            self.extractSample(attrs)
            self.writeRecord()
        elif name == 'httpSample' :
            self.isPageSampleElement = True
            self.pageCount += 1
            self.record['st'] = 'P'
            self.record['id'] = 'P' + str(self.pageCount)
            self.record['pid'] = ''
            self.extractSample(attrs)
            self.writeRecord()
        elif name == 'testResults' :
            print ('entering test results')
        return

    def endElement(self, name) :
        if name == 'sample':
            self.isTransactionSampleElement = False
        elif name == 'httpSample' and self.isDetailSampleElement :
            self.isDetailSampleElement = False
        elif name == 'httpSample' and self.isPageSampleElement :
            self.isPageSampleElement = False
        elif name == 'testResults' :
            print ('leaving test results')
        return

    def characters (self, ch):
        return


class JMeter2Csv:
    def processInbox(self, inbox_dir_name, sas_home):
        # trouver les fichiers
        # traiter le fichier
        print ("browsing " + inbox_dir_name + " ...")
        pattern = re.compile("\w+-[0-9-]+-[0-9-].jtl") 
        pattern = re.compile(".*jtl") 
        nbProcessed = 0
        for root, dirs, files in os.walk(inbox_dir_name):
            for f in files :
                match = re.search(pattern, f)
                if match :
                    file = os.path.join(root,f)
                    print("Processing %s" % file)
                    sas = self.processFile(file, sas_home)
                    new_name = os.path.join(os.path.dirname(sas),f)
                    os.rename(file, new_name)
                    nbProcessed += 1
        print("jmeter2csv completed")
        print("number of files processed: %d" % nbProcessed)
    
    def processFile(self, input_file_name, sas_home):
        sas = self.get_sas_name(input_file_name, sas_home)
        if not os.path.exists(sas):
            os.makedirs(sas)

        jmeterSampleHandler = JMeterSampleHandler(sas) #param, csvWriter, filter)
        parser = make_parser()
        parser.setContentHandler(jmeterSampleHandler)
        parser.parse(open(input_file_name))

        index = jmeterSampleHandler.index
        output_file_name = os.path.join(sas, "index.csv")
        writer = csv.writer(open(output_file_name, 'w'), delimiter='|',
                          quotechar='"', quoting=csv.QUOTE_MINIMAL)
        writer.writerow(["name", "file"])
        for entry in index:
            writer.writerow([entry["name"], entry["file"]])

        jmeterSampleHandler.closeFiles()
        
        return sas

    def get_sas_name(self, input_file_name, sas_home):
        sp1 = os.path.split(input_file_name)
        file_name = sp1[1]
        sp2 =  os.path.split(sp1[0])
        test_type = sp2[1]
        print("test_type=" + test_type)
        m = re.match('(?P<test_name>[^-]+-\d+-\d+).jtl', file_name)
        test_name = m.group('test_name')
        print("test_name=" + test_name)
        m = re.match('[^-]+-(?P<test_date>\d+)-\d+', test_name)
        test_date = m.group('test_date')
        formatted_date = test_date[0:4] + '-' + test_date[4:6] + '-' + test_date[6:8]
        sas = "%s/%s/%s/%s" % (sas_home, formatted_date, test_type, test_name)
        print("sas=" + sas)
        return sas
        
def main() :
    #usage sample test file Inbox/myapp/mytestplan-20100625-1523.jtl 
    #usage sample output Results/2010-06-25/myapp/testplan-20100625-1523 containing csv files
    #usage cd Diapason\Reporting
    #usage ..\..\python31-win32\python.exe scripts\jmeter\jmeter2csv.py Inbox Results
    inbox_name = sys.argv[1]
    print ('inbox home: %s' % inbox_name)
    sas_home = sys.argv[2]
    print ('results home: %s' % sas_home)

    jmeter2csv = JMeter2Csv()
    sas = jmeter2csv.processInbox(inbox_name, sas_home)

if __name__ == '__main__' :
    main()
