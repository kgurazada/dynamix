{Question} = require './question'

class Room
    createRoom: (args) ->
        return
        
    constructor: (args) ->
        # get or create from mongodb (one method, returns either the new or old)
        # ttl = 1 week
        @name = args.name
        @question = args.question || new Question()
        @readSpeed = args.readSpeed || 200
        @timeout = args.timeout || 6000
        @people = args.people || {}
        @wss = args.srv
        @word = 0
        @questionText = @question.text.split ' '
        @interval = null
        return
        
    refreshQuestion: () ->
        @question = new Question();
        @word = 0;        

    handle: (msg, ws) ->
        console.log msg
        if msg.type == 'next'
            console.log 'next'
            @refreshQuestion()
            self = this
            @interval = global.setInterval () ->
                self.wss.broadcast JSON.stringify {
                    room: self.name,
                    type: 'word',
                    text: self.questionText[self.word]
                }
                self.word++
                if self.word == @questionText.length
                    self.wss.broadcast JSON.stringify {
                        room: self.name,
                        type: 'eof',
                        timeout: self.timeout
                    }
                    global.clearInterval @interval
                # read word and increment
                # don't forget finishing and whatnot
                return
            , @readSpeed
        else
            @wss.broadcast JSON.stringify msg
        return
        
exports.Room = Room
