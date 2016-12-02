class Circle::TaskablesController < ApplicationController
  layout "internal"
  require 'pry'
  before_action :ensure_logged_in
  before_action :set_back_path, only: [:volunteering, :organizing]

  include HasCircle

  def volunteer
    authorize! :read, current_circle
    @tasks = current_user.tasks.for_circle(current_circle).volunteered.not_completed.ordered_by_date
    @supplies = current_user.supplies.for_circle(current_circle).volunteered.not_completed.ordered_by_date
  end


  def organizer
    authorize! :read, current_circle
    @tasks = current_user.tasks.for_circle(current_circle).organized.not_completed.ordered_by_date
    @supplies = current_user.supplies.for_circle(current_circle).organized.not_completed.ordered_by_date
  end

  def supply_calendar
    authorize! :read, current_circle
    @supplies = current_user.supplies.for_circle(current_circle).volunteered.not_completed.ordered_by_date
    respond_to do |format|
      format.ics do
        cal = Icalendar::Calendar.new
        @supplies.each do |supply|
          cal.add_event(create_supply_event supply)
        end
        cal.publish
        calstr = cal.to_ical
        render :text => cal.to_ical
        filename = current_user.name + '-' + current_circle.name + '-' + "Calendar"
        headers['Content-Disposition'] = 'attachment; filename="'+ filename.delete(' ') + '.ics"'
      end
    end
  end


  def task_calendar
    authorize! :read, current_circle
    @tasks = current_user.tasks.for_circle(current_circle).volunteered.not_completed.ordered_by_date
    respond_to do |format|
      format.ics do
        cal = Icalendar::Calendar.new
        @tasks.each do |task|
          cal.add_event(create_task_event task)
        end
        cal.publish
        calstr = cal.to_ical
        render :text => cal.to_ical
        filename = current_user.name + '-' + current_circle.name + '-' + "Calendar"
        headers['Content-Disposition'] = 'attachment; filename="'+ filename.delete(' ') + '.ics"'
      end
    end
  end

  def create_task_event(task)
    event = Icalendar::Event.new
    task_presenter = TaskPresenter.new(task)
    event.dtstart = task.start_date || task.due_date
    event.dtend = unless task.due_time.nil? then 
                    convert_to_datetime task.due_date, task.due_time 
                  else task.due_date
                  end
    if event.dtstart == event.dtend
      event.dtend = event.dtend.end_of_day
    end
    event.summary = "Lale Task - " + task_presenter.name
    event.description = task_presenter.description
    event.location = task.primary_location.address
    event.url = circle_task_url(task.circle, task)
    event
  end

   def create_supply_event(supply)
    event = Icalendar::Event.new
    task_presenter = TaskPresenter.new(supply)
    event.dtstart = supply.due_date
    event.dtend = supply.due_date.end_of_day
    event.summary = "Lale Supply - " + task_presenter.name
    event.description = task_presenter.description
    event.location = supply.location.address
    event.url = circle_supply_url(supply.circle, supply)
    event
  end

  def convert_to_datetime(date, time)
    time = Time.parse(time)
    DateTime.new(date.year, date.month, date.day, time.hour, time.min)
  end

end
