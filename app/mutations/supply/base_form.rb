class Supply::BaseForm < ::Form
  attribute :supply, :model, primary: true, new_records: true
  attribute :user, :model
  attribute :working_group, :model

  attribute :name,             :string
  attribute :working_group_id, :string
  attribute :due_date,         :date,   default: proc{ Date.today + 1.week }
  attribute :description,      :string

  attribute :location, :string, default: proc{ (supply.location || supply.circle.location).try :address }
  attribute :organizer_id,     :integer, default: proc { supply.organizer.try(:id) }

  # def possible_working_groups
  #   binding.pry
  #   supply.circle.working_groups.select do |wg|
  #     can? :manage, wg
  #   end
  # end


  class Submit < ::Form::Submit
    def validate
      add_error(:name, :too_short)                   if name.length < 5
      add_error(:description, :too_short)            if description.length < 5
      add_error(:due_date, :empty)                   if due_date.blank?
      add_error(:location, :empty)                   if location.blank?
    end

    def execute
      supply.tap do |t|
        t.name          = name
        t.due_date      = due_date
        t.description   = description
        t.working_group = working_group
        t.location      = Location.location_from(location)
        t.save

        t.roles.send('supply.organizer').destroy_all
        t.roles.send('supply.organizer').create user_id: organizer_id

        t.save
      end
    end
  end
end