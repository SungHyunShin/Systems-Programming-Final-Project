#!/usr/bin/env python3

import multiprocessing
import os
import requests
import sys
import time

# Globals

PROCESSES = 1
REQUESTS  = 1
VERBOSE   = False
URL       = None

# Functions

def usage(status):
    print('''Usage: {} [-p PROCESSES -r REQUESTS -v] URL
    -h              Display help message
    -v              Display verbose output

    -p  PROCESSES   Number of processes to utilize (1)
    -r  REQUESTS    Number of requests per process (1)
    '''.format(os.path.basename(sys.argv[0])))
    sys.exit(status)

def do_request(pid):
    ''' Perform REQUESTS HTTP requests and return the average elapsed time. '''
    TOTALTIME = 0.0
    for i in range(int(REQUESTS)):
        try:
            before = time.time()
            response = requests.get(URL)
            after = time.time()
            data = response.text
            if VERBOSE:
                print(data)
            requestTime = after - before
            TOTALTIME += requestTime
            print("Process: {}, Request: {}, Elapsed Time: {:.2f}".format(pid, i, requestTime))
        except:
            print("Error in request")
        
    print("Process: {}, AVERAGE   , Elapsed Time: {:.2f}".format(pid, TOTALTIME / float(REQUESTS)))
    return TOTALTIME / float(REQUESTS)

# Main execution

if __name__ == '__main__':
    # Parse command line arguments
    ARGUMENTS = sys.argv[1:]
    if not ARGUMENTS:
        usage(1)
        
    while len(ARGUMENTS) and len(ARGUMENTS[0]) > 1:
        ARG = ARGUMENTS.pop(0)
        if ARG == '-h':
            usage(0)
        elif ARG == '-v':
            VERBOSE = True
        elif ARG == '-p':
            PROCESSES = int(ARGUMENTS.pop(0))
        elif ARG == '-r':
            REQUESTS = ARGUMENTS.pop(0)
        elif ARG.startswith('-'):
            usage(1) # bad arguments
        else:
            URL = ARG

    # Create pool of workers and perform requests
    pool = multiprocessing.Pool(PROCESSES)
    timeIterable = pool.map(do_request, range(PROCESSES))

    print("TOTAL AVERAGE ELAPSED TIME: {:.6f}".format(sum(timeIterable) / PROCESSES))

# vim: set sts=4 sw=4 ts=8 expandtab ft=python:
