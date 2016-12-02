class Task::Notifications::InvitationSMS < Mutations::Command
 
  required do
    model :task
    model :current_user, class: User
    string :type
  end

  def execute

    invite_users
    if invitees.count > 0
      Task::Comments::Invited.run(item: task, user: current_user, invite_count: invitees.count)
    end

    OpenStruct.new(volunteers: invitees)
  end

  private

  def invite_users
    post_sms 
  end

  def invitees
    @invitees ||= begin
      invitees = (type == "circle" ? task.circle.volunteers.active : task.working_group.users)
      invitees.to_a.reject do |u| 
        u == current_user || task.volunteers.include?(u) || !u.email.present?
      end
    end
  end

  def post_sms
    require 'net/https'
    require 'json'

    @host = 'wuzz6ztgkj.execute-api.us-west-2.amazonaws.com'
    @path = "/DEV"

     @body ={
       "laleMessage" => "Hello Armin, Lale needs your help on the task 'Garten umgraben - nochmal' on Saturday 10 December 2016 16:00",
       "lalePhoneNumbers" => [{"phoneNumber" => "+15103311126"},{"phoneNumber" => "+12134472302"}]
     }.to_json

    http = Net::HTTP.new(@host, 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Post.new(@path, initheader = {'Content-Type' =>'application/json'})
    request.body = @body
    response = http.request(request) 

    puts "Response #{response.code} #{response.message}: #{response.body}"
  end

end
