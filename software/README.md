Software
========

The Gatekeeper service is broken up into several main chunks. The API server
handles all requests to the service from third party clients. The LDAP helper
interacts with CSH's LDAP. The DB helper interacts with a Gatekeeper's
database. And, the Hardware Helper communicates with the actual hardware.

Third party clients (i.e. websites, mobile apps, etc.) send all requests by
connecting to the API Server and sending API commands. The API Server uses the
LDAP Helper and DB Helper to authenticate the user and determine if they are
allowed to preform the requested action.


API Server
----------


LDAP Helper
-----------


DB Helper
---------


Hardware Helper
---------------

Provides functionality for communicating with the actual door-locking
hardware. This functionality consists of performing the following actions on
the door:
* locking
* unlocking
* popping
* showing an error code
* querying the state
* adding users to the local access list
* removing users from the local access list
* setting the door ID
