require 'tilt'
require 'helpers'

module Statum
  class SendStatusEmail

  include Helpers

  def initialize(data)
    @email = data['user_email']
    data['url'] = "http://localhost:9393/status/#{data['id']}"
    send_email(data)
  end

  def send_email(data)
    subject = subject_for_status_email(data)
    html_body = status_output_body(data)
    to = @email

    return if to.empty? # Sometimes... there's just nobody listening.

    user, domain = CONFIG["email"].split("@")
    pony_options = pony_options_for_email(data).merge({
      # Make the From: address e.g. "user+statum@gmail.com" so it's easily filterable.
      :from => "#{user}+statum@#{domain}"
    })

    deliver_mail(to, subject, html_body, pony_options)
  end

  def subject_for_status_email(data)
    "Statum - new status created at #{data['created_at']} by #{data['user_login']}"
  end

  def status_output_body(data)
    template = Tilt.new(File.join(File.dirname(__FILE__), "/views/email/status.erb"))
    template.render(self, :data => data)
  end

 end
end
