Project - README
================

Members
-------

- Nicholas Marcopoli (nmarcopo@nd.edu)
- Austin Sura        (asura@nd.edu)
- Sung Hyun Shin     (ssin1@nd.edu)

Demonstration
-------------

https://docs.google.com/presentation/d/1uxEwSPMoKRkB-4QWyqDZbSC5ZflS22lFqh5QLrLZA94/edit?usp=sharing

Errata
------

Summary of things that don't work (quite right).

We are aware that we fail one test to correctly mime-type .html. We fail to this because we think some default mime-type is being incorrectly put in, but we could not locate the source of this problem. We also have a problem in forking with valgrind leaks, but the forking valgrind test does pass all of the test_spidey.sh tests. When using forking, we also found that the server does not auto close itself once the tests are over, and we think that stems from either a while(true) loop or from previous valgrind erros.

Contributions
-------------

Enumeration of the contributions of each group member.

We all met together to work on the project in the same space and time. We had different emphasis on different functions, but we were all aware of what the files and functions do and how we were going to accomplish it. We were all collaborating and helping each other. 
Sung Hyun Shin focused on socket.c, single.c, accept_request, parse_request_headers,handle_request,handle_browse_request,handle_error,single.c, and functions in utils.c. Austin worked on thor.py, parse_request_method, parse_request_headers, handle_browse_request,handle_cgi_request,forking.c,spidey.c, and functions in utils.c. Nicholas worked on thor.py, accept_request, parse_request_method, parse_request_headers, handle_request, handle_browse_request,handle_browse_request,handle_error,forking.c,spidey.c,and functions in utils.c.
For debugging we all worked together and collaboratively to fix problems together.
