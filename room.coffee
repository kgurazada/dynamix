{Question} = require './question'
{Person} = require './person'

class Room

    createRoom: (args) ->
        return
        
    constructor: (args) ->
        # get or create from mongodb (one method, returns either the new or old)
        # ttl = 1 week
        @name = args.name
        @question = args.question || new Question()
        @readSpeed = args.readSpeed || 120
        @timeout = args.timeout || 6000
        @people = args.people || {}
        @wss = args.wss
        @word = 0
        @questions = null
        @question = null
        @questionText = null
        @interval = null
        @personCurrentlyBuzzing = null
        @questionFinished = false
        @pause = false
        return
        
    next: () ->
        @finishQuestion()
        @word = 0
        qIndex = @questions.indexOf @question
        qIndex++
        qIndex = qIndex % @questions.length
        @question = @questions[qIndex]
        @questionText = @question.text.question.split ' '
        @wss.broadcast JSON.stringify {
            room: @name,
            type: 'next',
            meta: {tournament: @question.tournament, difficulty: @question.difficulty, category: @question.category, subcategory: @question.subcategory}
        }
        @personCurrentlyBuzzing = null
        @questionFinished = false
        self = this
        @interval = global.setInterval () ->
            if self.pause || self.questionFinished
                return
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
        
    finishQuestion: () ->
        @pause = false
        global.clearInterval @interval
        @questionFinished = true
        if !@question
            return
        @wss.broadcast JSON.stringify {
            room: @name,
            type: 'finishQuestion',
            question: @question
        }
        return
        
    handle: (msg, ws) ->
       try
            toFinish = false
            if ws.person != Person.getPerson msg.person
                ws.close()
                return
            if msg.type == 'next'
                @readSpeed = msg.readSpeed
                msg = {}
                @next()
            else if msg.type == 'pauseOrPlay'
                @pause = !@pause
            else if msg.type == 'search'
                Question.getQuestions msg.searchParameters, this
            else if msg.type == 'openbuzz'
                if @personCurrentlyBuzzing || @questionFinished
                    msg.approved = false
                else
                    @personCurrentlyBuzzing = msg.person
                    console.log 'openbuzz by ' + @personCurrentlyBuzzing
                    msg.approved = true
                    @pause = true
                    self = this
                    setTimeout () ->
                        console.log 'executing timeout'
                        if self.personCurrentlyBuzzing
                            msg.verdict = 3
                            self.wss.broadcast JSON.stringify {room: self.name, person: self.personCurrentlyBuzzing, type: 'buzz', value: '', verdict: 3}
                            console.log 'timed out ' + self.personCurrentlyBuzzing + ' because he took ' + self.timeout + 'ms. smh'
                            self.personCurrentlyBuzzing = null
                            self.pause = false
                        return
                    , @timeout
                    console.log 'set timeout in case they take too long -_- ' + @timeout
                #
            else if msg.type == 'buzz'
                @pause = false
                if !@personCurrentlyBuzzing
                    return
                if @personCurrentlyBuzzing.name != msg.person # fix this
                    return
                toFinish = true
                msg.verdict = Question.match @question, msg.value
                @personCurrentlyBuzzing = null 
            @wss.broadcast JSON.stringify msg
            @finishQuestion() if toFinish
        catch e
            console.log e.stack
            @wss.broadcast 'temporary error'
        return
        
exports.Room = Room
