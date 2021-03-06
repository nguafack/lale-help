class SupplyPresenter < Presenter
  delegate :id, :name, :volunteers, :volunteer_count_required, :comments, :due_date,
    :description, :complete?, :on_track?, :more_volunteers_needed?, :circle, to: :object

  let(:statuses) do
    statuses = []
    statuses << :complete  if _.complete?
    statuses << :on_track  if _.on_track?
    statuses << :urgent    if _.more_volunteers_needed?
    statuses << :new
    statuses
  end

  let(:status) do
    statuses.first
  end

  let(:messages) do
    statuses = []
    statuses << :volunteer_needed   if _.more_volunteers_needed?
    statuses << :recent_activity    if recent_comments?
    statuses
  end

  let(:message_key) { messages.first }

  let(:message) do
    I18n.t("supply.presenter.messages.#{message_key}") if message_key.present?
  end

  let(:recent_comments?) do
    _.comments.where("created_at > ?", 2.days.ago).exists?
  end

  let(:css) do
    "taskable-urgency-#{status}" if status.present?
  end

  let(:date_attributes) do
    {data: {urgency: status}} if status.present?
  end

  let(:formatted_date) do
    I18n.l(_.due_date, format: :long)
  end

end
