/**
 * Created by JetBrains PhpStorm.
 * User: seanmcgary
 * Date: 3/18/12
 * Time: 8:58 PM
 * To change this template use File | Settings | File Templates.
 */
var conn;
$(document).ready(function(){

    conn = new websocket(userkey);
    //console.log(conn);

    if(conn.connection_error == true){
        //console.log('false');
        conn = new rest(userkey);
    }

    function handle_action_button(elem){

        switch(elem.attr('door_action')){
            case 'pop':
                conn.pop(elem);
                break;

            case 'unlock':
                conn.unlock(elem);
                break;

            case 'lock':
                conn.lock(elem);
                break;
        }

        var buttons = $('#' + elem.attr('door_id') + ' .action-button');
        $('#' + elem.attr('door_id') + ' .action-button').attr('disabled', true);
    }

    $('.action-button').live('click', function(event){
        handle_action_button($(this));
    });


});