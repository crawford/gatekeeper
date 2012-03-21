/**
 * Created by JetBrains PhpStorm.
 * User: seanmcgary
 * Date: 3/18/12
 * Time: 8:55 PM
 * To change this template use File | Settings | File Templates.
 */
/**
 * REST connection interface
 */
rest.prototype = new connection();
function rest(userkey){
    var self = this;

    self._init.apply(self, [userkey]);

    self.paths = {
        'all_doors': 'https://api.gatekeeper.csh.rit.edu/all_doors',
        'pop': 'https://api.gatekeeper.csh.rit.edu/pop',
        'lock': 'https://api.gatekeeper.csh.rit.edu/lock',
        'unlock': 'https://api.gatekeeper.csh.rit.edu/unlock'
    };

    self.get_states();

};

rest.prototype.pop = function(elem){
    var self = this,
        id = (new Date()).getTime(),
        door_id = $(elem).attr('door_id');


    if(window.XDomainRequest){

        var req = new XDomainRequest();

        if(req){
            req.onload = function(){
                var data = JSON.parse(req.responseText);

                self.handle_post_pop(data, {id: door_id});
            };

            req.open('post', self.paths.pop + '/' + door_id);
            req.send("userkey=" + userkey);

        }

    } else {
        $.ajax({
            url: self.paths.pop + '/' + door_id,
            dataType: 'json',
            type: 'POST',
            success: function(data){
                self.handle_post_pop(data, {id: door_id});
            },
            data: {userkey: userkey}
        });
    }
};

rest.prototype.lock = function(elem){
    var self = this,
            id = (new Date()).getTime(),
            door_id = $(elem).attr('door_id');

    if(window.XDomainRequest){

        var req = new XDomainRequest();

        if(req){
            req.onload = function(){
                var data = JSON.parse(req.responseText);

                self.handle_post_lock(data, {id: door_id}, function(){
                    update_states(self.current_state);
                });
            };

            req.open('post', self.paths.lock + '/' + door_id);
            req.send("userkey=" + userkey);

        }

    } else {
        $.ajax({
            url: self.paths.lock + '/' + door_id,
            dataType: 'json',
            type: 'POST',
            success: function(data){
                self.handle_post_lock(data, {id: door_id}, function(){
                    update_states(self.current_state);
                });
            },
            data: {userkey: userkey}
        });
    }
};

rest.prototype.unlock = function(elem){
    var self = this,
            id = (new Date()).getTime(),
            door_id = $(elem).attr('door_id');

    if(window.XDomainRequest){
        var req = new XDomainRequest();

        if(req){
            req.onload = function(){
                var data = JSON.parse(req.responseText);

                self.handle_post_unlock(data, {id: door_id}, function(){
                    update_states(self.current_state);
                });
            };

            req.open('post', self.paths.unlock + '/' + door_id);
            req.send("userkey=" + userkey);

        }

    } else {

        $.ajax({
            url: self.paths.unlock + '/' + door_id,
            dataType: 'json',
            type: 'POST',
            success: function(data){
                self.handle_post_unlock(data, {id: door_id}, function(){
                    update_states(self.current_state);
                });
            },
            data: {userkey: userkey}
        });
    }
};

rest.prototype.get_states = function(){
    var self = this;

    if(window.XDomainRequest){
        var req = new XDomainRequest();

        if(req){
            req.onload = function(){
                var data = JSON.parse(req.responseText);
                self.current_state = data.response;
                update_states(self.current_state);
            };

            req.open('post', self.paths.all_doors);
            req.send("userkey=" + userkey);

        }

    } else {
        $.ajax({
            url: self.paths.all_doors,
            dataType: 'json',
            type: 'POST',
            success: function(data){
                self.current_state = data.response;
                update_states(self.current_state);
            },
            data: {userkey: userkey}
        });
    }


};