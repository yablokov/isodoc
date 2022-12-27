module IsoDoc
  class PresentationXMLConvert < ::IsoDoc::Convert
    def concept(docxml)
      @definition_ids = docxml.xpath(ns("//definitions//dt"))
        .each_with_object({}) { |x, m| m[x["id"]] = true }
      docxml.xpath(ns("//concept")).each { |f| concept1(f) }
    end

    def concept1(node)
      xref = node&.at(ns("./xref/@target"))&.text or
        return concept_render(node, ital: "true", ref: "true", bold: "false",
                                    linkref: "true", linkmention: "false")
      if @definition_ids[xref]
        concept_render(node, ital: "false", ref: "false", bold: "false",
                             linkref: "true", linkmention: "false")
      else concept_render(node, ital: "true", ref: "true", bold: "false",
                                linkref: "true", linkmention: "false")
      end
    end

    def concept_render(node, defaults)
      opts, render, ref = concept_render_init(node, defaults)
      node&.at(ns("./refterm"))&.remove
      ref && opts[:ref] != "false" and render&.next = " "
      concept1_linkmention(ref, render, opts)
      concept1_ref(node, ref, opts)
      concept1_style(node, opts)
      node.replace(node.children)
    end

    def concept1_style(node, opts)
      r = node.at(ns(".//renderterm")) or return
      opts[:ital] == "true" and r.children = "<em>#{to_xml(r.children)}</em>"
      opts[:bold] == "true" and
        r.children = "<strong>#{to_xml(r.children)}</strong>"
      r.replace(r.children)
    end

    def concept_render_init(node, defaults)
      opts = %i(bold ital ref linkref linkmention)
        .each_with_object({}) do |x, m|
        m[x] = node[x.to_s] || defaults[x]
      end
      [opts, node.at(ns("./renderterm")),
       node.at(ns("./xref | ./eref | ./termref"))]
    end

    def concept1_linkmention(ref, renderterm, opts)
      (opts[:linkmention] == "true" &&
        !renderterm.nil? && !ref.nil?) or return
      ref2 = ref.clone
      r2 = renderterm.clone
      renderterm.replace(ref2).children = r2
    end

    def concept1_ref(_node, ref, opts)
      ref.nil? and return
      opts[:ref] == "false" and return ref.remove
      r = concept1_ref_content(ref)
      ref = r.at("./descendant-or-self::xmlns:xref | " \
                 "./descendant-or-self::xmlns:eref | " \
                 "./descendant-or-self::xmlns:termref")
      %w(xref eref).include? ref&.name and get_linkend(ref)
      opts[:linkref] == "false" && %w(xref eref).include?(ref&.name) and
        ref.replace(ref.children)
    end

    def concept1_ref_content(ref)
      if non_locality_elems(ref).select do |c|
           !c.text? || /\S/.match(c)
         end.empty?
        ref.replace(@i18n.term_defined_in.sub(/%/,
                                              to_xml(ref)))
      else ref.replace("[#{to_xml(ref)}]")
      end
    end

    def related(docxml)
      docxml.xpath(ns("//related")).each { |f| related1(f) }
    end

    def related1(node)
      p = node.at(ns("./preferred"))
      ref = node.at(ns("./xref | ./eref | ./termref"))
      label = @i18n.relatedterms[node["type"]].upcase
      if p && ref
        node.replace(l10n("<p><strong>#{label}:</strong> " \
                          "<em>#{to_xml(p)}</em> (#{Common::to_xml(ref)})</p>"))
      else
        node.replace(l10n("<p><strong>#{label}:</strong> " \
                          "<strong>**RELATED TERM NOT FOUND**</strong></p>"))
      end
    end

    def designation(docxml)
      docxml.xpath(ns("//term")).each { |t| merge_second_preferred(t) }
      docxml.xpath(ns("//preferred | //admitted | //deprecates"))
        .each { |p| designation1(p) }
    end

    def merge_second_preferred(term)
      pref = nil
      term.xpath(ns("./preferred[expression/name]")).each_with_index do |p, i|
        if i.zero? then pref = p
        else merge_second_preferred1(pref, p)
        end
      end
    end

    def merge_second_preferred1(pref, second)
      merge_preferred_eligible?(pref, second) or return
      n1 = pref.at(ns("./expression/name"))
      n2 = second.remove.at(ns("./expression/name"))
      n1.children = l10n("#{to_xml(n1.children)}; #{Common::to_xml(n2.children)}")
    end

    def merge_preferred_eligible?(first, second)
      firstex = first.at(ns("./expression")) || {}
      secondex = second.at(ns("./expression")) || {}
      first["geographic-area"] == second["geographic-area"] &&
        firstex["language"] == secondex["language"] &&
        !first.at(ns("./pronunciation | ./grammar")) &&
        !second.at(ns("./pronunciation | ./grammar"))
    end

    def designation1(desgn)
      s = desgn.at(ns("./termsource"))
      name = desgn.at(ns("./expression/name | ./letter-symbol/name | " \
                         "./graphical-symbol")) or return
      designation_annotate(desgn, name)
      s and desgn.next = s
    end

    def designation_annotate(desgn, name)
      designation_boldface(desgn)
      designation_field(desgn, name)
      g = desgn.at(ns("./expression/grammar")) and
        name << ", #{designation_grammar(g).join(', ')}"
      designation_localization(desgn, name)
      designation_pronunciation(desgn, name)
      desgn.children = name.children
    end

    def designation_boldface(desgn)
      desgn.name == "preferred" or return
      name = desgn.at(ns("./expression/name | ./letter-symbol/name")) or return
      name.children = "<strong>#{name.children}</strong>"
    end

    def designation_field(desgn, name)
      f = desgn.xpath(ns("./field-of-application | ./usage-info"))
        &.map { |u| to_xml(u.children) }&.join(", ")
      f&.empty? and return nil
      name << ", &#x3c;#{f}&#x3e;"
    end

    def designation_grammar(grammar)
      ret = []
      grammar.xpath(ns("./gender | ./number")).each do |x|
        ret << @i18n.grammar_abbrevs[x.text]
      end
      %w(isPreposition isParticiple isAdjective isVerb isAdverb isNoun)
        .each do |x|
        grammar.at(ns("./#{x}[text() = 'true']")) and
          ret << @i18n.grammar_abbrevs[x]
      end
      ret
    end

    def designation_localization(desgn, name)
      loc = [desgn&.at(ns("./expression/@language"))&.text,
             desgn&.at(ns("./expression/@script"))&.text,
             desgn&.at(ns("./@geographic-area"))&.text].compact
      loc.empty? and return
      name << ", #{loc.join(' ')}"
    end

    def designation_pronunciation(desgn, name)
      f = desgn.at(ns("./expression/pronunciation")) or return
      name << ", /#{to_xml(f.children)}/"
    end

    def termexample(docxml)
      docxml.xpath(ns("//termexample")).each { |f| example1(f) }
    end

    def termnote(docxml)
      docxml.xpath(ns("//termnote")).each { |f| termnote1(f) }
    end

    def termnote1(elem)
      lbl = l10n(@xrefs.anchor(elem["id"], :label) || "???")
      prefix_name(elem, "", lower2cap(lbl), "name")
    end

    def termdefinition(docxml)
      docxml.xpath(ns("//term[definition]")).each do |f|
        termdefinition1(f)
      end
    end

    def termdefinition1(elem)
      unwrap_definition(elem)
      multidef(elem) if elem.xpath(ns("./definition")).size > 1
    end

    def multidef(elem)
      d = elem.at(ns("./definition"))
      d = d.replace("<ol><li>#{to_xml(d.children)}</li></ol>").first
      elem.xpath(ns("./definition")).each do |f|
        f = f.replace("<li>#{to_xml(f.children)}</li>").first
        d << f
      end
      d.wrap("<definition></definition>")
    end

    def unwrap_definition(elem)
      elem.xpath(ns("./definition")).each do |d|
        %w(verbal-definition non-verbal-representation).each do |e|
          v = d&.at(ns("./#{e}"))
          v&.replace(v.children)
        end
      end
    end

    def termsource(docxml)
      docxml.xpath(ns("//termsource/modification")).each do |f|
        termsource_modification(f)
      end
      docxml.xpath(ns("//termsource")).each do |f|
        termsource1(f)
      end
    end

    def termsource1(elem)
      while elem&.next_element&.name == "termsource"
        elem << "; #{to_xml(elem.next_element.remove.children)}"
      end
      elem.children = l10n("[#{@i18n.source}: #{to_xml(elem.children).strip}]")
    end

    def termsource_modification(mod)
      mod.previous_element.next = l10n(", #{@i18n.modified}")
      mod.text.strip.empty? or mod.previous = " &#x2013; "
      mod.elements.size == 1 and
        mod.elements[0].replace(mod.elements[0].children)
      mod.replace(mod.children)
    end
  end
end
