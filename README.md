# Contents
- [What is this?](https://github.com/Abica/horse#what-is-this)
- [Why the name Horse?](https://github.com/Abica/horse#why-the-name-horse)
- [Examples](https://github.com/Abica/horse#examples)
- [APIs](https://github.com/Abica/horse#apis)
  - [Jobs API](https://github.com/Abica/horse#jobs-api)
  - [Horse API](https://github.com/Abica/horse#horse-api)
- [Why do you keep saying RAF?](https://github.com/Abica/horse#why-do-you-keep-saying-raf)


# What is this?
Horse is a lightweight run loop built for executing delayed functions over time to simplify tasks like custom
animation.

Jobs are processed every frame in a throttled RAF loop with wormhole patching. Unless paused or canceled, jobs
begin running after the specified delay has elapsed.

# Why the name Horse?
This is an old inside reference to a production Three.js client app I worked on many years ago.

Basically, we had a low level animation system that we called $horse, as it was the workhorse of the app.  When I decided to write this library I remembered the name and it fit. Horse is the workhorse.

Straight from the horse's mouth.

# Examples
Adding a job via horse.addJob is the only exposed method of adding a job to the system. The newly created job
is added to the jobs list, given an id and returned.

If autostart is not passed when adding a job, you must call .start() directly on the job before the timers will
begin running.

```coffeescript
fps = 60 # default

# Horse is a singleton, so subsequent calls receive initial instance
horse = new Horse(fps)

# tell horse to spin the run loop and process any jobs
horse.start()

# this job will run as soon as the horse instance is started and will update an
# element with the class current-time with the current time in miliseconds every
# frame for 10 seconds after a 5 second delay
tickerJob = horse.addJob
  delay: 5
  duration: 10
  work: (dt, frameTime, frameIndex) ->
    $el = $(".current-time")
    $el.text +(new Date)

colors = ["red", "green", "blue"]
all_colors = colors.join(" ")

# this job will not autostart, so we must call .start() on it if we want it
# to begin running
colorCyclingJob = horse.addJob
  autostart: false
  duration: 20
  work: (dt, frameTime, frameIndex) ->
    $el = $("div")
    $el.removeClass all_colors
    $el.addClass colors[frameIndex % colors.length]

# start and stop a job -- note that living jobs do nothing unless a horse instance
# has been told to start as well
colorCyclingJob.start()
colorCyclingJob.stop()

# if using the defaults, you can pass the work function as the only argument
translateJob = horse.addJob ->
  for bullet in bullets
    bullet.translateX bullet.speed

# autostarts, runs forever and plays a pretty disco light show on any divs
horse.addJob (dt, frameTime, frameIndex) ->
  $el = $("div")
  max = 255
  index = frameIndex % max
  [r, g, b] = [max - index, Math.floor(frameTime % max), index]
  $el.css "background", "rgb(#{r}, #{g}, #{b})"

# stop horsing around
horse.stop()
```


# APIs
All methods are called on an instance.

## Jobs API
Note that the only ways to get a job instance are by using the horse.findJob method
or by assigning the result of methods like horse.addJob. Most of the horse methods will
return a job, but there is no direct access to the Job class for creating orphaned jobs.

#### Properties
```coffeescript
job.isLiving   # is this job currently running
job.age        # elapsed seconds this job has been running
job.options    # contains the initial options hash with defaults applied
```

#### Methods
```coffeescript
job.start()                          # start timers; jobs won't process unless started
job.stop()                           # stops writing job timers
job.needsCanceled()                  # true if age > duration and not an infinite job
job.step(dt, frameTime, frameIndex)  # perform a single simulation step for this job
```


## Horse API
#### Properties
```coffeescript
horse.instance          # static property that returns the only instance of Horse
horse.animationEnabled  # is the runloop even enabled?
horse.isRunning         # is the engine currently running
horse.frames            # current number of frames since we started
horse.then              # miliseconds to last frame since starting
horse.now               # miliseconds to this frame since starting
horse.lastJobIndex      # returns the last job id created; next id is this + 1
```

#### Methods
```coffeescript
horse.setFPS(fps)     # change the current frames per second
horse.start()         # starts the RAF runloop and processes any living jobs
horse.stop()          # stops runloop

# queues a job
# takes either options hash or a function containing work to run every frame
#
# the options argument hash accepts and defaults to these properties:
#
#  options =
#    work: ->         # function to run each frame for the duration of this job
#    duration: -1     # duration in sections; -1 means run forever (default -1)
#    delay: 0         # delay in seconds to wait before running (default 0)
#    autostart: true  # start the timers for this job instantly if horse is running
horse.addJob(options)

horse.cancelJob(job)  # takes a job or job id and cancels  and returns it
horse.cancelAllJobs() # cancels any queued jobs
horse.findJob(id)     # takes a job or job id and returns the corresponding job
```

The following methods are available but are lower level and will llikely be made private
soon since they are intended mainly for internal use... You probably shouldn'tt use these directly.
```coffeescript
horse.processJobs()   # steps or cancels all currently running jobs one frame
horse.step()          # steps the world one frame and requests another frame
```


# Why do you keep saying RAF?
RAF is an acronym which stands for requestAnimationFrame. It is essentially a much more performant alternative
to setTimeout/setInterval for running scheduled callbacks and animations.

Basically RAF just tells the browser that we are planning on performing some animation, and we want our callback
to be run before the next repaint occurs. Usually RAF matches your display's refresh rate, however Horse
throttles it for situations where you want to lock to a given FPS.

This number is typically 60fps, and Horse also uses this as a default framerate. Only a single instance of Horse
is ever running at a time, and it sets up a single RAF run loop which will loop through any added jobs and step
them once each frame.

You can read the quintessential article on RAF by [Paul Irish here](http://www.paulirish.com/2011/requestanimationframe-for-smart-animating).