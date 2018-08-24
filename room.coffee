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
        @wss = args.wss
        @word = 0
        @questionText = @question.text.question.split ' '
        @interval = null
        @personCurrentlyBuzzing = null
        @questionFinished = false
        return
        
    next: () ->
        @refreshQuestion()
        self = this
        @interval = global.setInterval () ->
            self.wss.broadcast JSON.stringify {
                room: self.name,
                type: 'word',
                value: self.questionText[self.word]
            }
            self.word++
            if self.word == self.questionText.length
                self.wss.broadcast JSON.stringify {
                    room: self.name,
                    type: 'endedQuestion',
                    timeout: self.timeout
                }
                global.clearInterval self.interval
                global.setTimeout () ->
                    self.finishQuestion()
                , self.timeout
            # read word and increment
            # don't forget finishing and whatnot
            return
        , @readSpeed
        return  
        
    refreshQuestion: () ->
        @question = new Question();
        @questionText = @question.text.question.split ' '
        console.log 'refreshing'
        console.log @question
        console.log @questionText
        @word = 0
        return
        
    finishQuestion: () ->
        @wss.broadcast {
            room: @name,
            type: 'finishQuestion',
            answer: @question.text.answer
        }
        @questionFinished = true
        return
        
    handle: (msg, ws) ->
        if ws.person != msg.person
            ws.close()
            return
        if msg.type == 'next'
            @next()
        else if msg.type == 'openbuzz'
            if @personCurrentlyBuzzing?
                msg.approved = false
            else
                @personCurrentlyBuzzing = Person.getPerson msg.person
                msg.approved = true
            #
        else if msg.type == 'buzz'
            if Person.getPerson msg.person != @personCurrentlyBuzzing
                return
            else
                # only finish if right, but rn everything is right!
                toFinish = true
            @personCurrentlyBuzzing = null
        @wss.broadcast JSON.stringify msg
        @finishQuestion if toFinish
        return
        
exports.Room = Room
