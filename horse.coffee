@Horse = do ->
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
        duration: -1
        delay: 0
        autostart: true

      @options = merge {}, defaults, options

      @isLiving = false
      @age = 0

      @start() if @options.autostart

    start: ->
      @isLiving = true

    stop: ->
      @isLiving = false

    needsCanceled: ->
      @age > @options.duration > -1

    step: (dt, frameTime, frameIndex) ->
      if @options.delay > 0
        @options.delay -= dt
        return

      @age += dt
      @options.work dt, frameTime, frameIndex

  class JobRunner
    @instance: null

    jobs: {}

    isRunning: false
    animationEnabled: true
    frames: 0
    then: 0
    now: 0
    lastJobIndex: null

    constructor: (fps = 60) ->
      if JobRunner.instance
        return JobRunner.instance

      JobRunner.instance = @

      @setFPS fps

      window.requestAnimFrame =
        window.requestAnimationFrame       ||
        window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame    ||
        (callback) => window.setTimeout(callback, @fpsInterval)

    setFPS: (fps) ->
      @fps = fps
      @fpsInterval = 1000 / @fps
      @fps

    start: ->
      return unless @animationEnabled

      @then = window.performance.now()
      @isRunning = true
      @step 0

    stop: ->
      @isRunning = false

    step: (frameTime) =>
      return unless @isRunning
      return unless @animationEnabled

      requestAnimFrame @step

      dt = (frameTime - @now) / 1000
      @now = frameTime
      elapsed = @now - @then

      if elapsed > @fpsInterval
        @then = @now - (elapsed % @fpsInterval)

        @processJobs dt, frameTime, ++@frames

    processJobs: (dt, frameTime, frameIndex) ->
      for id, job of @jobs
        if job.needsCanceled()
          @cancelJob job
          continue

        job.step dt, frameTime, frameIndex if job.isLiving

    addJob: (job) ->
      unless job instanceof Job
        job = new Job arguments...

      job.id = ++@lastJobIndex
      @jobs[job.id] = job
      job

    cancelJob: (id) ->
      job = @findJob(id)
      if job
        delete @jobs[id]
        job.stop()

    cancelAllJobs: ->
      for id, job of @jobs
        if job
          delete @jobs[id]
          job.stop()

    findJob: (id) ->
      if id instanceof Job
        return id

      @jobs[id]

  return JobRunner
