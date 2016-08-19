module PageObject
  module Circle
    class MyActivities < PageObject::Page

      set_url '/circles/{circle_id}/taskables/volunteer{?as}'

      section :tab_nav, PageObject::Component::TabNav, '.tab-nav'

      # FIXME review if it should be DRYed up
      sections :tasks, '#my-tasks-list' do
        element :name, '.task-title'
      end

      # FIXME review if it should be DRYed up
      sections :supplies, '#my-supplies-list' do
        element :name, '.task-title'
      end

      # FIXME review if it should be DRYed up
      def has_task?(task_to_find)
        tasks.any? { |task| task.name.text == task_to_find.name }
      end

      # FIXME review if it should be DRYed up
      def has_supply?(supply_to_find)
        supplies.any? { |supply| supply.name.text == supply_to_find.name }
      end

    end
  end
end