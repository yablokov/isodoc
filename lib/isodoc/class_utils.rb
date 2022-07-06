module IsoDoc
  module ClassUtils
    def date_range(date)
      from = date.at(ns("./from"))
      to = date.at(ns("./to"))
      on = date.at(ns("./on"))
      return date.text unless from || on || to
      return on.text if on

      ret = "#{from.text}&#x2013;"
      ret += to.text if to
      ret
    end

    def ns(xpath)
      xpath.gsub(%r{/([a-zA-z])}, "/xmlns:\\1")
        .gsub(%r{::([a-zA-z])}, "::xmlns:\\1")
        .gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]* ?=)}, "[xmlns:\\1")
        .gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]*[/\[\]])}, "[xmlns:\\1")
    end

    def liquid(doc)
      # unescape HTML escapes in doc
      doc = doc.split(%r<(\{%|%\})>).each_slice(4).map do |a|
        a[2] = a[2].gsub("&lt;", "<").gsub("&gt;", ">") if a.size > 2
        a.join
      end.join
      Liquid::Template.parse(doc)
    end

    def case_strict(text, casing, script, firstonly: true)
      return text unless %w(Latn Cyrl Grek Armn).include?(script)

      seen = false
      text.split(/(\s+)/).map do |w|
        letters = w.chars
        case_strict1(letters, casing) if !seen || !firstonly
        seen ||= /\S/.match?(w)
        letters.join
      end.join
    end

    def case_strict1(letters, casing)
      return letters if letters.empty?

      case casing
      when "capital" then letters.first.upcase!
      when "lowercase" then letters.first.downcase!
      when "allcaps" then letters.map(&:upcase!)
      end
    end

    def case_with_markup(linkend, casing, script, firstonly: true)
      seen = false
      xml = Nokogiri::XML("<root>#{linkend}</root>")
      xml.traverse do |b|
        next unless b.text? && !seen

        b.replace(Common::case_strict(b.text, casing, script,
                                      firstonly: firstonly))
        seen = true if firstonly
      end
      xml.root.children.to_xml
    end

    def nearest_block_parent(node)
      until %w(p title td th name formula li dt dd sourcecode pre quote
               note example)
          .include?(node.name)
        node = node.parent
      end
      node
    end

    # node is at the start of sentence in a Metanorma XML context
    def start_of_sentence(node)
      prec = nearest_block_parent(node).xpath("./descendant-or-self::text()") &
        node.xpath("./preceding::text()")
      prec.empty? || /(?!<[^.].)\.\s+$/.match(prec.map(&:text).join)
    end
  end
end
