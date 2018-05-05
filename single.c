/* single.c: Single User HTTP Server */

#include "spidey.h"

#include <errno.h>
#include <string.h>

#include <unistd.h>

/**
 * Handle one HTTP request at a time.
 *
 * @param   sfd         Server socket file descriptor.
 * @return  Exit status of server (EXIT_SUCCESS).
 **/
int single_server(int sfd) {
  /* Accept and handle HTTP request */
  while (true) {
    Request * r;
    /* Accept request */
    r = accept_request(sfd);
    /* Handle request */
    if(handle_request(r) != HTTP_STATUS_OK){
      log("Unable to handle request.");
    }
    /* Free request */
    free_request(r);
  }
  
    /* Close server socket */
  close(sfd);
  return EXIT_SUCCESS;
}

/* vim: set expandtab sts=4 sw=4 ts=8 ft=c: */
