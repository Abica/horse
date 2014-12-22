window.Horse = (->
  merge = (dest, objs...) ->
    for obj in objs
      for k, v of obj
        dest[k] = v
    dest

  isFunction = (obj) ->
    typeof obj is 'function'

  class Job
    constructor: (options = {}) ->
      if isFunction options
        options =
          work: options

      defaults =
        work: ->
        duration: 0
        delay: 0
        autostart: false

      @options = merge {}, defaults, options

      @living = false
      @age = 0

      @start() if @options.autostart

    start: ->
      @living = true

    stop: ->
      @living = false

    needsCanceled: ->
      @age > @options.duration

    step: (dt, frameTime, frameIndex) ->
      if @options.delay > 0
        @options.delay -= dt
        return

      @age += dt
      @options.work dt, frameTime, frameIndex

  class JobRunner
    @instance: null

    isRunning: false
    animationEnabled: true
    frames: 0
    then: 0
    now: 0
    lastJobIndex: null

    jobs: []

    constructor: (fps = 60) ->
      if JobRunner.instance
        return JobRunner.instance

      JobRunner.instance = @

      @fps = fps
      @fpsInterval = 1000 / @fps

      @requestAnimFrame =
        window.requestAnimationFrame       ||
        window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame    ||
        (callback) -> window.setTimeout(callback, @fpsInterval)

    start: ->
      return unless @animationEnabled

      @then = window.performance.now()
      @isRunning = true
      @animate 0

    stop: ->
      @isRunning = false

    animate: (frameTime) ->
      return unless @isRunning
      return unless @animationEnabled

      requestAnimationFrame $.proxy(@animate, @)

      dt = (frameTime - @now) / 1000
      @now = frameTime
      elapsed = @now - @then

      if elapsed > @fpsInterval
        @then = @now - (elapsed % @fpsInterval)

        @processJobs dt, frameTime, ++@frames

    processJobs: (dt, frameTime, frameIndex) ->
      for job, index in @jobs by -1
        if job.needsCanceled()
          @cancelJobAtIndex index
          continue

        job.step dt, frameTime, frameIndex if job.living

    addJob: (job) ->
      unless job instanceof Job
        job = new Job arguments...

      job.id = ++@lastJobIndex
      @jobs.push job
      job

    cancelJob: (id) ->
      index = @jobs.indexOf @findJob(id)
      @cancelJobAtIndex index

    cancelJobAtIndex: (index) ->
      job = @jobs.splice index, 1
      if job
        job.living = false

    findJob: (id) ->
      if id instanceof Job
        return id

      for job in @jobs
        return job if job.id is id

  return JobRunner
)()
