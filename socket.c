/* socket.c: Simple Socket Functions */

#include "spidey.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

/**
 * Allocate socket, bind it, and listen to specified port.
 *
 * @param   port        Port number to bind to and listen on.
 * @return  Allocated server socket file descriptor.
 **/
int socket_listen(const char *port) {
    /* Lookup server address information */
    
    struct addrinfo hints = {
        .ai_family = AF_UNSPEC,
        .ai_socktype = SOCK_STREAM,
        .ai_flags = AI_PASSIVE,
    };
    struct addrinfo *results;
    int status;
    if((status = getaddrinfo(HOST,POST,&hints,&results))!= 0){
        fprintf(stderr, "getaddrinfo failed: %s\n", gai_strerror(status));
        return EXIT_FAILURE;
    }

    /* For each server entry, allocate socket and try to connect */
    int socket_fd = -1;
    for (struct addrinfo *p = results; p != NULL && socket_fd < 0; p = p->ai_next) {
	/* Allocate socket */
        if((socket_fd = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) <0) {
            fprintf(stderr, "Unable to make socket: %s\n", strerror(errno));
            continue;
        }

	/* Bind socket */
        if(bind(socket_fd, p->ai_addr, p->ai_addrlen) < 0){
            fprint(stderr, "Unable to bind: %s\n", strerror(errno));
            close(server_fd);
            return EXIT_FAILURE;
        }
        
    	/* Listen to socket */
        if(listen(socket_fd, SOMAXCONN) < 0) {
            fprintf(stderr, "Unable to listen: %s\n", strerror(errno));
            close(socket_fd);
            return EXIT_FAILURE;
        }
    }

    freeaddrinfo(results);

    return socket_fd;
}

/* vim: set expandtab sts=4 sw=4 ts=8 ft=c: */
