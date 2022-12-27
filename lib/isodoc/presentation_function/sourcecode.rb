module IsoDoc
  class PresentationXMLConvert < ::IsoDoc::Convert
    def sourcehighlighter_css(docxml)
      @sourcehighlighter or return
      ins = docxml.at(ns("//misc-container")) ||
        docxml.at(ns("//bibdata")).after("<misc-container/>").next_element
      ins << "<source-highlighter-css>#{sourcehighlighter_css_file}" \
             "</source-highlighter-css>"
    end

    def sourcehighlighter_css_file
      File.read(File.join(File.dirname(__FILE__), "..", "base_style",
                          "rouge.css"))
    end

    def sourcehighlighter
      @sourcehighlighter or return
      f = Rouge::Formatters::HTML.new
      opts = { gutter_class: "rouge-gutter", code_class: "rouge-code" }
      { formatter: f,
        formatter_line: Rouge::Formatters::HTMLLineTable.new(f, opts) }
    end

    def sourcecode(docxml)
      sourcehighlighter_css(docxml)
      @highlighter = sourcehighlighter
      docxml.xpath(ns("//sourcecode")).each do |f|
        sourcecode1(f)
      end
    end

    def sourcecode1(elem)
      source_highlight(elem)
      source_label(elem)
    end

    def source_highlight(elem)
      @highlighter or return
      markup = source_remove_markup(elem)
      p = source_lex(elem)
      elem.children = if elem["linenums"] == "true"
                        r = sourcecode_table_to_elem(elem, p)
                        source_restore_markup_table(r, markup)
                      else
                        r = @highlighter[:formatter].format(p)
                        source_restore_markup(Nokogiri::XML.fragment(r), markup)
                      end
    end

    def source_remove_markup(elem)
      ret = {}
      name = elem.at(ns("./name")) and ret[:name] = name.remove.to_xml
      ret[:ann] = elem.xpath(ns("./annotation")).each(&:remove)
      ret[:call] = elem.xpath(ns("./callout")).each_with_object([]) do |c, m|
        m << { xml: c.remove.to_xml, line: c.line - elem.line }
      end
      ret
    end

    def source_restore_markup(wrapper, markup)
      ret = source_restore_callouts(wrapper, markup[:call])
      "#{markup[:name]}#{ret}#{markup[:ann]}"
    end

    def source_restore_markup_table(wrapper, markup)
      source_restore_callouts_table(wrapper, markup[:call])
      ret = to_xml(wrapper)
      "#{markup[:name]}#{ret}#{markup[:ann]}"
    end

    def source_restore_callouts(code, callouts)
      text = to_xml(code)
      text.split(/[\n\r]/).each_with_index do |c, i|
        while !callouts.empty? && callouts[0][:line] == i
          c.sub!(/\s+$/, " <span class='c'>#{callouts[0][:xml]}</span> ")
          callouts.shift
        end
      end.join("\n")
    end

    def source_restore_callouts_table(table, callouts)
      table.xpath(".//td[@class = 'rouge-code']/sourcecode")
        .each_with_index do |c, i|
        while !callouts.empty? && callouts[0][:line] == i
          c << " <span class='c'>#{callouts[0][:xml]}</span> "
          callouts.shift
        end
      end
    end

    def sourcecode_table_to_elem(elem, tokens)
      r = Nokogiri::XML(@highlighter[:formatter_line].format(tokens)).root
      r.xpath(".//td[@class = 'rouge-code']/pre").each do |pre|
        %w(style).each { |n| elem[n] and pre[n] = elem[n] }
        pre.name = "sourcecode"
        pre.children = to_xml(pre.children).sub(/\s+$/, "")
      end
      r
    end

    def source_lex(elem)
      l = (Rouge::Lexer.find(elem["lang"] || "plaintext") ||
       Rouge::Lexer.find("plaintext"))
      l.lex(@c.decode(elem.children.to_xml))
    end

    def source_label(elem)
      labelled_ancestor(elem) and return
      lbl = @xrefs.anchor(elem["id"], :label, false) or return
      prefix_name(elem, block_delim,
                  l10n("#{lower2cap @i18n.figure} #{lbl}"), "name")
    end
  end
end
