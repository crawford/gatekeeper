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

Functions:

* get a list of all doors (id, name, status)
* get status of a single door
* pop a door
* unlock a door
* lock a door
* authenticate user
* add/remove ibutton from access list


Database
---------

* Doors
 * id
 * hardware address - hardware address for the board (IP address, ZID, etc)
 * interface id
 * name
 * state id
 * message address - used for message passing

* Users
 * id
 * username

* Denials
 * id
 * user id
 * door id
 * start date
 * end date

* Interfaces
 * id
 * name (Ethernet, zigbee, etc)

* States
 * id
 * name

* Events
 * id
 * time
 * user id
 * type id
 * action arg - (usually a door id)
 * action id
 * service id

* Type
 * id
 * name (Violation, Access, etc)

* Action
 * id
 * name (Pop, Unlock, etc)

* Service
 * service id
 * name (Socket, HTTP, etc)


Hardware Interface
------------------

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


WebSocket Interface
-------------------

<pre>
+---------+--------------------+-------------------+---------------------------------------+  
| Command | Payload            | Server     Client | Description                           |  
+---------+--------------------+-------------------+---------------------------------------+  
| AUTH    | Username, Password |        <==        | Auth user using username and password |  
| LOCK    | Door ID            |        <==        | Lock a specific door                  |  
| UNLOCK  | Door ID            |        <==        | Unlock a specific door                |  
| POP     | Door ID            |        <==        | Pop a specific door                   |  
| STATES  | All Door States    |        ==>        | Returns a JSON string containing the  |  
|         |                    |                   |  states for all of the doors.         |  
+---------+--------------------+-------------------+---------------------------------------+  
</pre>
