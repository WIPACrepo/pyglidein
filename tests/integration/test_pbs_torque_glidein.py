import htcondor
import os
import time
import unittest
from minio import Minio


class TestPBSTorqueGlidein(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.glidein_site = 'WIPAC_Dev'
        cls.minio_url = 'minio:9000'
        cls.minio_bucket = 'wipac-dev'
        cls.minio_acces_key = 'minio'
        cls.minio_secret_key = 'minio123'
        cls.minio_secure = False
        cls.pyglidein_client_name = 'pyglidein-client'

    def test_glidein_startd(self):

        glidein_site = 'WIPAC_Dev'

        # Submitting some sleep jobs
        job = {"executable": "/bin/sleep",
               "arguments": "5m",
               "request_memory": "500"}

        sub = htcondor.Submit(job)
        schedd = htcondor.Schedd()
        with schedd.transaction() as txn:
            sub.queue(txn, 100)

        # Waiting for the glideins to start
        time.sleep(60)

        coll = htcondor.Collector()
        startds = coll.locateAll(htcondor.DaemonTypes.Startd)

        self.assertTrue(len(startds) > 0,
                        msg='No STARTDs found.')
        for startd in startds:
            self.assertTrue(
                startd['GLIDEIN_Site'] == glidein_site,
                msg='GLIDEIN_Site CLASSAD: {} not equal to {}'.format(
                    startd['GLIDEIN_Site'], glidein_site))

    def test_submit_hello_world(self):

        output_file = "test_submit_hello_world_out"
        output_text = "hello pyglidein"
        job = {"executable": "/bin/echo",
               "arguments": output_text,
               "output": output_file,
               "request_memory": "500"}

        sub = htcondor.Submit(job)
        schedd = htcondor.Schedd()
        with schedd.transaction() as txn:
            cluster_id = sub.queue(txn)

        # Waiting for job to complete
        for i in xrange(0, 5):
            if sum(1 for _ in schedd.history('ClusterId=={}'.format(cluster_id), ['ClusterId', 'JobStatus'], 1)) == 0:
                time.sleep(1)
            else:
                break

        self.assertTrue(os.path.exists(output_file),
                        msg="Output file doesn't exist.")

        with open(output_file, 'r') as f:
            data = f.readlines()[0].rstrip()
        self.assertEqual(data, output_text,
                         msg='Output File Text: {} not equal to {}'.format(data, output_text))

    def test_logging(self):

        # Submitting some sleep jobs
        job = {"executable": "/bin/sleep",
               "arguments": "5m",
               "request_memory": "500"}

        sub = htcondor.Submit(job)
        schedd = htcondor.Schedd()
        with schedd.transaction() as txn:
            sub.queue(txn, 100)

        # Waiting for the glideins to start
        time.sleep(60)

        client = Minio(self.minio_url,
                       access_key=self.minio_acces_key,
                       secret_key=self.minio_secret_key,
                       secure=self.minio_secure
                       )
        objects = client.list_objects(self.minio_bucket, prefix=self.glidein_site, recursive=False)
        object_count = sum(1 for _ in objects)
        self.assertTrue(object_count > 0)

    def tearDown(self):

        schedd = htcondor.Schedd()
        schedd.act(htcondor.JobAction.Remove, 'true')


if __name__ == '__main__':
    unittest.main()
