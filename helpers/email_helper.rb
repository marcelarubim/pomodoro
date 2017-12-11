require 'sinatra/base'
require 'mail'

module Sinatra
  module Helpers
    def email?(str)
      str.match(/\A[^@]+@[^@]+\Z/)
    end

    def send_register_email(token)
      url = "#{request.base_url}/account/reset/#{token}"
      email_body = erb :'test_mailer.html', locals: { url: url }

      Mail.deliver do
        to ENV['EMAIL_USER']
        from ENV['EMAIL_USER']
        subject 'MyApp Account Verification'
        text_part do
          body 'A request has been made to verify your MyApp account.' \
               'If you made this request, go to ' + url +
               '. If you did not make this request, ignore this email.'
        end
        html_part do
          content_type 'text/html; charset=UTF-8'
          body email_body
        end
      end
    end
  end
end
