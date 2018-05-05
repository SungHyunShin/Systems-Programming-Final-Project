/* forking.c: Forking HTTP Server */

#include "spidey.h"

#include <errno.h>
#include <signal.h>
#include <string.h>

#include <unistd.h>

/**
 * Fork incoming HTTP requests to handle the concurrently.
 *
 * @param   sfd         Server socket file descriptor.
 * @return  Exit status of server (EXIT_SUCCESS).
 *
 * The parent should accept a request and then fork off and let the child
 * handle the request.
 **/
int forking_server(int sfd) {
  /* Accept and handle HTTP request */
  while (true) {
    /* Accept request */
    debug("Accepting client request.");
    Request *r = accept_request(sfd);
    if(!r){
      continue;
    }
    
    /* Ignore children */
    signal(SIGINT, SIG_IGN);
    
    /* Fork off child process to handle request */
    pid_t rc = fork();
    if(rc == 0){
      // child
      close(sfd);
      exit(handle_request(r) != 0);
    }else if(rc > 0){
      // parent
      free_request(r);
      continue;
    }else if(rc < 0){
      // error
      free_request(r);
      continue;
    }
  }
  
  /* Close server socket */
  close(sfd);
  return EXIT_SUCCESS;
}

/* vim: set expandtab sts=4 sw=4 ts=8 ft=c: */
