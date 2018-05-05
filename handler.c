/* handler.c: HTTP Request Handlers */

#include "spidey.h"

#include <errno.h>
#include <limits.h>
#include <string.h>

#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <libgen.h> // used for basename in browse_request

/* Internal Declarations */
HTTPStatus handle_browse_request(Request *request);
HTTPStatus handle_file_request(Request *request);
HTTPStatus handle_cgi_request(Request *request);
HTTPStatus handle_error(Request *request, HTTPStatus status);

/**
 * Handle HTTP Request.
 *
 * @param   r           HTTP Request structure
 * @return  Status of the HTTP request.
 *
 * This parses a request, determines the request path, determines the request
 * type, and then dispatches to the appropriate handler type.
 *
 * On error, handle_error should be used with an appropriate HTTP status code.
 **/
HTTPStatus  handle_request(Request *r) {
  HTTPStatus result;
  
  /* Parse request */
  if(parse_request(r) < 0){
    log("Could not parse request.");
    return handle_error(r, HTTP_STATUS_BAD_REQUEST);
  }
  
  /* Determine request path */
  r->path = determine_request_path(r->uri);
  if(r->path == NULL){
    log("Could not determine request path.");
    return handle_error(r, HTTP_STATUS_NOT_FOUND);
  }
  debug("HTTP REQUEST PATH: %s", r->path);
  
  /* Dispatch to appropriate request handler type based on file type */
  struct stat fileStat;
  lstat(r->path, &fileStat);
  if (S_ISDIR(fileStat.st_mode)){
    result = handle_browse_request(r);
  }
  else if (S_ISREG(fileStat.st_mode)){
    if (access(r->path, X_OK) == 0){
      result = handle_cgi_request(r);
    }
    else if (access(r->path, R_OK) == 0){
      result = handle_file_request(r); }
  }
  else {
    result = HTTP_STATUS_BAD_REQUEST;
  }
  
  if(result != HTTP_STATUS_OK){
    result = handle_error(r, result);
  }
  
  log("HTTP REQUEST STATUS: %s", http_status_string(result));
  return result;
}

/**
 * Handle browse request.
 *
 * @param   r           HTTP Request structure.
 * @return  Status of the HTTP browse request.
 *
 * This lists the contents of a directory in HTML.
 *
 * If the path cannot be opened or scanned as a directory, then handle error
 * with HTTP_STATUS_NOT_FOUND.
 **/
HTTPStatus  handle_browse_request(Request *r) {
  struct dirent **entries;
  int n;
  
  /* Open a directory for reading or scanning */
  n = scandir(r->path, &entries, NULL, alphasort);
  
  if(n == -1){
    log("Unable to scandir on directory.");
    return HTTP_STATUS_NOT_FOUND;
  }
  
  /* Write HTTP Header with OK Status and text/html Content-Type */
  fprintf(r->file, "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n");
  
  /* For each entry in directory, emit HTML list item */
  fprintf(r->file, "<ul>");
  for(int i = 0; i < n; i++){
    if(strcmp(entries[i]->d_name,".") == 0){
      free(entries[i]);
      continue;
    }
    if(strcmp(r->uri,"/")==0){
      fprintf(r->file,"<li><a href=\"/%s\">%s</a></li>\r\n", entries[i]->d_name, entries[i]->d_name);
    }
    else{
      fprintf(r->file, "<li<a href=\"/%s/%s\">%s</a></li>\r\n",basename(r->path),entries[i]->d_name,entries[i]->d_name);
    }
    free(entries[i]);
  }
  fprintf(r->file, "<ul>");
  
  /* Flush socket, return OK */
  fflush(r->file);
  free(entries);
  return HTTP_STATUS_OK; 
}

/**
 * Handle file request.
 *
 * @param   r           HTTP Request structure.
 * @return  Status of the HTTP file request.
 *
 * This opens and streams the contents of the specified file to the socket.
 *
 * If the path cannot be opened for reading, then handle error with
 * HTTP_STATUS_NOT_FOUND.
 **/
HTTPStatus  handle_file_request(Request *r) {
  FILE *fs;
  char buffer[BUFSIZ];
  char *mimetype = NULL;
  size_t nread;
  
  /* Open file for reading */
  if((fs = fopen(r->path, "r")) == NULL){
    log("Could not open file for reading.");
    goto fail;
  }
  
  /* Determine mimetype */
  mimetype = determine_mimetype(r->path);
  
  /* Write HTTP Headers with OK status and determined Content-Type */
  if(fprintf(r->file, "HTTP/1.0 200 OK\r\nContent-Type: %s\r\n\r\n", mimetype) < 0){
    log("Cannot print to socket.");
    goto fail;
  }
  
  /* Read from file and write to socket in chunks */
  while((nread = fread(buffer, 1, BUFSIZ, fs)) > 0){ // 1 element of size BUFSIZ
    if(fwrite(buffer, 1, nread, r->file) != nread){ // write to file, 1 element of size nread
      log("Could not write to file");
      goto fail;
    }
  }
  
  /* Close file, flush socket, deallocate mimetype, return OK */
  fclose(fs);
  fflush(r->file);
  free(mimetype);
  return HTTP_STATUS_OK;
  
fail:
  /* Close file, free mimetype, return INTERNAL_SERVER_ERROR */
  fclose(fs);
  free(mimetype);
  return HTTP_STATUS_INTERNAL_SERVER_ERROR;
}

/**
 * Handle CGI request
 *
 * @param   r           HTTP Request structure.
 * @return  Status of the HTTP file request.
 *
 * This popens and streams the results of the specified executables to the
 * socket.
 *
 * If the path cannot be popened, then handle error with
 * HTTP_STATUS_INTERNAL_SERVER_ERROR.
 **/
HTTPStatus handle_cgi_request(Request *r) {
  FILE *pfs;
  char buffer[BUFSIZ];
  
  if(r->query != NULL){
    setenv("QUERY_STRING",r->query,1);
  }
  else{
    setenv("QUERY_STRING","",1);
  }
  setenv("DOCUMENT_ROOT",RootPath,1);
  setenv("REQUEST_URI",r->uri,1);
  setenv("REQUEST_METHOD",r->method,1);
  setenv("REMOTE_ADDR",r->host,1);
  setenv("REMOTE_PORT",r->port,1);
  setenv("SCRIPT_FILENAME",r->path,1);
  setenv("SERVER_PORT",r->port,1);
  
  /* Export CGI environment variables from request structure:
   * http://en.wikipedia.org/wiki/Common_Gateway_Interface */
  
  
  
  /* Export CGI environment variables from request headers */
  
  Header* curr = r->headers;
  
  while(curr)
    {
      if(streq(curr->name,"Host"))
	{
	  setenv("HTTP_HOST",curr->value,1);
	}
      else if(streq(curr->name,"User-Agent"))
	{
	  setenv("HTTP_USER_AGENT",curr->value,1);
	  
	}
      else if(streq(curr->name,"Accept"))
	{
	  setenv("HTTP_ACCEPT",curr->value,1);
	  
	}
      else if(streq(curr->name,"Accept-Language"))
	{
	  setenv("HTTP_ACCEPT_LANGUAGE",curr->value,1);
	}
      else if(streq(curr->name,"Accept-Encoding"))
	{
	  setenv("HTTP_ACCEPT_ENCODING",curr->value,1);
	}
      else if(streq(curr->name,"Connection"))
	{
	  setenv("HTTP_CONNECTION",curr->value,1);
	}
      
      curr=curr->next;
    }
  
  




    /* POpen CGI Script */

    if((pfs=popen(r->path,"r"))==NULL)
      {
  log("unable to popen");
  return HTTP_STATUS_INTERNAL_SERVER_ERROR;
      }

    /* Copy data from popen to socket */

    while(fgets(buffer,BUFSIZ,pfs) !=NULL)
      {
        if(fputs(buffer,r->file) < 0){
          log("Fail to fputs.");
          return HTTP_STATUS_INTERNAL_SERVER_ERROR;
        }

      }

    /* Close popen, flush socket, return OK */
    pclose(pfs);
    fflush(r->file);

    return HTTP_STATUS_OK;
}

/**
 * Handle displaying error page
 *
 * @param   r           HTTP Request structure.
 * @return  Status of the HTTP error request.
 *
 * This writes an HTTP status error code and then generates an HTML message to
 * notify the user of the error.
 **/
HTTPStatus  handle_error(Request *r, HTTPStatus status) {
    const char *status_string = http_status_string(status);

    /* Write HTTP Header */
    fprintf(r->file, "HTTP/1.0 %s\r\nContent-Type: text/html\r\n\r\n",status_string);

    /* Write HTML Description of Error*/
    fprintf(r->file,"<h1>");
    fprintf(r->file,"Mr. Bui, I don't feel so good...");
    fprintf(r->file,"</h1>");
    fprintf(r->file,"<h2>");
    fprintf(r->file,"Something went wrong:");
    fprintf(r->file,"</h2>");
    fprintf(r->file,"<p>");
    fprintf(r->file,"%s\n",status_string);
    fprintf(r->file,"</p>");
    /* Return specified status */
    return status;
}

/* vim: set expandtab sts=4 sw=4 ts=8 ft=c: */
