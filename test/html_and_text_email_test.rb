require 'test_helper'
require 'html_and_text_email'

class TestMailer < ActionMailer::Base
  self.template_root = File.join(RAILS_ROOT, 'vendor/plugins/html_and_text_email/test/fixtures')
  
  def cool_mail(recipient)
    @recipients = recipient
    @subject    = "multipart example"
    @from       = "test@example.com"
    @sent_on    = Time.local 2004, 12, 12
    @body       = { "recipient" => recipient }
    @content_type= "text/html"
  end
end


class HtmlAndTextEmailTest < ActionMailer::TestCase  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.raise_delivery_errors = true
    ActionMailer::Base.deliveries = []

    @original_logger = TestMailer.logger
    @recipient = 'test@localhost'
  end
  
    
  test "html2text was added into ActionMailer::Base" do
    assert ActionMailer::Base.methods.include? "html2text"
  end
  
  test "html2text works" do
    html               = "<html>Hey <script>Malicious Code</script></html>"
    link               = "<a href=\"http://www.google.com\">The Internet</a>"
    link_without_label = "<a href=\"http://www.google.com\"></a>"
    link_with_link_label= "<a href=\"http://www.google.com\">http://www.google.com</a>"
    
    
    assert_equal "Hey \n",                                   ActionMailer::Base.html2text(html)
    assert_equal "The Internet [http://www.google.com]\n",   ActionMailer::Base.html2text(link)
    assert_equal "[http://www.google.com]\n",                ActionMailer::Base.html2text(link_without_label)
    assert_equal "http://www.google.com [http://www.google.com]\n", ActionMailer::Base.html2text(link_with_link_label)
  end
  
  def test_nested_parts_with_body
    created = nil
    
    assert_nothing_raised { created = TestMailer.create_cool_mail(@recipient)}
    assert_equal 2,created.parts.size        
    assert_equal "text/plain", created.parts.first.content_type
    assert_equal "text/html", created.parts.last.content_type
    assert_equal created.parts.first.body, <<-OUTPUT
test@localhost 
OUTPUT
    
    assert_equal created.parts.last.body+"\n", <<-OUTPUT
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
  <title>multipart example</title>
</head>
<body>
  <div style="font-family: arial; font-size: 12px;">
    <p style="margin: 0 0 15px 0; padding: 0; ">
      test@localhost
    </p>  
  </div>
</body>
OUTPUT
    
  end
  
  def test_plain_part_not_created_if_plain_part_exists
    TestMailer.template_root = File.join(RAILS_ROOT, 'vendor/plugins/html_and_text_email/test/fixtures_alt')
    created = nil
    assert_nothing_raised { created = TestMailer.create_cool_mail(@recipient) }
    assert_equal 2, created.parts.size
  end
  
end
