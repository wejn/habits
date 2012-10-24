class Habit < NSObject
  COLORS = [
      '#77A247', #GREEN
      '#488FB4', #BLUE
      '#E2804F', #ORANGE
      '#E7BE2B', #YELLOW
      '#E2804F', #PEACH
      '#875495', #PURPLE
      '#7A5D35' #BROWN
    ]
  # :first_in_chain, :last_in_chain, :mid_chain, :missed, :future, :before_start
  attr_accessor :title, :color_index, :created_at, :days_checked, :time_to_do, :deadline, :active
  def serialize
    {
      title: @title,
      color_index: @color_index,
      created_at: @created_at,
      days_checked: @days_checked,
      time_to_do: @time_to_do || "",
      deadline: @deadline || "",
      active: @active
    }
  end  
  def initialize(options={title: "New Habit", active:true, days_checked: []})
    @title = options[:title]
    @active = options[:active]
    @color_index =  options[:color_index] || Habit.next_unused_color_index
    @days_checked = Array.new(options[:days_checked] || [])
    @created_at = options[:created_at] || Time.now
    @time_to_do = options[:time_to_do]
    @deadline = options[:deadline]
    @interval = 1.day
  end
  
  def is_new?
    @title == "New Habit"
  end
  
  def color
    COLORS[@color_index].to_color
  end
  def no_reminders?
    deadline.nil? or deadline == "" or time_to_do.nil? or time_to_do == ""
  end
  def self.save!
    queue = Dispatch::Queue.concurrent('goodtohear.habits.save')
    queue.async do
      data = all.map(&:serialize)
      # NSLog "saving data #{data}"
      App::Persistence['habits'] = data
      reschedule_all_notifications
    end
  end
  
  def self.load
    data = App::Persistence['habits']
    return nil unless data
    result = data.map do |item|
      Habit.new item
    end
  end
  
  def self.all
    @all ||= load || [Habit.new(title: "Double-tap here...")]
  end
  
  def self.next_unused_color_index
    return 0 unless @all
    result = @all.count + 1
    result = 0 if result >= COLORS.count
    result
  end
  
  def self.delete habit
    all.delete habit
    save!
    App.notification_center.post :deleted_habit
  end
  
  def self.days_ago(days)
    days.map{ |days_ago| Time.now - days_ago.days  }
  end
  
  def currentChainLength
    count = 0
    last_day = Time.now
    last_day = Time.local last_day.year, last_day.month, last_day.day
    for checked_day in @days_checked.reverse
      compare = last_day - checked_day
      return count if compare > @interval
      count += 1
      last_day = checked_day
    end
    count
  end
  
  def check_days days
    for day in days
      day = Time.local day.year, day.month, day.day
      @days_checked << day unless @days_checked.include? day
    end
    @days_checked.sort!
  end
  
  def uncheck_days days
    for day in days
      found = @days_checked.find{|d| d == Time.local(day.year, day.month, day.day) }
      @days_checked.delete found
    end
    @days_checked.sort!
  end
  def earliest_date
    @days_checked.first
  end
  
  def totalDays
    @days_checked.count
  end
  def longestChain
    30
  end
  def blank?
    @days_checked.count == 0
  end
  
  def self.reschedule_all_notifications
    UIApplication.sharedApplication.cancelAllLocalNotifications
    all.each(&:reschedule_notifications)
  end

  def timeWithHour hour, daysTime: dayOffset
    day = Time.now + dayOffset.days
    Time.local day.year, day.month, day.day, hour
  end

  TOMORROW = 1
  TODAY = 0

  def alarm dayOffset, atHour: hour, text: text
    notification = UILocalNotification.alloc.init
    notification.alertBody = text
    notification.fireDate = timeWithHour hour, daysTime: dayOffset
    UIApplication.sharedApplication.scheduleLocalNotification notification
  end

  def reschedule_notifications
    return if no_reminders?

    dayOffset = 0
    now = Time.now

    # always schedule tomorrow's reminders
    alarm TOMORROW, atHour: time_to_do, text: title
    alarm TOMORROW, atHour: deadline, text: "Last chance: #{title}"
    # if to_do_later then schedule both
    # so schedule deadline:
    alarm TODAY, atHour: deadline, text: "Last chance: #{title}"
    # if overdue don't schedule first reminder - it's in the past
    return if overdue? now
    alarm TODAY, atHour: time_to_do, text: title

  end
 
  def toggle(time)
    day = day(time)
    if @days_checked.include?(day)
      @days_checked.delete day
    else
      @days_checked << day
    end
    @days_checked.sort!
    Habit.save!
  end

  def day(time)
     Time.local time.year, time.month, time.day
  end

  def done?(time)
    @days_checked.include? day(time)
  end
  def to_do_later?(time)
    !done?(time)
    
  end
  def overdue?(time)
    false
  end

end