{Room} = require './room'
console.log 'requiring stuff and whatnot'

class RootHandler
    construtor: () ->
        main = require './main'
        console.log 'imports ' + main.wss? + ' ' + main.rooms? + ' ' + main.guest?
        @guest = main.guest
        @rooms = main.rooms
        @wss = main.wss
        return
    
    handle: (msg, ws) ->
        if msg.type == 'entry'
            ws.person = @guest # fix this eventually, thanks
            ws.room = msg.room
            @rooms[msg.room] = new Room() if !@rooms[msg.room]?
            @rooms[msg.room].people[msg.person] = 0
            @wss.broadcast JSON.stringify {
                timestamp: msg.timestamp,
                room: msg.room,
                person: msg.person,
                type: 'entry'
            }
        return

exports.RootHandler = RootHandler