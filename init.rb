require 'html_and_text_email'
ActionMailer::Base.send(:include, HtmlAndTextEmail)