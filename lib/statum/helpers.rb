require 'pony'

module Helpers
  def self.random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    str = ""
    1.upto(len) { |i| str << chars[rand(chars.size-1)] }
    return str
  end

  class RecoverableEmailError < StandardError
  end

  def deliver_mail(to, subject, html_body, pony_options = {})
    options = { :to => to, :via => :smtp, :subject => subject, :html_body => html_body,
      # These settings are from the Pony documentation and work with Gmail's SMTP TLS server.
      :via_options => {
        :address => "smtp.gmail.com",
        :port => "587",
        :enable_starttls_auto => true,
        :user_name => "#{Statum::CONFIG["email"]}",
        :password => "#{Statum::CONFIG["password"]}",
        :authentication => :plain,
        # the HELO domain provided by the client to the server
      }
    }
    begin
      Pony.mail(options.merge(pony_options))
    rescue Net::SMTPAuthenticationError => error
      # Gmail's SMTP server sometimes gives this response; we've seen it come up in the admin dashboard.
      if error.message.include?("Cannot authenticate due to temporary system problem")
        raise RecoverableEmailError.new(error.message)
      else
        raise error
      end
    rescue Errno::ECONNRESET, Errno::ECONNABORTED, Errno::ETIMEDOUT => error
      raise RecoverableEmailError.new(error.message)
    end
  end

  def pony_options_for_email(data)
    # See http://cr.yp.to/immhf/thread.html for information about headers used for threading.
    # To have Gmail properly thread all correspondences, you must use the same value for In-Reply-To
    # on all messages in the same thread. The message ID that In-Reply-To refers to need not exist.
    # Note that consumer Gmail (but not corporate Gmail for your domain) ignores any custom message-id
    # on the message and instead uses their own.

    # Strip off any port-numbers from hostname. Gmail will not thread properly when the
    # In-Reply-To header has colons in it. It must just discard the header altogether.
    hostname_without_port = Statum::CONFIG["hostname"].sub(/\:.+/, "")
    message_id = "<status-id-#{data['id']}-statum@#{hostname_without_port}>"
    {
      :headers => {
        "In-Reply-To" => message_id,
        "References" => message_id
      }
    }
  end
end
