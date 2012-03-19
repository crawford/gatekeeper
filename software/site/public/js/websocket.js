/**
 * Created by JetBrains PhpStorm.
 * User: seanmcgary
 * Date: 3/18/12
 * Time: 8:55 PM
 * To change this template use File | Settings | File Templates.
 */
/**
 *  WebSocket connection interface
 */
websocket.prototype = new connection();
function websocket(userkey){
    var self = this;

    self._init.apply(self, [userkey]);

    self.socket_addr = "wss://gatekeeper.csh.rit.edu:8080";
    self.socket = null;
    self.sent_actions = {};

    self.connection_error = false;

    if (typeof WebSocket !== 'undefined') {
        self.socket = new WebSocket(self.socket_addr);

    } else if (typeof MozWebSocket !== 'undefined') {
        self.socket = new MozWebSocket(self.socket_addr);

    } else {
        // no websocket, return true for an error to fallback to REST
        self.connection_error = true;
        return;
    }

    self.socket.onerror = function(){

    };

   self.socket.onclose = function(){

   };

   self.socket.onopen = function(data){
       self.socket.send("AUTH:" + self.userkey);
   };

   self.socket.onmessage = function(data){
       data = JSON.parse(data.data);
        //console.log(data);
       if('states' in data){
           self.current_state = data.states;
           update_states(self.current_state);
       }

       if(data.id in self.sent_actions){
           self.sent_actions[data.id].action(data);
       }

   };
}

websocket.prototype.pop = function(element){
   var self = this,
       id = (new Date()).getTime();

   var callback = function(response){
       self.handle_post_pop(response, self.sent_actions[response.id]);
   }


   self.sent_actions[id] = {id: element.attr('door_id'), action: callback};

   self.socket.send("POP:" + element.attr('door_id') + ':' + id);
};

websocket.prototype.lock = function(){
   var self = this,
       id = (new Date()).getTime();

   var callback = function(response){
       self.handle_post_lock(response, self.sent_actions[response.id], function(){
           update_states(self.current_state);
       });
   }

   self.sent_actions[id] = {id: element.attr('door_id'), action: callback};

   self.socket.send("LOCK:" + element.attr('door_id') + ':' + id);
};

websocket.prototype.unlock = function(){
   var self = this,
       id = (new Date()).getTime();

    var callback = function(response){
        self.handle_post_unlock(response, self.sent_actions[response.id], function(){
            update_states(self.current_state);
        });

    }

   self.sent_actions[id] = {id: element.attr('door_id'), action: callback};

   self.socket.send("UNLOCK:" + element.attr('door_id') + ':' + id);
};