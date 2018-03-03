module IsoDoc
  class Convert
    @anchors = {}

    def get_anchors
      @anchors
    end

    def back_anchor_names(docxml)
      docxml.xpath(ns("//annex")).each_with_index do |c, i|
        annex_names(c, (65 + i).chr.to_s)
      end
      docxml.xpath(ns("//bibitem")).each do |ref|
        reference_names(ref)
      end
    end

    def initial_anchor_names(d)
      introduction_names(d.at(ns("//introduction")))
      section_names(d.at(ns("//clause[title = 'Scope']")), "1", 1)
      section_names(d.at(ns(
        "//references[title = 'Normative References']")), "2", 1)
      section_names(d.at(ns("//sections/terms")), "3", 1)
      middle_section_asset_names(d)
    end

    def middle_section_asset_names(d)
      middle_sections = "//clause[title = 'Scope'] | "\
        "//references[title = 'Normative References'] | //sections/terms | "\
        "//sections/symbols-abbrevs | //clause[parent::sections]"
      sequential_asset_names(d.xpath(ns(middle_sections)))
    end

    def clause_names(docxml, sect_num)
      q = "//clause[parent::sections][not(xmlns:title = 'Scope')]"
      docxml.xpath(ns(q)).each_with_index do |c, i|
        section_names(c, (i + sect_num).to_s, 1)
      end
    end

    def termnote_label(n)
      @termnote_lbl.gsub(/%/, n.to_s)
    end

    def termnote_anchor_names(docxml)
      docxml.xpath(ns("//term[termnote]")).each do |t|
        t.xpath(ns("./termnote")).each_with_index do |n, i|
          @anchors[n["id"]] = 
            { label: termnote_label(i + 1),
              xref: l10n("#{@anchors[t['id']][:xref]}, "\
                         "#{@note_xref_lbl} #{i + 1}") }
        end
      end
    end

    SECTIONS_XPATH =
      "//foreword | //introduction | //sections/terms | //annex | "\
      "//sections/clause | //references[not(ancestor::references)]".freeze

    CHILD_NOTES_XPATH =
      "./*[not(self::xmlns:subsection)]//xmlns:note | ./xmlns:note".freeze

    def note_anchor_names(sections)
      sections.each do |s|
        notes = s.xpath(CHILD_NOTES_XPATH)
        notes.each_with_index do |n, i|
          next if @anchors[n["id"]]
          next if n["id"].nil?
          idx = notes.size == 1 ? "" : " #{i + 1}"
          @anchors[n["id"]] = anchor_struct(idx, s, @note_xref_lbl)
        end
        note_anchor_names(s.xpath(ns("./subsection")))
      end
    end

    CHILD_EXAMPLES_XPATH =
      "./*[not(self::xmlns:subsection)]//xmlns:example | "\
      "./xmlns:example".freeze

    def example_anchor_names(sections)
      sections.each do |s|
        notes = s.xpath(CHILD_EXAMPLES_XPATH)
        notes.each_with_index do |n, i|
          next if @anchors[n["id"]]
          idx = notes.size == 1 ? "" : " #{i + 1}"
          @anchors[n["id"]] = anchor_struct(idx, s, @example_xref_lbl)
        end
        example_anchor_names(s.xpath(ns("./subsection")))
      end
    end

    def middle_anchor_names(docxml)
      symbols_abbrevs = docxml.at(ns("//sections/symbols-abbrevs"))
      sect_num = 4
      if symbols_abbrevs
        section_names(symbols_abbrevs, sect_num.to_s, 1)
        sect_num += 1
      end
      clause_names(docxml, sect_num)
      termnote_anchor_names(docxml)
    end

    # extract names for all anchors, xref and label
    def anchor_names(docxml)
      initial_anchor_names(docxml)
      middle_anchor_names(docxml)
      back_anchor_names(docxml)
      # preempt clause notes with all other types of note
      note_anchor_names(docxml.xpath(ns("//table | //example | //formula | "\
                                        "//figure")))
      note_anchor_names(docxml.xpath(ns(SECTIONS_XPATH)))
      example_anchor_names(docxml.xpath(ns(SECTIONS_XPATH)))
    end

    def sequential_figure_names(clause)
      i = j = 0
      clause.xpath(ns(".//figure")).each do |t|
        if t.parent.name == "figure" then j += 1
        else
          j = 0
          i += 1
        end
        label = i.to_s + (j.zero? ? "" : "-#{j}")
        @anchors[t["id"]] = anchor_struct(label, nil, @figure_lbl)
      end
    end

    def anchor_struct(lbl, container, elem)
      ret = { label: lbl.to_s }
      ret[:xref] = 
        elem == "Formula" ? l10n("#{elem} (#{lbl})") : l10n("#{elem} #{lbl}")
      ret[:xref].gsub!(/ $/, "")
      ret[:container] = get_clause_id(container) unless container.nil?
      ret
    end

    def sequential_asset_names(clause)
      clause.xpath(ns(".//table")).each_with_index do |t, i|
        @anchors[t["id"]] = anchor_struct(i + 1, nil, @table_lbl)
      end
      sequential_figure_names(clause)
      clause.xpath(ns(".//formula")).each_with_index do |t, i|
        @anchors[t["id"]] = anchor_struct(i + 1, t, @formula_lbl)
      end
    end

    def hierarchical_figure_names(clause, num)
      i = j = 0
      clause.xpath(ns(".//figure")).each do |t|
        if t.parent.name == "figure" then j += 1
        else
          j = 0
          i += 1
        end
        label = "#{num}.#{i}" + (j.zero? ? "" : "-#{j}")
        @anchors[t["id"]] = anchor_struct(label, nil, @figure_lbl)
      end
    end

    def hierarchical_asset_names(clause, num)
      clause.xpath(ns(".//table")).each_with_index do |t, i|
        @anchors[t["id"]] = anchor_struct("#{num}.#{i + 1}", nil, @table_lbl)
      end
      hierarchical_figure_names(clause, num)
      clause.xpath(ns(".//formula")).each_with_index do |t, i|
        @anchors[t["id"]] = anchor_struct("#{num}.#{i + 1}", t, @formula_lbl)
      end
    end

    def introduction_names(clause)
      return if clause.nil?
      clause.xpath(ns("./subsection")).each_with_index do |c, i|
        section_names1(c, "0.#{i + 1}", 2)
      end
    end

    def section_names(clause, num, lvl)
      return if clause.nil?
      @anchors[clause["id"]] = 
        { label: num, xref: l10n("#{@clause_lbl} #{num}"), level: lvl }
      clause.xpath(ns("./subsection | ./term  | ./terms | ./symbols-abbrevs")).
        each_with_index do |c, i|
        section_names1(c, "#{num}.#{i + 1}", lvl + 1)
      end
    end

    def section_names1(clause, num, level)
      @anchors[clause["id"]] =
        { label: num, level: level, xref: num }
      # subclauses are not prefixed with "Clause"
      clause.xpath(ns("./subsection | ./terms | ./term | ./symbols-abbrevs")).
        each_with_index do |c, i|
        section_names1(c, "#{num}.#{i + 1}", level + 1)
      end
    end

    def annex_names(clause, num)
      obl = l10n("(#{@inform_annex_lbl})")
      obl = l10n("(#{@norm_annex_lbl})") if clause["obligation"] == "normative"
      label = l10n("<b>#{@annex_lbl} #{num}</b><br/>#{obl}")
      @anchors[clause["id"]] =
        { label: label, xref: "#{@annex_lbl} #{num}", level: 1 }
      clause.xpath(ns("./subsection")).each_with_index do |c, i|
        annex_names1(c, "#{num}.#{i + 1}", 2)
      end
      hierarchical_asset_names(clause, num)
    end

    def annex_names1(clause, num, level)
      @anchors[clause["id"]] = { label: num, xref: num, level: level }
      clause.xpath(ns(".//subsection")).each_with_index do |c, i|
        annex_names1(c, "#{num}.#{i + 1}", level + 1)
      end
    end
  end
end
