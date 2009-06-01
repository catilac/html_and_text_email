#HtmlAndTextEmail
module HtmlAndTextEmail
  def self.included(base)
    base.extend Enhancement::HtmlToText
    base.send(:include, Enhancement::Base)
  end

  module Enhancement
    # Stolen! From http://blog.choonkeat.com/weblog/2005/10/html2text-funct.html
    module HtmlToText
      require 'cgi'
      NUM_CHARS=80
      def html2text(html)
        text = html.gsub(/(&nbsp;|\s)+/im, ' ').squeeze(' ').strip

        linkregex = /<a (src|href)=\S*([\'|\"])([^>\s]*)\2[^>]*>(.*?)<\/a>/i # original
        while linkregex.match(text)
          if $~[4].nil?
            text.sub!(linkregex, "["+$~[3]+"]")
          else 
            text.sub!(linkregex, $~[4]+ " ["+$~[3]+"]")
          end
        end

        text = CGI.unescapeHTML(
          text.
            gsub(/<(script|style)[^>]*>.*<\/\1>/im, '').
            gsub(/<!--.*-->/m, '').
            gsub(/<title>.*<\/title>/, '').
            gsub(/<hr(| [^>]*)>/i, "___\n").
            gsub(/<li(| [^>]*)>/i, "\n* ").
            gsub(/<blockquote(| [^>]*)>/i, '> ').
            gsub(/<(br)(| [^>]*)>/i, "\n").
            gsub(/<(\/h[\d]+|p)(| [^>]*)>/i, "\n\n").
            gsub(/<[^>]*>/, '')).lstrip.gsub(/\n[ ]+/, "\n") + "\n"
        
        for i in (1..(text.size/NUM_CHARS).ceil)
          text[i*NUM_CHARS, text.size] = text[i*NUM_CHARS, text.size].sub(' ', "\n")
        end
        text.squeeze(' ')
      end
    end
    
    module Base
      include HtmlToText
      include ActionMailer
      
      def self.included(base)
        base.alias_method_chain(:create_mail, :text)
      end

      def create_mail_with_text #:nodoc:
        mail = create_mail_without_text
        # if there is already a text/plain type, then don't generate another part.
        
        if mail.parts.reject { |p| true unless p.content_type =~ /plain/ }.empty?
          mail.parts.each do |p|
            if p.content_type == "text/html"
              part = TMail::Mail.new
              part.body = html2text(p.body)
              part.content_type = "text/plain"
              part.set_content_disposition "inline"
              mail.parts << part
            end
          end
        end
        unless mail.parts.empty?
          mail.content_type = "multipart/alternative" if mail.content_type !~ /^multipart/
          ordered_parts = sort_parts(mail.parts, ActionMailer::Base.default_implicit_parts_order)
          mail.parts.size.times { mail.parts.shift }
          ordered_parts.size.times { mail.parts << ordered_parts.shift }
        end
        mail
      end
    end
  end
end
