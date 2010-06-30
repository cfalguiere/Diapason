import os, sys
import unittest
from shutil import copytree, rmtree
from tempfile import mkdtemp

sys.path.append("../scripts/jmeter")

from jmeter2csv import JMeter2Csv
import csv

class JMeter2CsvTest(unittest.TestCase):
    def testCanParseSamples(self):
        """ """
        input_file = "jmeter/data/inbox/testname/test_plan_00-20100312-1.jtl"
        output_dir =  "jmeter/output/results1"
        
        jmeter2csv = JMeter2Csv()
        sas = jmeter2csv.processFile(input_file, output_dir)
        
        self.assertEqual(output_dir + "/2010-03-12/testname/test_plan_00-20100312-1", sas)
        
        self.assertEqual(True, os.path.exists(sas))
        csv_file = os.path.join(sas, "T1.csv")
        self.assertEqual(True, os.path.exists(csv_file))

        index_file = os.path.join(sas, "index.csv")
        self.assertEqual(True, os.path.exists(index_file))

        indexReader = csv.reader(open(index_file, newline=''), delimiter='|', quotechar='"')
        nb = 0
        for row in indexReader:
            if len(row)>0:
                nb += 1
        self.assertEqual(12, nb)

        csvReader = csv.reader(open(csv_file, newline=''), delimiter='|', quotechar='"')
        nb = 0
        for row in csvReader:
            if len(row)>0:
                nb += 1
        self.assertEqual(5, nb)

    def testCanScanInbox(self):
        """ """
        inbox_ref = "jmeter/data/inbox"
        inbox_dir = "jmeter/output/inbox" #mkdtemp()
        rmtree(inbox_dir, True)
        copytree(inbox_ref, inbox_dir)
        files = os.listdir(inbox_dir)
        self.assertNotEqual(0, len(files))

        output_dir =  "jmeter/output/results2"
        rmtree(output_dir, True)
        jmeter2csv = JMeter2Csv()
        jmeter2csv.processInbox(inbox_dir, output_dir)
        
        test_result_dir = output_dir + "/2010-03-13/testname/test_plan_00-20100313-1"
        self.assertEqual(True, os.path.exists(test_result_dir))
        csv_file = os.path.join(test_result_dir, "T1.csv")
        self.assertEqual(True, os.path.exists(csv_file))

        files = os.listdir(os.path.join(inbox_dir,"testname")) #does not remove test folder
        print("files after testCanScanInbox %s " % files)
        self.assertEqual(0, len(files))
        
        rmtree(inbox_dir, True)

    def testCanParsePageSamples(self):
        """ """
        input_file = "jmeter/data/inbox/testname/test_plan_00-20100312-1.jtl"
        output_dir =  "jmeter/output/results1"
        
        jmeter2csv = JMeter2Csv()
        sas = jmeter2csv.processFile(input_file, output_dir)
        
        self.assertEqual(output_dir + "/2010-03-12/testname/test_plan_00-20100312-1", sas)
        
        self.assertEqual(True, os.path.exists(sas))
        csv_file = os.path.join(sas, "P1.csv")
        self.assertEqual(True, os.path.exists(csv_file))

        index_file = os.path.join(sas, "index.csv")
        self.assertEqual(True, os.path.exists(index_file))

        indexReader = csv.reader(open(index_file, newline=''), delimiter='|', quotechar='"')
        nb = 0
        for row in indexReader:
            if len(row)>0:
                nb += 1
        self.assertEqual(12, nb) # 6 T + 5 P + Header

        csvReader = csv.reader(open(csv_file, newline=''), delimiter='|', quotechar='"')
        nb = 0
        for row in csvReader:
            if len(row)>0:
                nb += 1
        self.assertEqual(5, nb)


if __name__ == "__main__":
    unittest.main()