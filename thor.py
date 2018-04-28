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
ARGUMENTS = sys.argv[1:]

# Functions

def usage(status=0):
    print('''Usage: {} [-p PROCESSES -r REQUESTS -v] URL
    -h              Display help message
    -v              Display verbose output

    -p  PROCESSES   Number of processes to utilize (1)
    -r  REQUESTS    Number of requests per process (1)
    '''.format(os.path.basename(sys.argv[0])))
    sys.exit(status)

def do_request(pid):
    ''' Perform REQUESTS HTTP requests and return the average elapsed time. '''
    
    return 0

# Main execution

if __name__ == '__main__':
    # Parse command line arguments
    if not ARGUMENTS:
        usage(0)
        
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
        else:
            URL = ARG

    # Create pool of workers and perform requests
    pool = multiprocessing.Pool(PROCESSES)

# vim: set sts=4 sw=4 ts=8 expandtab ft=python: