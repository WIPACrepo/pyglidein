#!/usr/bin/env python

from optparse import OptionParser
from telnetlib import Telnet


def main():

    usage = "usage: %prog [options] GRIDFTP_SERVER_FQDN GRIDFTP_SERVER_PORT"
    parser = OptionParser(usage)
    parser.add_option('--timeout', type='int', default=5,
                      help="Telnet timeout value in seconds")
    (options, args) = parser.parse_args()

    if len(args) != 2:
        raise Exception('Number Of Args != 2')
    gridftp_server_name = args[0]
    gridftp_server_port = args[1]

    try:
        gridftp_connection = Telnet(gridftp_server_name, gridftp_server_port, options.timeout)
        output = gridftp_connection.read_until('ready.', options.timeout)
        for txt in ['220', 'GridFTP Server', 'ready']:
            if txt not in output:
                raise Exception()
        gridftp_connection.close()

        print 'PYGLIDEIN_RESOURCE_GRIDFTP=True'
        print '- update:true'
    except:
        print 'PYGLIDEIN_RESOURCE_GRIDFTP=False'
        print '- update:true'


if __name__ == '__main__':
    main()
