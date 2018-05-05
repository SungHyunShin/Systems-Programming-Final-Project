/* spidey: Simple HTTP Server */

#include "spidey.h"

#include <errno.h>
#include <stdbool.h>
#include <string.h>

#include <unistd.h>

/* Global Variables */
char *Port	      = "9898";
char *MimeTypesPath   = "/etc/mime.types";
char *DefaultMimeType = "text/plain";
char *RootPath	      = "www";

/**
 * Display usage message and exit with specified status code.
 *
 * @param   progname    Program Name
 * @param   status      Exit status.
 */
void usage(const char *progname, int status) {
  fprintf(stderr, "Usage: %s [hcmMpr]\n", progname);
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "    -h            Display help message\n");
  fprintf(stderr, "    -c mode       Single or Forking mode\n");
  fprintf(stderr, "    -m path       Path to mimetypes file\n");
  fprintf(stderr, "    -M mimetype   Default mimetype\n");
  fprintf(stderr, "    -p port       Port to listen on\n");
  fprintf(stderr, "    -r path       Root directory\n");
  exit(status);
}

/**
 * Parse command-line options.
 *
 * @param   argc        Number of arguments.
 * @param   argv        Array of argument strings.
 * @param   mode        Pointer to ServerMode variable.
 * @return  true if parsing was successful, false if there was an error.
 *
 * This should set the mode, MimeTypesPath, DefaultMimeType, Port, and RootPath
 * if specified.
 */
bool parse_options(int argc, char *argv[], ServerMode *mode) {
  int argind = 1;    
  while(argind < argc && strlen(argv[argind]) > 1 && argv[argind][0] == '-'){
    char *arg = argv[argind++];
    switch(arg[1]){
    case 'h':
      usage(argv[0], 0);
      break;
    case 'c':
      if(strcmp(argv[argind], "forking") == 0){
	*mode = FORKING; 
      }else if(strcmp(argv[argind], "single") == 0){
	*mode = SINGLE;
      }else{
	*mode = UNKNOWN;
      }
      argind++;
      break;
    case 'm':
      MimeTypesPath = argv[argind++];
      break;
    case 'M':
      DefaultMimeType = argv[argind++];
      break;
    case 'p':
      Port = argv[argind++];
      break;
    case 'r':
      RootPath = argv[argind++];
      break;
    default:
      return false;
    }
  }
  
  return true;
}

/**
 * Parses command line options and starts appropriate server
 **/
int main(int argc, char *argv[]) {
  ServerMode mode;
  char *PROGRAM_NAME = argv[0];
  
  /* Parse command line options */
  if(!parse_options(argc, argv, &mode)){
    usage(PROGRAM_NAME, 1);
  }
  
  /* Listen to server socket */
  int server_fd = socket_listen(Port);
  
  /* Determine real RootPath */
  RootPath = realpath(RootPath, NULL);
  
  log("Listening on port %s", Port);
  debug("RootPath        = %s", RootPath);
  debug("MimeTypesPath   = %s", MimeTypesPath);
  debug("DefaultMimeType = %s", DefaultMimeType);
  debug("ConcurrencyMode = %s", mode == SINGLE ? "Single" : "Forking");
  
  /* Start either forking or single HTTP server */
  if(mode == SINGLE){
    single_server(server_fd);
  }else if(mode == FORKING){
    forking_server(server_fd);
  }else if(mode == UNKNOWN){
    usage(PROGRAM_NAME, 1);
  }
  free(RootPath);
  return EXIT_SUCCESS;
}

/* vim: set expandtab sts=4 sw=4 ts=8 ft=c: */
