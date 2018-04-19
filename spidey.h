#ifndef SPIDEY_H
#define SPIDEY_H

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include <netdb.h>
#include <unistd.h>

/* Constants */

#define WHITESPACE	" \t\n"

/**
 * Concurrency modes
 */
typedef enum {
    SINGLE,                             /**< Single connection */
    FORKING,                            /**< Process per connection */
    UNKNOWN
} ServerMode;

/* Global Variables */

extern char *Port;                      /**< Port number */
extern char *MimeTypesPath;             /**< Path to mime.types file */
extern char *DefaultMimeType;           /**< Default file mimetype */
extern char *RootPath;                  /**< Path to root directory */

/* Logging Macros */

#ifdef NDEBUG
#define debug(M, ...)
#else
#define debug(M, ...)   fprintf(stderr, "[%5d] DEBUG %10s:%-4d " M "\n", getpid(), __FILE__, __LINE__, ##__VA_ARGS__)
#endif

#define fatal(M, ...)   fprintf(stderr, "[%5d] FATAL %10s:%-4d " M "\n", getpid(), __FILE__, __LINE__, ##__VA_ARGS__); exit(EXIT_FAILURE)
#define log(M, ...)     fprintf(stderr, "[%5d] LOG   %10s:%-4d " M "\n", getpid(), __FILE__, __LINE__, ##__VA_ARGS__)

/* HTTP Request */

typedef struct header Header;
struct header {
    char    *name;                      /*< Name of header entry */
    char    *value;                     /*< Value of header entry */
    Header  *next;                      /*< Next header entry */
};

typedef struct {
    int     fd;                         /*< Client socket file descripter */
    FILE    *file;                      /*< Client socket file stream */
    char    *method;                    /*< HTTP method */
    char    *uri;                       /*< HTTP uniform resource identifier */
    char    *path;                      /*< Real path corrsponding to URI and RootPath */
    char    *query;                     /*< HTTP query string */

    char host[NI_MAXHOST];              /*< Host name of client */
    char port[NI_MAXSERV];              /*< Port number of client */

    Header  *headers;                   /*< List of name, value Header pairs */
} Request;

Request *       accept_request(int sfd);
void	        free_request(Request *request);
int	        parse_request(Request *request);

/* HTTP Request Handlers */

typedef enum {
    HTTP_STATUS_OK = 0,			/* 200 OK */
    HTTP_STATUS_BAD_REQUEST,		/* 400 Bad Request */
    HTTP_STATUS_NOT_FOUND,		/* 404 Not Found */
    HTTP_STATUS_INTERNAL_SERVER_ERROR,	/* 500 Internal Server Error */
} HTTPStatus;

HTTPStatus      handle_request(Request *request);

/* HTTP Server */

int             single_server(int sfd);
int             forking_server(int sfd);

/* Socket */

int	        socket_listen(const char *port);

/* Utilities */

#define chomp(s)    (s)[strlen(s) - 1] = '\0'
#define streq(a, b) (strcmp((a), (b)) == 0)

char *	        determine_mimetype(const char *path);
char *	        determine_request_path(const char *uri);
const char *    http_status_string(HTTPStatus status);
char *	        skip_nonwhitespace(char *s);
char *	        skip_whitespace(char *s);

#endif

/* vim: set expandtab sts=4 sw=4 ts=8 ft=c: */
