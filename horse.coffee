window.requestAnimationFrame = (->
  window.requestAnimationFrame       ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame    ||
  (callback) -> window.setTimeout(callback, @fpsInterval)
)()

window.Horse = (->
  class Job
    constructor: (duration, work, delay, autostart) ->
      [@duration, @work, @delay, @autostart] = arguments

      @living = false
      @age = 0
      @delay ||= 0
      @work ||= ->

      @start() if @autostart

    start: ->
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
        if job.age > job.duration
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
