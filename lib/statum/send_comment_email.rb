require 'tilt'
require 'helpers'

module Statum
  class SendCommentEmail

  include Helpers

  def initialize(data)
    @email = data['email']
    data['url'] = "http://localhost:9393/status/#{data['id']}"
    send_email(data)
  end

  def send_email(data)
    subject = subject_for_comment_email(data)
    html_body = comment_output_body(data)
    to = @email

    return if to.empty? # Sometimes... there's just nobody listening.

    user, domain = CONFIG["email"].split("@")
    pony_options = pony_options_for_email(data).merge({
      # Make the From: address e.g. "user+statum@gmail.com" so it's easily filterable.
      :from => "#{user}+statum@#{domain}"
    })

    deliver_mail(to, subject, html_body, pony_options)
  end

  def subject_for_comment_email(data)
    "Statum - new comment created at #{data['created_at']} by #{data['login']}"
  end

  def comment_output_body(data)
    template = Tilt.new(File.join(File.dirname(__FILE__), "/views/email/comment.erb"))
    template.render(self, :data => data)
  end

 end
end
