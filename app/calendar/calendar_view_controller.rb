class CalendarViewController < UIViewController
  # https://github.com/mattetti/BubbleWrap
  attr_accessor :dataSource
  
  def viewDidLoad
    view.autoresizesSubviews = false
    
    @top = CalendarTopView.alloc.initWithFrame [[0,0],[320,54]]
    view.addSubview @top
    
    @top.prev_button.when(UIControlEventTouchUpInside) do
      showMonthIncludingTime @dayInPreviousMonth if @dayInPreviousMonth
    end
    @top.next_button.when(UIControlEventTouchUpInside) do
      showMonthIncludingTime @dayInNextMonth if @dayInNextMonth
    end
    
    @scroller = UIScrollView.alloc.initWithFrame [[0,54], [320,220]]
    self.view.addSubview @scroller
    showMonthIncludingTime Time.now
    
  end
  
  def showMonthIncludingTime time
    NSLog "Calling showMonthIncludingTime(#{time})"
    return if @grid and @grid.month == time.month
    @grid.view.removeFromSuperview if @grid and @grid.view.superview
    
    @top.label.text = time.strftime '%B'
    
    firstDay = time
    firstDay = Time.local time.year, time.month
    
    @dayInPreviousMonth = firstDay - 2.days
    @dayInNextMonth = firstDay + 36.days
    
    until firstDay.sunday? do
      firstDay -= 1.day
    end
  
    @grid = MonthGridViewController.alloc.init
    @grid.firstDay = firstDay
    @grid.month = time.month
    @scroller.addSubview @grid.view
    
    
  
  end
  
end