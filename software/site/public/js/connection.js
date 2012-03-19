/**
 * Created by JetBrains PhpStorm.
 * User: seanmcgary
 * Date: 3/18/12
 * Time: 8:54 PM
 * To change this template use File | Settings | File Templates.
 */
var connection = function(){
    var self = this;
    self.current_state = null;
};

connection.prototype._init = function(userkey){
    var self = this;

    self.userkey = userkey;

};

connection.prototype.handle_post_pop = function(response, data, cb){
    var self = this,
        door = $('#' + data.id);

    if(response.success == true){
        door.attr('class', 'door');
        door.addClass('open');

        setTimeout(function(){
            door.attr('class', 'door');
            door.addClass('closed');
            update_states(self.current_state);
        }, 2000);
    } else {
        update_states(self.current_state);

        door.find('.door-message').html(response.error);

        setTimeout(function(){
            door.find('.door-message').html('');
        }, 2000);
    }

    if(typeof cb != 'undefined'){
        cb();
    }
};

connection.prototype.handle_post_lock = function(response, data, cb){
    var self = this,
        door = $('#' + data.id);

    if(response.error != null){
       door.find('.door-message').html(response.error);

       setTimeout(function(){
           door.find('.door-message').html('');
       }, 2000);
    }

    if(typeof cb != 'undefined'){
        cb();
    }
};

connection.prototype.handle_post_unlock = function(response, data, cb){
    var self = this,
        door = $('#' + data.id);

    if(response.error != null){
        door.find('.door-message').html(response.error);

        setTimeout(function(){
            door.find('.door-message').html('');
        }, 2000);
    }
};
