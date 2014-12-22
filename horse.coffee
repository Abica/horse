Horse = (->
  class Job
    constructor: (duration, work, delay = 0, autostart = false) ->
      [@duration, @work, @delay, @autostart] = arguments

      @living = false
      @age = 0
      @work ||= ->

      @run() if @autostart

    run: ->
      @living = true

    step: (dt, frameTime, frameIndex) ->
      if @delay > 0
        @delay -= dt
        return

      @age += dt
      @work dt, frameTime, frameIndex

    stop: ->
      @living = false

  class JobRunner
    @instance: null

    frames: 0
    isRunning: false
    then: null
    now: null
    lastJobIndex: null
    animationEnabled: true

    jobs: []

    constructor: (fps) ->
      if JobRunner.instance
        return JobRunner.instance

      @fps = fps
      @fpsInterval = 1000 / @fps

      @requestAnimFrame =
        window.requestAnimationFrame       ||
        window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame    ||
        (callback) -> window.setTimeout(callback, @fpsInterval)

    startAnimating: ->
      return unless @animationEnabled

      @then = window.performance.now()
      @isRunning = true
      @animate()

    animate: (frameTime) ->
      return unless @isRunning
      return unless @animationEnabled

      @requestAnimationFrame animate

      dt = frameTime - @now
      @now = frameTime
      elapsed = @now - @then

      if elapsed > @fpsInterval
        @then = @now - (elapsed % @fpsInterval)

        @processJobs dt, frameTime, ++@frames

    processJobs: (dt, frameTime, frameIndex) ->
      for job, index in @jobs by -1
        if job.age > job.duration
          @cancelJobAtIndex index
          continue

        job.step dt, frameTime, frameIndex if job.isAlive

    addJob: (job) ->
      job.id = ++@lastJobIndex
      @jobs.push job

    cancelJob: (id) ->
      index = @jobs.indexOf @findJob(id)
      @cancelJobAtIndex index

    cancelJobAtIndex: (index) ->
      @jobs.splice index, 1
      job.isAlive = false

    findJob: (id) ->
      if id instanceof Job
        return id

      for job in @jobs
        return job if job.id is id


  return JobRunner
)()
