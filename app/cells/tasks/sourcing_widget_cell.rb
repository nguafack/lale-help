class Tasks::SourcingWidgetCell < ::ViewModel

  include ActionView::Helpers::FormOptionsHelper

  # the first argument to the #cell call is "model" in here
  alias :task :model

  delegate :can?, to: :ability

  delegate :is_missing_volunteers?, :volunteer_count_required, :volunteers, :circle, :working_group,
    to: :task

  # deep down the user icon partial is rendered, which uses current_circle.
  # since that partial is used globally I don't want to change the variable name
  alias :current_circle :circle

  # this is the cells default action, ran when using the cell('path') helper
  def show
    render
  end

  private

  def helper_stats
    [volunteers.count, volunteer_count_required].join('/')
  end

  def current_user
    @options[:current_user]
  end

  def assignable_volunteers_select
    cell('tasks/volunteer_select_tag', task)
  end

  def ability
    @ability ||= Ability.new(current_user)
  end

  def links
    @links ||= begin
      OpenStruct.new(
        decline: circle_task_decline_path(circle, task),
        accept: circle_task_volunteer_path(circle, task),
        invite_wg: circle_task_invite_path(circle, task, type: 'working_group'),
        invite_sms_wg: circle_task_invitesms_path(circle, task, type: 'working_group'),
        invite_circle: circle_task_invite_path(circle, task, type: 'circle'),
        invite_sms_circle: circle_task_invitesms_path(circle, task, type: 'circle'),
        assign_volunteer: circle_task_assign_volunteer_path(circle, task)
      )
    end
  end

  def working_group_invitees_count
    @_wg_invitees_count ||= begin
      all_users_count               = working_group.active_users.size
      volunteers_from_working_group = volunteers.select { |user| working_group.active_users.include?(user) }
      ignored_users_count           = [volunteers_from_working_group, current_user].flatten.uniq.size
      invitees_count                = all_users_count - ignored_users_count
      ensure_non_negative_number(invitees_count)
    end
  end

  def circle_invitees_count
    @_circle_invitees_count ||= begin
      all_users_count     = circle.users.active.size
      ignored_users_count = [volunteers, current_user].flatten.uniq.size
      invitees_count      = all_users_count - ignored_users_count
      ensure_non_negative_number(invitees_count)
    end
  end

  # since a task can be overassigned with helpers (more volunteers than required)
  def ensure_non_negative_number(number)
    number > 0 ? number : 0
  end
end
