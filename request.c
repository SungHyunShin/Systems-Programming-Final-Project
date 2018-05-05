/* request.c: HTTP Request Functions */

#include "spidey.h"

#include <errno.h>
#include <string.h>

#include <unistd.h>

int parse_request_method(Request *r);
int parse_request_headers(Request *r);

/**
 * Accept request from server socket.
 *
 * @param   sfd         Server socket file descriptor.
 * @return  Newly allocated Request structure.
 *
 * This function does the following:
 *
 *  1. Allocates a request struct initialized to 0.
 *  2. Initializes the headers list in the request struct.
 *  3. Accepts a client connection from the server socket.
 *  4. Looks up the client information and stores it in the request struct.
 *  5. Opens the client socket stream for the request struct.
 *  6. Returns the request struct.
 *
 * The returned request struct must be deallocated using free_request.
 **/
Request * accept_request(int sfd) {
  Request *r;
  struct sockaddr raddr;
  socklen_t rlen;
  
  /* Allocate request struct (zeroed) */
  rlen = sizeof(struct sockaddr);
  r = calloc(1, sizeof(Request));
  r->headers = NULL;
  
  /* Accept a client */
  int cfd = accept(sfd, &raddr, &rlen);
  if(cfd < 0){
    log("Accepting client connection failed.");
    goto fail;
  }
  
  /* Lookup client information */
  if(getnameinfo(&raddr, sizeof(raddr), r->host, sizeof(r->host), r->port, sizeof(r->port), 0) != 0){
    log("Could not look up client information.");
    goto fail;
  }
  
  /* Open socket stream */
  r->file = fdopen(cfd, "w+");
  if(!r->file){
    log("Could not open socket stream.");
    goto fail;
  }
  
  log("Accepted request from %s:%s", r->host, r->port);
  return r;
  
 fail:
    /* Deallocate request struct */
  free(r);
  return NULL;
}

/**
 * Deallocate request struct.
 *
 * @param   r           Request structure.
 *
 * This function does the following:
 *
 *  1. Closes the request socket stream or file descriptor.
 *  2. Frees all allocated strings in request struct.
 *  3. Frees all of the headers (including any allocated fields).
 *  4. Frees request struct.
 **/
void free_request(Request *r) {
  if (!r) {
    // requests is null
    return;
  }
  
  /* Close socket or fd */
  fclose(r->file);
  close(r->fd);
  
  /* Free allocated strings */
  free(r->method);
  free(r->uri);
  free(r->path);
  free(r->query);
  
  /* Free headers */
  if(r->headers){
    free(r->headers->next);
    free(r->headers);
  }
  
  /* Free request */
  free(r);
  
}

/**
 * Parse HTTP Request.
 *
 * @param   r           Request structure.
 * @return  -1 on error and 0 on success.
 *
 * This function first parses the request method, any query, and then the
 * headers, returning 0 on success, and -1 on error.
 **/
int parse_request(Request *r) {
  /* Parse HTTP Request Method */
  if(parse_request_method(r) < 0){
    log( "Could not parse request headers method.");
    return -1;
  }
  
  /* Parse HTTP Requet Headers*/
  if(parse_request_headers(r) < 0){
    log("Could not parse HTTP Request Headers.");
    return -1;
  }

  return 0;
}

/**
 * Parse HTTP Request Method and URI.
 *
 * @param   r           Request structure.
 * @return  -1 on error and 0 on success.
 *
 * HTTP Requests come in the form
 *
 *  <METHOD> <URI>[QUERY] HTTP/<VERSION>
 *
 * Examples:
 *
 *  GET / HTTP/1.1
 *  GET /cgi.script?q=foo HTTP/1.0
 *
 * This function extracts the method, uri, and query (if it exists).
 **/
int parse_request_method(Request *r) {
  char buffer[BUFSIZ];
  char *method;
  char *uri;
  char *query;
  const char* delim = " \t\n";
  /* Read line from socket */
  if(fgets(buffer,BUFSIZ,r->file) == NULL){
    log("Could not read from socket.");
    goto fail;
  }
  
  /* Parse method and uri */
  skip_whitespace(buffer);
  
  if((method = strtok(buffer, delim)) == NULL){
    log("Could not parse method.");
    goto fail;
  }
  if((uri = strtok(NULL, delim)) == NULL){
    log("Could not parse uri.");
    goto fail;
  }
  
  /* Parse query from uri */
  char *temp  = strchr(uri, '?');
  if (temp != NULL){
    temp++;
    int difference = strlen(uri) - strlen(temp);
    *(uri + difference - 1) = '\0';
  }
  query = temp;
  
  /* Record method, uri, and query in request struct */
  r->method = strdup(method);
  r->uri    = strdup(uri);
  if(query != NULL)
    r->query  = strdup(query); // may be an issue because it might not exist.
  
  debug("HTTP METHOD: %s", r->method);
  debug("HTTP URI:    %s", r->uri);
  debug("HTTP QUERY:  %s", r->query);
  
  return 0;
  
fail:
  return -1;
}

/**
 * Parse HTTP Request Headers.
 *
 * @param   r           Request structure.
 * @return  -1 on error and 0 on success.
 *
 * HTTP Headers come in the form:
 *
 *  <NAME>: <VALUE>
 *
 * Example:
 *
 *  Host: localhost:8888
 *  User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0
 *  Accept: text/html,application/xhtml+xml
 *  Accept-Language: en-US,en;q=0.5
 *  Accept-Encoding: gzip, deflate
 *  Connection: keep-alive
 *
 * This function parses the stream from the request socket using the following
 * pseudo-code:
 *
 *  while (buffer = read_from_socket() and buffer is not empty):
 *      name, value = buffer.split(':')
 *      header      = new Header(name, value)
 *      headers.append(header)
 **/
int parse_request_headers(Request *r) {
  struct header *curr = NULL;
  char buffer[BUFSIZ];
  char *name;
  char *value;
  
  /* Parse headers from socket */
  char *temp; // temporary char to split the buffer
  
  /* Parse headers from socket */
  r->headers = curr;
  
  while(fgets(buffer, BUFSIZ, r->file)){
    if((strcmp(buffer, "\n")) == 0 || (strcmp(buffer, "\r\n")) == 0){
      log("Reached end of headers.");
      break;
    }
    chomp(buffer);
    if((temp = strchr(buffer, ':')) == NULL){
      log("Not a valid header format.");
      goto fail;
    }
    // split buffer at the position of the colon
    *temp = '\0';
    name = buffer; // get just the name
    value = skip_whitespace(temp + 1); // goes to space after colon
    
    //value = temp;
    if((curr = calloc(1, sizeof(struct header))) == NULL){
      log("Could not allocate memory for header.");
      goto fail;
    }
    // set headers in the request struct
    curr->name = strdup(name); 
    curr->value = strdup(value);
    
    
    curr->next = r->headers;
    
    // move to the next header
    r->headers = curr;
  }
  
#ifndef NDEBUG
  for (struct header *header = r->headers; header != NULL; header = header->next) {
    debug("HTTP HEADER %s = %s", header->name, header->value);
  }
#endif
  return 0;
  
 fail:
  return -1;
}
/* vim: set expandtab sts=4 sw=4 ts=8 ft=c: */
