class Circle::AdminsController < ApplicationController
  include HasCircle

  before_action do
    authorize! :manage, current_circle
  end

  def show
    @circle_form = Circle::Update.new(user: current_user, circle: current_circle)
  end

  def roles
  end

  def working_groups
  end

  def invite
  end


  helper_method def tab_class key
    'selected' if action_name == key
  end
end