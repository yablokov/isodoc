require "spec_helper"

RSpec.describe IsoDoc do
  it "droplocs xrefs" do
    input = <<~INPUT
          <iso-standard xmlns="http://riboseinc.com/isoxml">
          <sections>
          <clause id="A">
          <formula id="B">
          </formula>
          </clause>
          <clause id="C">
          <p>This is <xref target="A"/> and <xref target="B"/>.
          This is <xref target="A" droploc="true"/> and <xref target="B" droploc="true"/>.</p>
      </clause>
      </sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      <iso-standard xmlns='http://riboseinc.com/isoxml' type="presentation">
        <preface>
          <clause type="toc" id="_" displayorder="1">
          <title depth="1">Table of contents</title>
        </clause>
        </preface>
        <sections>
          <clause id='A' displayorder="2">
            <title>1.</title>
            <formula id='B'>
              <name>1</name>
            </formula>
          </clause>
          <clause id='C' displayorder="3">
            <title>2.</title>
            <p>
              This is
              <xref target='A'>kla&#x16D;zo 1</xref>
               and
              <xref target='B'>kla&#x16D;zo 1, Formula (1)</xref>
              . This is
              <xref target='A' droploc='true'>1</xref>
               and
              <xref target='B' droploc='true'>(1)</xref>
              .
            </p>
          </clause>
        </sections>
      </iso-standard>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert
      .new({ i18nyaml: "spec/assets/i18n.yaml" }
      .merge(presxml_options))
      .convert("test", input, true)))).to be_equivalent_to xmlpp(output)
  end

  it "renders xrefs with style" do
    input = <<~INPUT
          <iso-standard xmlns="http://riboseinc.com/isoxml">
          <sections>
          <clause id="A"><title>My section</title>
          <formula id="B">
          </formula>
          </clause>
          <clause id="C">
          <p>This is <xref target="A"/> and <xref target="B"/> and <xref target="C"/>.</p>
          <p>This is <xref style="id" target="A"/> and <xref style="id" target="B"/> and <xref style="id" target="C"/>.</p>
          <p>This is <xref style="basic" target="A"/> and <xref style="basic" target="B"/> and <xref style="basic" target="C"/>.</p>
          <p>This is <xref style="short" target="A"/> and <xref style="short" target="B"/> and <xref style="short" target="C"/>.</p>
          <p>This is <xref style="full" target="A"/> and <xref style="full" target="B"/> and <xref style="full" target="C"/>.</p>
          </clause>
      </clause>
      </sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      <iso-standard xmlns='http://riboseinc.com/isoxml' type='presentation'>
        <preface>
          <clause type="toc" id="_" displayorder="1">
          <title depth="1">Table of contents</title>
        </clause>
        </preface>
        <sections>
          <clause id='A' displayorder='2'>
            <title depth='1'>
              1.
              <tab/>
              My section
            </title>
            <formula id='B'>
              <name>1</name>
            </formula>
          </clause>
          <clause id='C' displayorder='3'>
            <title>2.</title>
            <p>This is
        <xref style='id' target='A'>A</xref>
         and
        <xref style='id' target='B'>B</xref>
         and
        <xref style='id' target='C'>C</xref>
        .
      </p>
            <p>
              This is
              <xref target='A'>Clause 1</xref>
               and
              <xref target='B'>Clause 1, Formula (1)</xref>
               and
              <xref target='C'>Clause 2</xref>
              .
            </p>
            <p>
              This is
              <xref style='basic' target='A'>My section</xref>
               and
              <xref style='basic' target='B'>My section, Formula (1)</xref>
               and
              <xref style='basic' target='C'>Clause 2</xref>
              .
            </p>
            <p>
              This is
              <xref style='short' target='A'>Clause 1</xref>
               and
              <xref style='short' target='B'>Clause 1, Formula (1)</xref>
               and
              <xref style='short' target='C'>Clause 2</xref>
              .
            </p>
            <p>
              This is
              <xref style='full' target='A'>Clause 1, My section</xref>
               and
              <xref style='full' target='B'>Clause 1, My section, Formula (1)</xref>
               and
              <xref style='full' target='C'>Clause 2</xref>
              .
            </p>
          </clause>
        </sections>
      </iso-standard>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)))).to be_equivalent_to xmlpp(output)
  end

  it "processes inline formatting" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml">
      <preface><foreword>
      <p>
      <em>A</em> <strong>B</strong> <sup>C</sup> <sub>D</sub> <tt>E</tt>
      <strike>F</strike> <smallcap>G</smallcap> <keyword>I</keyword> <br/> <hr/>
      <bookmark id="H"/> <pagebreak/> <pagebreak orientation="landscape"/> <underline>J</underline>
      <underline style="wavy">J1</underline>
      <span class="A"><em>A</em> <strong>B</strong> <sup>C</sup> <sub>D</sub> <tt>E</tt> F</span>
      <span style="font-family:&quot;Arial&quot;"><em>A</em> F</span>
      </p>
      </foreword></preface>
      <sections>
      </iso-standard>
    INPUT
    html = <<~OUTPUT
      <div><h1 class="ForewordTitle">Foreword</h1>
               <p>
       <i>A</i> <b>B</b> <sup>C</sup> <sub>D</sub> <tt>E</tt>
       <s>F</s> <span style="font-variant:small-caps;">G</span> <span class="keyword">I</span> <br/> <hr/>
       <a id="H"/> <br/> <br/> <span style="text-decoration: underline">J</span>
       <span style="text-decoration: underline wavy">J1</span>
       <span class="A"><i>A</i> <b>B</b> <sup>C</sup> <sub>D</sub> <tt>E</tt> F</span>
       <span style="font-family:&quot;Arial&quot;"><i>A</i> F</span>
       </p>
             </div>
    OUTPUT

    doc = <<~OUTPUT
      <div><h1 class='ForewordTitle'>Foreword</h1>
          <p>
            <i>A</i>
            <b>B</b>
            <sup>C</sup>
            <sub>D</sub>
            <tt>E</tt>
            <s>F</s>
            <span style='font-variant:small-caps;'>G</span>
            <span class='keyword'>I</span>
            <br/>
            <hr/>
            <a id='H'/>
            <p>
              <br clear='all' style='mso-special-character:line-break;page-break-before:always'/>
            </p>
            <p>
              <br clear='all' class='section' orientation='landscape'/>
            </p>
            <u>J</u>
            <u style="text-decoration: wavy">J1</u>
            <span class="A">
            <i>A</i>
            <b>B</b>
            <sup>C</sup>
            <sub>D</sub>
            <tt>E</tt>
             F</span>
            <span style='font-family:&#x22;Arial&#x22;'><i>A</i> F</span>
          </p>
        </div>
    OUTPUT
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", input, true))
      .sub(/^.*<h1/m, "<div><h1").sub(%r{</div>.*$}m, "</div>"))
      .to be_equivalent_to xmlpp(html)
    expect(xmlpp(IsoDoc::WordConvert.new({})
      .convert("test", input, true))
      .sub(/^.*<h1/m, "<div><h1").sub(%r{</div>.*$}m, "</div>"))
      .to be_equivalent_to xmlpp(doc)
  end

  it "ignores index entries" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml">
      <preface><foreword>
      <p><index primary="A" secondary="B" tertiary="C"/></p>
      </foreword></preface>
      <sections/>
      <indexsect>
        <title>Index</title>
      </indexsect>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
          <iso-standard xmlns='http://riboseinc.com/isoxml' type='presentation'>
        <preface>
            <clause type="toc" id="_" displayorder="1">
      <title depth="1">Table of contents</title>
    </clause>
          <foreword displayorder="2">
            <p/>
          </foreword>
        </preface>
        <sections> </sections>
      </iso-standard>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)))).to be_equivalent_to xmlpp(output)
  end

  it "processes concept markup" do
    input = <<~INPUT
          <iso-standard xmlns="http://riboseinc.com/isoxml">
          <preface><foreword>
          <p>
          <ul>
          <li>
          <concept><refterm>term</refterm>
              <xref target='clause1'/>
            </concept></li>
            <li><concept><refterm>term</refterm>
              <renderterm>term</renderterm>
              <xref target='clause1'/>
            </concept></li>
          <li><concept><refterm>term</refterm>
              <renderterm>w[o]rd</renderterm>
              <xref target='clause1'>Clause #1</xref>
            </concept></li>
            <li><concept><refterm>term</refterm>
              <renderterm>term</renderterm>
              <eref bibitemid="ISO712" type="inline" citeas="ISO 712"/>
            </concept></li>
            <li><concept><refterm>term</refterm>
              <renderterm>word</renderterm>
              <eref bibitemid="ISO712" type="inline" citeas="ISO 712">The Aforementioned Citation</eref>
            </concept></li>
            <li><concept><refterm>term</refterm>
              <renderterm>word</renderterm>
              <eref bibitemid="ISO712" type="inline" citeas="ISO 712">
                <locality type='clause'>
                  <referenceFrom>3.1</referenceFrom>
                </locality>
                <locality type='figure'>
                  <referenceFrom>a</referenceFrom>
                </locality>
              </eref>
            </concept></li>
            <li><concept><refterm>term</refterm>
              <renderterm>word</renderterm>
              <eref bibitemid="ISO712" type="inline" citeas="ISO 712">
              <localityStack connective="and">
                <locality type='clause'>
                  <referenceFrom>3.1</referenceFrom>
                </locality>
              </localityStack>
              <localityStack connective="and">
                <locality type='figure'>
                  <referenceFrom>b</referenceFrom>
                </locality>
              </localityStack>
              </eref>
            </concept></li>
            <li><concept><refterm>term</refterm>
              <renderterm>word</renderterm>
              <eref bibitemid="ISO712" type="inline" citeas="ISO 712">
              <localityStack connective="and">
                <locality type='clause'>
                  <referenceFrom>3.1</referenceFrom>
                </locality>
              </localityStack>
              <localityStack connective="and">
                <locality type='figure'>
                  <referenceFrom>b</referenceFrom>
                </locality>
              </localityStack>
              The Aforementioned Citation
              </eref>
            </concept></li>
            <li><concept><refterm>term</refterm>
              <renderterm>word</renderterm>
              <termref base='IEV' target='135-13-13'/>
            </concept></li>
            <li><concept><refterm>term</refterm>
              <renderterm>word</renderterm>
              <termref base='IEV' target='135-13-13'>The IEV database</termref>
            </concept></li>
            <li><concept>
              <strong>error!</strong>
              </concept>
              </li>
            </ul>
          </p>
          </foreword></preface>
          <sections>
          <clause id="clause1"><title>Clause 1</title></clause>
          </sections>
          <bibliography><references id="_normative_references" obligation="informative" normative="true"><title>Normative References</title>
          <p>The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
      <bibitem id="ISO712" type="standard">
        <title format="text/plain">Cereals or cereal products</title>
        <title type="main" format="text/plain">Cereals and cereal products</title>
        <docidentifier type="ISO">ISO 712</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization>
            <name>International Organization for Standardization</name>
          </organization>
        </contributor>
      </bibitem>
      </references></bibliography>
          </iso-standard>
    INPUT
    presxml = <<~OUTPUT
         <iso-standard xmlns="http://riboseinc.com/isoxml" type="presentation">
          <preface>    <clause type="toc" id="_" displayorder="1">
      <title depth="1">Table of contents</title>
    </clause>
      <foreword displayorder="2">
                   <p>
                                  <ul>
                 <li>

               [term defined in <xref target="clause1">Clause 2</xref>]
             </li>
                 <li><em>term</em>
               [term defined in <xref target="clause1">Clause 2</xref>]
             </li>
                 <li><em>w[o]rd</em>
               [<xref target="clause1">Clause #1</xref>]
             </li>
                 <li><em>term</em>
               [term defined in <xref type="inline" target="ISO712">ISO 712</xref>]
             </li>
                 <li><em>word</em>
               [<xref type="inline" target="ISO712">The Aforementioned Citation</xref>]
             </li>
                 <li><em>word</em>
               [term defined in <xref type="inline" target="ISO712">ISO 712, Clause 3.1, Figure a</xref>]
             </li>
                 <li><em>word</em>
               [term defined in <xref type="inline" target="ISO712">ISO 712, Clause 3.1 and Figure b</xref>]
             </li>
                 <li><em>word</em>
               [<xref type="inline" target="ISO712">


               The Aforementioned Citation
               </xref>]
             </li>
                 <li><em>word</em>
               [term defined in <termref base="IEV" target="135-13-13"/>]
             </li>
                 <li><em>word</em>
               [<termref base="IEV" target="135-13-13">The IEV database</termref>]
             </li>
                 <li>
                   <strong>error!</strong>
                 </li>
               </ul>
             </p>
          </foreword></preface>
          <sections>
          <clause id="clause1" displayorder="4"><title depth="1">2.<tab/>Clause 1</title></clause>
          </sections>
          <bibliography><references id="_" obligation="informative" normative="true" displayorder="3"><title depth="1">1.<tab/>Normative References</title>
          <p>The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
      <bibitem id="ISO712" type="standard">
        <formattedref>International Organization for Standardization. <em>Cereals and cereal products</em>.</formattedref>
        <docidentifier type="ISO">ISO&#xa0;712</docidentifier>
        <biblio-tag>ISO&#xa0;712, </biblio-tag>
      </bibitem>
      </references></bibliography>
          </iso-standard>
    OUTPUT
    output = <<~OUTPUT
      #{HTML_HDR}
                 <br/>
             <div>
               <h1 class='ForewordTitle'>Foreword</h1>
               <p>
                 <ul>
                   <li>
                      [term defined in
                     <a href='#clause1'>Clause 2</a>
                     ]
                   </li>
                   <li>
                     <i>term</i>
                      [term defined in
                     <a href='#clause1'>Clause 2</a>
                     ]
                   </li>
                   <li>
                     <i>w[o]rd</i>
                      [
                     <a href='#clause1'>Clause #1</a>
                     ]
                   </li>
                   <li>
                     <i>term</i>
                      [term defined in
                     <a href='#ISO712'>ISO&#xa0;712</a>
                     ]
                   </li>
                   <li>
                     <i>word</i>
                      [
                     <a href='#ISO712'>The Aforementioned Citation</a>
                     ]
                   </li>
                   <li>
                     <i>word</i>
                      [term defined in
                     <a href='#ISO712'>ISO&#xa0;712, Clause 3.1, Figure a</a>
                     ]
                   </li>
                   <li>
                     <i>word</i>
                      [term defined in
                     <a href='#ISO712'>ISO&#xa0;712, Clause 3.1 and Figure b</a>
                     ]
                   </li>
                   <li>
                     <i>word</i>
                      [
                     <a href='#ISO712'> The Aforementioned Citation </a>
                     ]
                   </li>
                   <li>
                     <i>word</i>
                      [term defined in Termbase IEV, term ID 135-13-13]
                   </li>
                   <li>
                     <i>word</i>
                      [The IEV database]
                   </li>
                   <li> <b>error!</b> </li>
                 </ul>
               </p>
             </div>
             <p class='zzSTDTitle1'/>
             <div>
               <h1>1.&#160; Normative References</h1>
               <p>
                 The following documents are referred to in the text in such a way that
                 some or all of their content constitutes requirements of this
                 document. For dated references, only the edition cited applies. For
                 undated references, the latest edition of the referenced document
                 (including any amendments) applies.
               </p>
               <p id='ISO712' class='NormRef'>
                 ISO&#xa0;712, International Organization for Standardization.
                 <i>Cereals and cereal products</i>.
               </p>
             </div>
             <div id='clause1'>
               <h1>2.&#160; Clause 1</h1>
             </div>
           </div>
         </body>
       </html>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)))).to be_equivalent_to xmlpp(presxml)
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", presxml, true))).to be_equivalent_to xmlpp(output)
  end

  it "processes concept attributes" do
    input = <<~INPUT
             <iso-standard xmlns="http://riboseinc.com/isoxml">
             <preface><foreword>
             <p>
             <ul>
             <li><concept ital="true"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept bold="true" ital="false"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept ref="true"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept ital="true" ref="true"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept bold="true" ital="true" ref="true"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept ital="false" bold="true"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept ref="false"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept ital="false" ref="false"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept ital="true" ref="true" linkmention="true" linkref="true"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept bold="true" ital="false" ref="true" linkmention="true" linkref="true"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept bold="true" ital="true" ref="true" linkmention="true" linkref="true"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept ital="true" ref="true" linkmention="true" linkref="false"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept ital="true" ref="true" linkmention="false" linkref="true"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept ital="true" ref="true" linkmention="false" linkref="false"><refterm>term</refterm><renderterm>term</renderterm><xref target='clause1'/></concept>,</li>
             <li><concept ital="true" ref="true" linkmention="true" linkref="true"><strong>error!</strong></concept></li>
             <li><concept ital="false" bold="false" ref="false" linkmention="true">
      <refterm>CV_DiscreteCoverage</refterm>
      <renderterm>CV_DiscreteCoverage</renderterm>
      <xref target="term-cv_discretecoverage"/>
      </concept></li>
              </ul></p>
               </foreword></preface>
             <sections>
             <clause id="clause1"><title>Clause 1</title></clause>
             </sections>
            </iso-standard>
    INPUT
    presxml = <<~OUTPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml" type="presentation">
      <preface>
          <clause type="toc" id="_" displayorder="1"> <title depth="1">Table of contents</title> </clause>
        <foreword displayorder="2">
                   <p>
               <ul>
                 <li><em>term</em> [term defined in <xref target="clause1">Clause 1</xref>],</li>
                 <li><strong>term</strong> [term defined in <xref target="clause1">Clause 1</xref>],</li>
                 <li><em>term</em> [term defined in <xref target="clause1">Clause 1</xref>],</li>
                 <li><em>term</em> [term defined in <xref target="clause1">Clause 1</xref>],</li>
                 <li><strong><em>term</em></strong> [term defined in <xref target="clause1">Clause 1</xref>],</li>
                 <li><strong>term</strong> [term defined in <xref target="clause1">Clause 1</xref>],</li>
                 <li><em>term</em>,</li>
                 <li>term,</li>
                 <li><xref target="clause1"><em>term</em></xref> [term defined in <xref target="clause1">Clause 1</xref>],</li>
                 <li><xref target="clause1"><strong>term</strong></xref> [term defined in <xref target="clause1">Clause 1</xref>],</li>
                 <li><xref target="clause1"><strong><em>term</em></strong></xref> [term defined in <xref target="clause1">Clause 1</xref>],</li>
                 <li><xref target="clause1"><em>term</em></xref> [term defined in Clause 1],</li>
                 <li><em>term</em> [term defined in <xref target="clause1">Clause 1</xref>],</li>
                 <li><em>term</em> [term defined in Clause 1],</li>
                 <li>
                   <strong>error!</strong>
                 </li>
                 <li>
                   <xref target="term-cv_discretecoverage">CV_DiscreteCoverage</xref>
                 </li>
               </ul>
             </p>
      </foreword></preface>
      <sections>
      <clause id="clause1" displayorder="3"><title depth="1">1.<tab/>Clause 1</title></clause>
      </sections>
      </iso-standard>
    OUTPUT
    output = <<~OUTPUT
      #{HTML_HDR}
           <br/>
           <div>
             <h1 class='ForewordTitle'>Foreword</h1>
                            <p>
           <ul>
             <li><i>term</i> [term defined in <a href="#clause1">Clause 1</a>],</li>
             <li><b>term</b> [term defined in <a href="#clause1">Clause 1</a>],</li>
             <li><i>term</i> [term defined in <a href="#clause1">Clause 1</a>],</li>
             <li><i>term</i> [term defined in <a href="#clause1">Clause 1</a>],</li>
             <li><b><i>term</i></b> [term defined in <a href="#clause1">Clause 1</a>],</li>
             <li><b>term</b> [term defined in <a href="#clause1">Clause 1</a>],</li>
             <li><i>term</i>,</li>
             <li>term,</li>
             <li><a href="#clause1"><i>term</i></a> [term defined in <a href="#clause1">Clause 1</a>],</li>
             <li><a href="#clause1"><b>term</b></a> [term defined in <a href="#clause1">Clause 1</a>],</li>
             <li><a href="#clause1"><b><i>term</i></b></a> [term defined in <a href="#clause1">Clause 1</a>],</li>
             <li><a href="#clause1"><i>term</i></a> [term defined in Clause 1],</li>
             <li><i>term</i> [term defined in <a href="#clause1">Clause 1</a>],</li>
             <li><i>term</i> [term defined in Clause 1],</li>
             <li>
               <b>error!</b>
             </li>
             <li>
               <a href="#term-cv_discretecoverage">CV_DiscreteCoverage</a>
             </li>
           </ul>
         </p>
            </div>
            <p class='zzSTDTitle1'/>
            <div id='clause1'>
              <h1>1.&#160; Clause 1</h1>
            </div>
          </div>
        </body>
      </html>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)))).to be_equivalent_to xmlpp(presxml)
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", presxml, true))).to be_equivalent_to xmlpp(output)
  end

  it "processes concept markup for symbols" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml">
      <preface><foreword>
      <p>
      <ul>
      <li><concept>
          <refterm>term</refterm>
          <renderterm>ISO</renderterm>
          <xref target='d1'/>
        </concept></li>
        </ul>
        </p>
        </foreword>
        </preface>
        <sections>
        <definitions id="d">
        <dl>
        <dt id="d1">ISO</dt> <dd>xyz</xyz>
        <dt id="d2">IEC</dt> <dd>abc</xyz>
        </dl>
        </definitions>
        </sections>
        </iso-standard>
    INPUT
    presxml = <<~OUTPUT
      <iso-standard xmlns='http://riboseinc.com/isoxml' type='presentation'>
        <preface>
         <clause type="toc" id="_" displayorder="1">
      <title depth="1">Table of contents</title>
    </clause>
          <foreword displayorder='2'>
            <p>
              <ul>
                <li>ISO</li>
              </ul>
            </p>
          </foreword>
          </preface>
          <sections>
            <definitions id='d' displayorder='3'>
              <title>1.</title>
              <dl>
                <dt id='d1'>ISO</dt>
                <dd>xyz</dd>
                <dt id='d2'>IEC</dt>
                <dd>abc</dd>
              </dl>
            </definitions>
          </sections>
      </iso-standard>
    OUTPUT
    output = <<~OUTPUT
          #{HTML_HDR}
            <br/>
            <div>
              <h1 class='ForewordTitle'>Foreword</h1>
              <p>
                <ul>
                  <li>ISO</li>
                </ul>
              </p>
            </div>
            <p class='zzSTDTitle1'/>
            <div id='d' class='Symbols'>
              <h1>1.</h1>
              <dl>
                <dt id='d1'>
                  <p>ISO</p>
                </dt>
                <dd>xyz</dd>
                <dt id='d2'>
                  <p>IEC</p>
                </dt>
                <dd>abc</dd>
              </dl>
            </div>
          </div>
        </body>
      </html>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)))).to be_equivalent_to xmlpp(presxml)
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", presxml, true))).to be_equivalent_to xmlpp(output)
  end

  it "processes embedded inline formatting" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml">
      <preface> <clause type="toc" id="_">
      <title depth="1">Table of contents</title>
    </clause>
      <foreword>
      <p>
      <em><strong>&lt;</strong></em> <tt><link target="B"/></tt> <xref target="_http_1_1">Requirement <tt>/req/core/http</tt></xref> <eref type="inline" bibitemid="ISO712" citeas="ISO 712">Requirement <tt>/req/core/http</tt></eref>
      </p>
      </foreword></preface>
      <sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      #{HTML_HDR}
                 <br/>
                 <div>
                   <h1 class="ForewordTitle">Foreword</h1>
                   <p>
         <i><b>&lt;</b></i> <tt><a href="B">B</a></tt> <a href="#_http_1_1">Requirement <tt>/req/core/http</tt></a>  Requirement <tt>/req/core/http</tt>
         </p>
                 </div>
                 <p class="zzSTDTitle1"/>
               </div>
             </body>
         </html>
    OUTPUT
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", input, true))).to be_equivalent_to xmlpp(output)
  end

  it "processes inline images" do
    input = <<~INPUT
        <iso-standard xmlns="http://riboseinc.com/isoxml">
        <preface> <clause type="toc" id="_">
      <title depth="1">Table of contents</title>
    </clause>
    <foreword>
        <p>
      <image src="rice_images/rice_image1.png" height="20" width="30" id="_8357ede4-6d44-4672-bac4-9a85e82ab7f0" mimetype="image/png" alt="alttext" title="titletxt"/>
      </p>
      </foreword></preface>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
          #{HTML_HDR}
            <br/>
            <div>
              <h1 class='ForewordTitle'>Foreword</h1>
              <p>
                <img src='rice_images/rice_image1.png' height='20' width='30' title='titletxt' alt='alttext'/>
              </p>
            </div>
            <p class='zzSTDTitle1'/>
          </div>
        </body>
      </html>
    OUTPUT
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", input, true))).to be_equivalent_to xmlpp(output)
  end

  it "processes links" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml">
      <preface> <clause type="toc" id="_">
      <title depth="1">Table of contents</title>
    </clause>
    <foreword>
      <p>
      <link target="http://example.com"/>
      <link target="http://example.com">example</link>
      <link target="http://example.com" alt="tip">example</link>
      <link target="mailto:fred@example.com"/>
      <link target="mailto:fred@example.com">mailto:fred@example.com</link>
      </p>
      </foreword></preface>
      <sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      #{HTML_HDR}
                 <br/>
                 <div>
                   <h1 class="ForewordTitle">Foreword</h1>
                   <p>
         <a href="http://example.com">http://example.com</a>
         <a href="http://example.com">example</a>
         <a href="http://example.com" title="tip">example</a>
         <a href="mailto:fred@example.com">fred@example.com</a>
         <a href="mailto:fred@example.com">mailto:fred@example.com</a>
         </p>
                 </div>
                 <p class="zzSTDTitle1"/>
               </div>
             </body>
         </html>
    OUTPUT
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", input, true))).to be_equivalent_to xmlpp(output)
  end

  it "processes updatetype links" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml">
      <preface><foreword>
      <p>
      <link update-type="true" target="http://example.com"/>
      <link update-type="true" target="list.adoc">example</link>
      <link update-type="true" target="list" alt="tip">example</link>
      </p>
      </foreword></preface>
      <sections>
      </iso-standard>
    INPUT
    html = <<~OUTPUT
              <div>
                <h1 class="ForewordTitle">Foreword</h1>
                <p>
      <a href="http://example.com">http://example.com</a>
      <a href='list.adoc'>example</a>
      <a href='list.html' title='tip'>example</a>
      </p>
              </div>
    OUTPUT
    doc = <<~OUTPUT
              <div>
                <h1 class="ForewordTitle">Foreword</h1>
                <p>
      <a href="http://example.com">http://example.com</a>
      <a href='list.adoc'>example</a>
      <a href='list.doc' title='tip'>example</a>
      </p>
              </div>
    OUTPUT
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", input, true))
      .sub(/^.*<h1/m, "<div><h1").sub(%r{</div>.*$}m, "</div>"))
      .to be_equivalent_to xmlpp(html)
    expect(xmlpp(IsoDoc::WordConvert.new({})
      .convert("test", input, true))
      .sub(/^.*<h1/m, "<div><h1").sub(%r{</div>.*$}m, "</div>"))
      .to be_equivalent_to xmlpp(doc)
  end

  it "processes unrecognised markup" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml">
      <preface> <clause type="toc" id="_">
      <title depth="1">Table of contents</title>
    </clause>
    <foreword>
      <p>
      <barry fred="http://example.com">example</barry>
      </p>
      </foreword></preface>
      <sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      #{HTML_HDR}
                 <br/>
                 <div>
                   <h1 class="ForewordTitle">Foreword</h1>
                   <p>
         <para><b role="strong">&lt;barry fred="http://example.com"&gt;example&lt;/barry&gt;</b></para>
         </p>
                 </div>
                 <p class="zzSTDTitle1"/>
               </div>
             </body>
         </html>
    OUTPUT
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", input, true))).to be_equivalent_to xmlpp(output)
  end

  it "processes AsciiMath and MathML" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml" xmlns:m="http://www.w3.org/1998/Math/MathML">
      <preface>    <clause type="toc" id="_">
      <title depth="1">Table of contents</title>
    </clause>
     <foreword>
      <p>
      <stem type="AsciiMath">&lt;A&gt;</stem>
      <stem type="AsciiMath"><m:math><m:row>X</m:row></m:math><asciimath>&lt;A&gt;</asciimath></stem>
      <stem type="MathML"><m:math><m:row>X</m:row></m:math></stem>
      <stem type="LaTeX">Latex?</stem>
      <stem type="LaTeX"><asciimath>&lt;A&gt;</asciimath><latexmath>Latex?</latexmath></stem>
      <stem type="None">Latex?</stem>
      </p>
      </foreword></preface>
      <sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      #{HTML_HDR.sub(/<html/, "<html xmlns:m='m'")}
                 <br/>
                 <div>
                   <h1 class="ForewordTitle">Foreword</h1>
                   <p>
         <span class="stem">(#(&lt;A&gt;)#)</span>
         <span class="stem">(#(&lt;A&gt;)#)</span>
         <span class="stem"><m:math>
           <m:row>X</m:row>
         </m:math></span>
         <span class="stem">Latex?</span>
         <span class="stem">Latex?</span>
         <span class="stem">Latex?</span>
         </p>
                 </div>
                 <p class="zzSTDTitle1"/>
               </div>
             </body>
         </html>
    OUTPUT
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", input, true).sub(/<html/, "<html xmlns:m='m'")))
      .to be_equivalent_to xmlpp(output)
  end

  it "overrides AsciiMath delimiters" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml">
      <preface>
          <clause type="toc" id="_">
      <title depth="1">Table of contents</title>
    </clause>
      <foreword>
      <p>
      <stem type="AsciiMath">A</stem>
      (#((Hello))#)
      </p>
      </foreword></preface>
      <sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      #{HTML_HDR}
                 <br/>
                 <div>
                   <h1 class="ForewordTitle">Foreword</h1>
                   <p>
         <span class="stem">(#(((A)#)))</span>
         (#((Hello))#)
         </p>
                 </div>
                 <p class="zzSTDTitle1"/>
               </div>
             </body>
         </html>
    OUTPUT
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", input, true))).to be_equivalent_to xmlpp(output)
  end

  it "duplicates MathML with AsciiMath" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml" xmlns:m='http://www.w3.org/1998/Math/MathML'>
      <preface><foreword>
      <p>
      <stem type="MathML"><m:math>
        <m:msup> <m:mrow> <m:mo>(</m:mo> <m:mrow> <m:mi>x</m:mi> <m:mo>+</m:mo> <m:mi>y</m:mi> </m:mrow> <m:mo>)</m:mo> </m:mrow> <m:mn>2</m:mn> </m:msup>
      </m:math></stem>
      </p>
      </foreword></preface>
      <sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      <iso-standard xmlns='http://riboseinc.com/isoxml' xmlns:m='http://www.w3.org/1998/Math/MathML' type='presentation'>
        <preface>
            <clause type="toc" id="_" displayorder="1">
      <title depth="1">Table of contents</title>
    </clause>
          <foreword displayorder='2'>
            <p>
              <stem type='MathML'>
                 <m:math>
                   <m:msup>
                     <m:mrow>
                       <m:mo>(</m:mo>
                       <m:mrow>
                         <m:mi>x</m:mi>
                         <m:mo>+</m:mo>
                         <m:mi>y</m:mi>
                       </m:mrow>
                       <m:mo>)</m:mo>
                     </m:mrow>
                     <m:mn>2</m:mn>
                   </m:msup>
                 </m:math>
                 <asciimath>( x + y )^(2)</asciimath>
              </stem>
            </p>
          </foreword>
        </preface>
        <sections> </sections>
      </iso-standard>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)
      .gsub("<!--", "<comment>")
      .gsub("-->", "</comment>"))))
      .to be_equivalent_to xmlpp(output)
  end

  it "overrides duplication of MathML with AsciiMath" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml"  xmlns:m='http://www.w3.org/1998/Math/MathML'>
      <preface><foreword>
      <p>
      <stem type="MathML"><m:math>
        <m:msup> <m:mrow> <m:mo>(</m:mo> <m:mrow> <m:mi>x</m:mi> <m:mo>+</m:mo> <m:mi>y</m:mi> </m:mrow> <m:mo>)</m:mo> </m:mrow> <m:mn>2</m:mn> </m:msup>
      </m:math></stem>
      </p>
      </foreword></preface>
      <sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
          <iso-standard xmlns='http://riboseinc.com/isoxml' xmlns:m='http://www.w3.org/1998/Math/MathML' type='presentation'>
        <preface>
            <clause type="toc" id="_" displayorder="1">
      <title depth="1">Table of contents</title>
    </clause>
          <foreword displayorder='2'>
            <p>
              <stem type='MathML'>
                 <m:math>
                   <m:msup>
                     <m:mrow>
                       <m:mo>(</m:mo>
                       <m:mrow>
                         <m:mi>x</m:mi>
                         <m:mo>+</m:mo>
                         <m:mi>y</m:mi>
                       </m:mrow>
                       <m:mo>)</m:mo>
                     </m:mrow>
                     <m:mn>2</m:mn>
                   </m:msup>
                 </m:math>
              </stem>
            </p>
          </foreword>
        </preface>
        <sections> </sections>
      </iso-standard>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert
      .new({ suppressasciimathdup: true }
      .merge(presxml_options))
      .convert("test", input, true)
      .gsub("<!--", "<comment>")
      .gsub("-->", "</comment>"))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes eref types" do
    input = <<~INPUT
          <iso-standard xmlns="http://riboseinc.com/isoxml">
          <preface>
          <foreword>
          <p>
          <eref type="footnote" bibitemid="ISO712" citeas="ISO 712">A</stem>
          <eref type="inline" bibitemid="ISO712" citeas="ISO 712">A</stem>
          <eref type="footnote" bibitemid="ISO713" citeas="ISO 713">A</stem>
          <eref type="inline" bibitemid="ISO713" citeas="ISO 713">A</stem>
          </p>
          </foreword></preface>
          <bibliography><references id="_normative_references" obligation="informative" normative="true"><title>Normative References</title>
      <bibitem id="ISO712" type="standard">
        <formattedref format="text/plain"><em>Cereals and cereal products</em></formattedref>
        <docidentifier>ISO 712</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization>
            <abbreviation>ISO</abbreviation>
          </organization>
        </contributor>
      </bibitem>
            <bibitem id="ISO713" type="standard">
        <formattedref format="text/plain"><em>Cereals and cereal products</em></formattedref>
        <docidentifier>ISO 713</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization>
            <abbreviation>ISO</abbreviation>
          </organization>
        </contributor>
        <uri type="citation">http://wwww.example.com</uri>
      </bibitem>
          </references>
          </bibliography>
          </iso-standard>
    INPUT
    presxml = <<~OUTPUT
           <iso-standard xmlns="http://riboseinc.com/isoxml" type="presentation">
         <preface>
           <clause type="toc" id="_" displayorder="1">
             <title depth="1">Table of contents</title>
           </clause>
           <foreword displayorder="2">
             <p>
               <sup>
                 <xref type="footnote" target="ISO712">A</xref>
               </sup>
               <xref type="inline" target="ISO712">A</xref>
               <sup>
                 <link target="http://wwww.example.com">A</link>
               </sup>
               <link target="http://wwww.example.com">A</link>
             </p>
           </foreword>
         </preface>
         <bibliography>
           <references id="_" obligation="informative" normative="true" displayorder="3">
             <title depth="1">1.<tab/>Normative References</title>
             <bibitem id="ISO712" type="standard">
               <formattedref format="text/plain">
                 <em>Cereals and cereal products</em>
               </formattedref>
               <docidentifier>ISO 712</docidentifier>
               <contributor>
                 <role type="publisher"/>
                 <organization>
                   <abbreviation>ISO</abbreviation>
                 </organization>
               </contributor>
               <biblio-tag>ISO 712, </biblio-tag>
             </bibitem>
             <bibitem id="ISO713" type="standard">
               <formattedref format="text/plain">
                 <em>Cereals and cereal products</em>
               </formattedref>
               <docidentifier>ISO 713</docidentifier>
               <contributor>
                 <role type="publisher"/>
                 <organization>
                   <abbreviation>ISO</abbreviation>
                 </organization>
               </contributor>
               <uri type="citation">http://wwww.example.com</uri>
               <biblio-tag>ISO 713, </biblio-tag>
             </bibitem>
           </references>
         </bibliography>
       </iso-standard>
    OUTPUT
    output = <<~OUTPUT
      #{HTML_HDR}
             <br/>
             <div>
               <h1 class='ForewordTitle'>Foreword</h1>
                              <p>
                 <sup>
                   <a href="#ISO712">A</a>
                 </sup>
                 <a href="#ISO712">A</a>
                 <sup>
                   <a href="http://wwww.example.com">A</a>
                 </sup>
                 <a href="http://wwww.example.com">A</a>
               </p>
             </div>
             <p class="zzSTDTitle1"/>
             <div>
               <h1>1.  Normative References</h1>
               <p id="ISO712" class="NormRef">ISO 712,
                 <i>Cereals and cereal products</i>
               </p>
               <p id="ISO713" class="NormRef">ISO 713,
                 <i>Cereals and cereal products</i>
               </p>
             </div>
           </div>
         </body>
       </html>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)))).to be_equivalent_to xmlpp(presxml)
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", presxml, true))).to be_equivalent_to xmlpp(output)
  end

  it "processes eref content" do
    input = <<~INPUT
          <iso-standard xmlns="http://riboseinc.com/isoxml">
          <preface><foreword>
          <p>
          <eref type="inline" bibitemid="ISO712" citeas="ISO 712"/>
          <eref type="inline" bibitemid="ISO712"/>
          <eref type="inline" bibitemid="ISO712"><locality type="table"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO712"><localityStack connective="and"><locality type="table"><referenceFrom>1</referenceFrom></locality></localityStack></eref>
          <eref type="inline" bibitemid="ISO712"><localityStack connective="and"><locality type="table"><referenceFrom>1</referenceFrom></locality></localityStack><localityStack connective="and"><locality type="clause"><referenceFrom>1</referenceFrom></locality></localityStack></eref>
          <eref type="inline" bibitemid="ISO712"><locality type="table"><referenceFrom>1</referenceFrom><referenceTo>1</referenceTo></locality></eref>
          <eref type="inline" bibitemid="ISO712"><locality type="clause"><referenceFrom>1</referenceFrom></locality><locality type="table"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO712"><locality type="clause"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO712"><locality type="clause"><referenceFrom>1.5</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO712"><locality type="table"><referenceFrom>1</referenceFrom></locality>A</eref>
          <eref type="inline" bibitemid="ISO712"><locality type="whole"></locality></eref>
          <eref type="inline" bibitemid="ISO712"><locality type="locality:prelude"><referenceFrom>7</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO712"><locality type="locality:URI"><referenceFrom>7</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO712" citeas="ISO 712">A</eref>
          <eref type="inline" bibitemid="ISO712"><locality type="anchor"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO712"><locality type="anchor"><referenceFrom>1</referenceFrom></locality><locality type="clause"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" droploc="true" bibitemid="ISO712"><locality type="anchor"><referenceFrom>1</referenceFrom></locality><locality type="clause"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" case="lowercase" bibitemid="ISO712"><locality type="anchor"><referenceFrom>1</referenceFrom></locality><locality type="clause"><referenceFrom>1</referenceFrom></locality></eref>
          </p>
          </foreword></preface>
          <bibliography><references id="_normative_references" obligation="informative" normative="true"><title>Normative References</title>
      <bibitem id="ISO712" type="standard">
        <title format="text/plain">Cereals and cereal products</title>
        <docidentifier>ISO 712</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization>
            <abbreviation>ISO</abbreviation>
          </organization>
        </contributor>
      </bibitem>
          </references>
          </bibliography>
          </iso-standard>
    INPUT
    presxml = <<~OUTPUT
            <iso-standard xmlns="http://riboseinc.com/isoxml" type="presentation">
                <preface>
                  <clause type="toc" id="_" displayorder="1"> <title depth="1">Table of contents</title> </clause>
                <foreword displayorder="2">
                <p>
                <xref type="inline" target="ISO712">ISO 712</xref>
               <xref type="inline" target="ISO712">ISO 712</xref>
               <xref type="inline" target="ISO712">ISO 712, Table 1</xref>
               <xref type="inline" target="ISO712">ISO 712, Table 1</xref>
               <xref type="inline" target="ISO712">ISO 712, Table 1 and Clause 1</xref>
               <xref type="inline" target="ISO712">ISO 712, Table 1–1</xref>
               <xref type="inline" target="ISO712">ISO 712, Clause 1, Table 1</xref>
               <xref type="inline" target="ISO712">ISO 712, Clause 1</xref>
               <xref type="inline" target="ISO712">ISO 712, Clause 1.5</xref>
               <xref type="inline" target="ISO712">A</xref>
               <xref type="inline" target="ISO712">ISO 712, Whole of text</xref>
               <xref type="inline" target="ISO712">ISO 712, Prelude 7</xref>
               <xref type="inline" target="ISO712">ISO 712, URI 7</xref>
               <xref type="inline" target="ISO712">A</xref>
               <xref type="inline" target="ISO712">ISO 712</xref>
               <xref type="inline" target="ISO712">ISO 712, Clause 1</xref>
               <xref type="inline" droploc="true" target="ISO712">ISO 712, 1</xref>
               <xref type="inline" case="lowercase" target="ISO712">ISO 712, clause 1</xref>
                </p>
                </foreword></preface>
                <bibliography><references id="_" obligation="informative" normative="true" displayorder=
      "3"><title depth='1'>1.<tab/>Normative References</title>
            <bibitem id="ISO712" type="standard">
              <formattedref><em>Cereals and cereal products</em>.</formattedref>
              <docidentifier>ISO&#xa0;712</docidentifier>
              <biblio-tag>ISO&#xa0;712,</biblio-tag>
            </bibitem>
                </references>
                </bibliography>
                </iso-standard>
    OUTPUT

    html = <<~OUTPUT
          #{HTML_HDR}
                     <br/>
                     <div>
                       <h1 class="ForewordTitle">Foreword</h1>
                       <p>
                 <a href="#ISO712">ISO&#xa0;712</a>
                 <a href="#ISO712">ISO&#xa0;712</a>
                 <a href="#ISO712">ISO&#xa0;712, Table 1</a>
                 <a href='#ISO712'>ISO&#xa0;712, Table 1</a>
      <a href='#ISO712'>ISO&#xa0;712, Table 1 and Clause 1</a>
                 <a href="#ISO712">ISO&#xa0;712, Table 1&#8211;1</a>
                 <a href="#ISO712">ISO&#xa0;712, Clause 1, Table 1</a>
                 <a href="#ISO712">ISO&#xa0;712, Clause 1</a>
                 <a href="#ISO712">ISO&#xa0;712, Clause 1.5</a>
                 <a href="#ISO712">A</a>
                 <a href="#ISO712">ISO&#xa0;712, Whole of text</a>
                 <a href="#ISO712">ISO&#xa0;712, Prelude 7</a>
                 <a href="#ISO712">ISO&#xa0;712, URI 7</a>
                 <a href="#ISO712">A</a>
                 <a href='#ISO712'>ISO&#xa0;712</a>
                 <a href='#ISO712'>ISO&#xa0;712, Clause 1</a>
                 <a href='#ISO712'>ISO&#xa0;712, 1</a>
                 <a href='#ISO712'>ISO&#xa0;712, clause 1</a>
                 </p>
                     </div>
                     <p class="zzSTDTitle1"/>
                     <div>
                       <h1>1.&#160; Normative References</h1>
                       <p id="ISO712" class="NormRef">ISO&#xa0;712, <i>Cereals and cereal products</i>.</p>
                     </div>
                   </div>
                 </body>
             </html>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)))).to be_equivalent_to xmlpp(presxml)
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", presxml, true))).to be_equivalent_to xmlpp(html)
  end

  it "processes eref content pointing to reference with citation URL" do
    input = <<~INPUT
          <iso-standard xmlns="http://riboseinc.com/isoxml">
          <bibdata>
          <language>fr</language>
          </bibdata>
          <preface><foreword>
          <p>
          <eref type="inline" bibitemid="ISO712" citeas="ISO 712"/>
          <eref type="inline" bibitemid="ISO712"/>
          <eref type="inline" bibitemid="ISO713"><locality type="table"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713"><localityStack connective="and"><locality type="table"><referenceFrom>1</referenceFrom></locality></localityStack></eref>
          <eref type="inline" bibitemid="ISO713"><localityStack connective="and"><locality type="table"><referenceFrom>1</referenceFrom></locality></localityStack><localityStack connective="and"><locality type="clause"><referenceFrom>1</referenceFrom></locality></localityStack></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="table"><referenceFrom>1</referenceFrom><referenceTo>1</referenceTo></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="clause"><referenceFrom>1</referenceFrom></locality><locality type="table"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="clause"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="clause"><referenceFrom>1.5</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="table"><referenceFrom>1</referenceFrom></locality>A</eref>
          <eref type="inline" bibitemid="ISO713"><locality type="whole"></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="locality:prelude"><referenceFrom>7</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713" citeas="ISO 713">A</eref>
          <eref type="inline" bibitemid="ISO713"><locality type="anchor"><referenceFrom>xyz</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="anchor"><referenceFrom>xyz</referenceFrom></locality><locality type="clause"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO714"/>
          </p>
          </foreword></preface>
          <bibliography><references id="_normative_references" obligation="informative" normative="true"><title>Normative References</title>
      <bibitem id="ISO712" type="standard">
        <title format="text/plain">Cereals and cereal products</title>
        <uri type="citation">http://www.example.com</uri>
        <uri type="citation" language="en">http://www.example.com/en</uri>
        <uri type="citation" language="fr">http://www.example.com/fr</uri>
        <docidentifier>ISO 712</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization>
            <abbreviation>ISO</abbreviation>
          </organization>
        </contributor>
      </bibitem>
      <bibitem id="ISO713" type="standard">
        <title format="text/plain">Cereals and cereal products</title>
        <uri type="citation">spec/assets/iso713</uri>
        <uri type="citation">spec/assets/iso714</uri>
        <docidentifier>ISO 713</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization>
            <abbreviation>ISO</abbreviation>
          </organization>
        </contributor>
      </bibitem>
      <bibitem id="ISO714" type="standard">
        <title format="text/plain">Cereals and cereal products</title>
        <uri type="citation">spec/assets/iso714.svg</uri>
        <docidentifier>ISO 714</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization>
            <abbreviation>ISO</abbreviation>
          </organization>
        </contributor>
      </bibitem>
          </references>
          </bibliography>
          </iso-standard>
    INPUT
    presxml = <<~OUTPUT
      <iso-standard xmlns='http://riboseinc.com/isoxml' type='presentation'>
         <bibdata>
           <language current='true'>fr</language>
         </bibdata>
         <preface>
         <clause type="toc" id="_" displayorder="1"> <title depth="1">Sommaire</title> </clause>
           <foreword displayorder='2'>
             <p>
               <link target="http://www.example.com/fr">ISO 712</link>
               <link target="http://www.example.com/fr">ISO 712</link>
               <link target="spec/assets/iso713.html">ISO 713, Tableau 1</link>
               <link target="spec/assets/iso713.html">ISO 713, Tableau 1</link>
               <link target="spec/assets/iso713.html">ISO 713, Tableau 1 et Article 1</link>
               <link target="spec/assets/iso713.html">ISO 713, Tableau 1–1</link>
               <link target="spec/assets/iso713.html">ISO 713, Article 1, Tableau 1</link>
               <link target="spec/assets/iso713.html">ISO 713, Article 1</link>
               <link target="spec/assets/iso713.html">ISO 713, Article 1.5</link>
               <link target="spec/assets/iso713.html">A</link>
               <link target="spec/assets/iso713.html">ISO 713, Ensemble du texte</link>
               <link target="spec/assets/iso713.html">ISO 713, Prelude 7</link>
               <link target="spec/assets/iso713.html">A</link>
               <link target="spec/assets/iso713.html#xyz">ISO 713</link>
               <link target="spec/assets/iso713.html#xyz">ISO 713, Article 1</link>
               <link target="spec/assets/iso714.svg">ISO 714</link>
             </p>
           </foreword>
         </preface>
         <bibliography>
           <references id='_' obligation='informative' normative='true' displayorder='3'>
             <title depth='1'>
               1.
               <tab/>
               Normative References
             </title>
             <bibitem id='ISO712' type='standard'>
               <formattedref>
                 <em>Cereals and cereal products</em>
                 .
                 <link target='http://www.example.com/fr'>http://www.example.com/fr</link>
                 .
               </formattedref>
               <uri type='citation'>http://www.example.com</uri>
               <uri type='citation' language='en'>http://www.example.com/en</uri>
               <uri type='citation' language='fr'>http://www.example.com/fr</uri>
               <docidentifier>ISO&#xa0;712</docidentifier>
               <biblio-tag>ISO&#xa0;712,</biblio-tag>
             </bibitem>
             <bibitem id='ISO713' type='standard'>
               <formattedref>
                 <em>Cereals and cereal products</em>
                 .
                 <link target='spec/assets/iso713'>spec/assets/iso713</link>
                 .
               </formattedref>
               <uri type='citation'>spec/assets/iso713</uri>
               <uri type='citation'>spec/assets/iso714</uri>
               <docidentifier>ISO&#xa0;713</docidentifier>
               <biblio-tag>ISO&#xa0;713,</biblio-tag>
             </bibitem>
             <bibitem id='ISO714' type='standard'>
               <formattedref>
                 <em>Cereals and cereal products</em>
                 .
                 <link target='spec/assets/iso714.svg'>spec/assets/iso714.svg</link>
                 .
               </formattedref>
               <uri type='citation'>spec/assets/iso714.svg</uri>
               <docidentifier>ISO&#xa0;714</docidentifier>
               <biblio-tag>ISO&#xa0;714,</biblio-tag>
             </bibitem>
           </references>
         </bibliography>
       </iso-standard>
    OUTPUT

    html = <<~OUTPUT
      <html lang='fr'>
         <head/>
         <body lang='fr'>
           <div class='title-section'>
             <p>&#xa0;</p>
           </div>
           <br/>
           <div class='prefatory-section'>
             <p>&#xa0;</p>
           </div>
           <br/>
           <div class='main-section'>
             <br/>
                   <div class="TOC" id="_">
        <h1 class="IntroTitle">Sommaire</h1>
      </div>
      <br/>
             <div>
               <h1 class='ForewordTitle'>Avant-propos</h1>
               <p>
                 <a href='http://www.example.com/fr'>ISO&#xa0;712</a>
                 <a href='http://www.example.com/fr'>ISO&#xa0;712</a>
                 <a href='spec/assets/iso713.html'> ISO&#xa0;713, Tableau 1 </a>
                 <a href='spec/assets/iso713.html'> ISO&#xa0;713, Tableau 1 </a>
                 <a href='spec/assets/iso713.html'> ISO&#xa0;713, Tableau 1 et Article 1 </a>
                 <a href='spec/assets/iso713.html'> ISO&#xa0;713, Tableau 1&#x2013;1 </a>
                 <a href='spec/assets/iso713.html'> ISO&#xa0;713, Article 1, Tableau 1 </a>
                 <a href='spec/assets/iso713.html'> ISO&#xa0;713, Article 1 </a>
                 <a href='spec/assets/iso713.html'> ISO&#xa0;713, Article 1.5 </a>
                 <a href='spec/assets/iso713.html'> A </a>
                 <a href='spec/assets/iso713.html'> ISO&#xa0;713, Ensemble du texte </a>
                 <a href='spec/assets/iso713.html'> ISO&#xa0;713, Prelude 7 </a>
                 <a href='spec/assets/iso713.html'>A</a>
                 <a href='spec/assets/iso713.html#xyz'> ISO&#xa0;713 </a>
                 <a href='spec/assets/iso713.html#xyz'> ISO&#xa0;713, Article 1 </a>
                 <a href='spec/assets/iso714.svg'>ISO&#xa0;714</a>
               </p>
             </div>
             <p class='zzSTDTitle1'/>
             <div>
               <h1> 1. &#xa0; Normative References </h1>
               <p id='ISO712' class='NormRef'>
                 ISO&#xa0;712,
                 <i>Cereals and cereal products</i>
                  .
                 <a href='http://www.example.com/fr'>http://www.example.com/fr</a>
                  .
               </p>
               <p id='ISO713' class='NormRef'>
                 ISO&#xa0;713,
                 <i>Cereals and cereal products</i>
                  .
                 <a href='spec/assets/iso713'>spec/assets/iso713</a>
                  .
               </p>
               <p id='ISO714' class='NormRef'>
                 ISO&#xa0;714,
                 <i>Cereals and cereal products</i>
                  .
                 <a href='spec/assets/iso714.svg'>spec/assets/iso714.svg</a>
                  .
               </p>
             </div>
           </div>
         </body>
       </html>
    OUTPUT

    word = <<~OUTPUT
      <body lang='EN-US' link='blue' vlink='#954F72'>
         <div class='WordSection1'>
           <p>&#xa0;</p>
         </div>
         <p>
           <br clear='all' class='section'/>
         </p>
         <div class='WordSection2'>
           <p>
             <br clear='all' style='mso-special-character:line-break;page-break-before:always'/>
           </p>
               <div class="TOC" id="_">
      <p class="zzContents">Sommaire</p>
    </div>
    <p>
      <br clear="all" style="mso-special-character:line-break;page-break-before:always"/>
    </p>
               <div>
             <h1 class="ForewordTitle">Avant-propos</h1>
             <p>
               <a href="http://www.example.com/fr">ISO 712</a>
               <a href="http://www.example.com/fr">ISO 712</a>
               <a href="spec/assets/iso713.html">ISO 713, Tableau 1</a>
               <a href="spec/assets/iso713.html">ISO 713, Tableau 1</a>
               <a href="spec/assets/iso713.html">ISO 713, Tableau 1 et Article 1</a>
               <a href="spec/assets/iso713.html">ISO 713, Tableau 1–1</a>
               <a href="spec/assets/iso713.html">ISO 713, Article 1, Tableau 1</a>
               <a href="spec/assets/iso713.html">ISO 713, Article 1</a>
               <a href="spec/assets/iso713.html">ISO 713, Article 1.5</a>
               <a href="spec/assets/iso713.html">A</a>
               <a href="spec/assets/iso713.html">ISO 713, Ensemble du texte</a>
               <a href="spec/assets/iso713.html">ISO 713, Prelude 7</a>
               <a href="spec/assets/iso713.html">A</a>
               <a href="spec/assets/iso713.html#xyz">ISO 713</a>
               <a href="spec/assets/iso713.html#xyz">ISO 713, Article 1</a>
               <a href="spec/assets/iso714.svg">ISO 714</a>
             </p>
           </div>
           <p> </p>
         </div>
         <p>
           <br clear="all" class="section"/>
         </p>
         <div class="WordSection3">
           <p class="zzSTDTitle1"/>
           <div>
             <h1>
                1.
                <span style="mso-tab-count:1">  </span>
                Normative References
              </h1>
             <p id="ISO712" class="NormRef">ISO 712,
                  <i>Cereals and cereal products</i>
                  .
                  <a href="http://www.example.com/fr">http://www.example.com/fr</a>
                  .
                </p>
             <p id="ISO713" class="NormRef">ISO 713,
                  <i>Cereals and cereal products</i>
                  .
                  <a href="spec/assets/iso713">spec/assets/iso713</a>
                  .
                </p>
             <p id="ISO714" class="NormRef">ISO 714,
                  <i>Cereals and cereal products</i>
                  .
                  <a href="spec/assets/iso714.svg">spec/assets/iso714.svg</a>
                  .
                </p>
           </div>
         </div>
       </body>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)
      .sub(%r{<localized-strings>.*</localized-strings>}m, ""))))
      .to be_equivalent_to xmlpp(presxml)
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", presxml, true))).to be_equivalent_to xmlpp(html)
    expect(xmlpp(Nokogiri::XML(IsoDoc::WordConvert.new({})
      .convert("test", presxml, true))
      .at("//body").to_xml))
      .to be_equivalent_to xmlpp(word)
  end

  it "processes eref content pointing to hidden bibliographic entries" do
    input = <<~INPUT
          <iso-standard xmlns="http://riboseinc.com/isoxml">
          <preface><foreword>
          <p>
          <eref type="inline" bibitemid="ISO712" citeas="ISO 712"/>
          <eref type="inline" bibitemid="ISO712"/>
          <eref type="inline" bibitemid="ISO713"><locality type="table"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713"><localityStack connective="and"><locality type="table"><referenceFrom>1</referenceFrom></locality></localityStack></eref>
          <eref type="inline" bibitemid="ISO713"><localityStack connective="and"><locality type="table"><referenceFrom>1</referenceFrom></locality></localityStack><localityStack connective="and"><locality type="clause"><referenceFrom>1</referenceFrom></locality></localityStack></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="table"><referenceFrom>1</referenceFrom><referenceTo>1</referenceTo></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="clause"><referenceFrom>1</referenceFrom></locality><locality type="table"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="clause"><referenceFrom>1</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="clause"><referenceFrom>1.5</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="table"><referenceFrom>1</referenceFrom></locality>A</eref>
          <eref type="inline" bibitemid="ISO713"><locality type="whole"></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="locality:prelude"><referenceFrom>7</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713" citeas="ISO 713">A</eref>
          <eref type="inline" bibitemid="ISO713"><locality type="anchor"><referenceFrom>xyz</referenceFrom></locality></eref>
          <eref type="inline" bibitemid="ISO713"><locality type="anchor"><referenceFrom>xyz</referenceFrom></locality><locality type="clause"><referenceFrom>1</referenceFrom></locality></eref>
          </p>
          </foreword></preface>
          <bibliography><references id="_normative_references" obligation="informative" normative="true" hidden="true"><title>Normative References</title>
      <bibitem id="ISO712" type="standard" hidden="true">
        <title format="text/plain">Cereals and cereal products</title>
        <uri type="citation">http://www.example.com</uri>
        <docidentifier>ISO 712</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization>
            <abbreviation>ISO</abbreviation>
          </organization>
        </contributor>
      </bibitem>
      <bibitem id="ISO713" type="standard" hidden="true">
        <title format="text/plain">Cereals and cereal products</title>
        <uri type='src'>https://www.iso.org/standard/3944.html</uri>
        <uri type='rss'>https://www.iso.org/contents/data/standard/00/39/3944.detail.rss</uri>
        <docidentifier>ISO 713</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization>
            <abbreviation>ISO</abbreviation>
          </organization>
        </contributor>
      </bibitem>
    INPUT
    presxml = <<~PRESXML
      <iso-standard xmlns='http://riboseinc.com/isoxml' type='presentation'>
         <preface>
         <clause type="toc" id="_" displayorder="1"> <title depth="1">Table of contents</title> </clause>
           <foreword displayorder='2'>
             <p>
               <link target="http://www.example.com">ISO 712</link>
               <link target="http://www.example.com">ISO 712</link>
               <link target="https://www.iso.org/standard/3944.html">ISO 713, Table 1</link>
               <link target="https://www.iso.org/standard/3944.html">ISO 713, Table 1</link>
               <link target="https://www.iso.org/standard/3944.html">ISO 713, Table 1 and Clause 1</link>
               <link target="https://www.iso.org/standard/3944.html">ISO 713, Table 1–1</link>
               <link target="https://www.iso.org/standard/3944.html">ISO 713, Clause 1, Table 1</link>
               <link target="https://www.iso.org/standard/3944.html">ISO 713, Clause 1</link>
               <link target="https://www.iso.org/standard/3944.html">ISO 713, Clause 1.5</link>
               <link target="https://www.iso.org/standard/3944.html">A</link>
               <link target="https://www.iso.org/standard/3944.html">ISO 713, Whole of text</link>
               <link target="https://www.iso.org/standard/3944.html">ISO 713, Prelude 7</link>
               <link target="https://www.iso.org/standard/3944.html">A</link>
               <link target="https://www.iso.org/standard/3944.html#xyz">ISO 713</link>
               <link target="https://www.iso.org/standard/3944.html#xyz">ISO 713, Clause 1</link>
             </p>
           </foreword>
         </preface>
         <bibliography>
           <references id='_' obligation='informative' normative='true' displayorder='3' hidden="true">
             <title depth='1'>Normative References</title>
             <bibitem id='ISO712' type='standard' hidden="true">
               <formattedref><em>Cereals and cereal products</em>. <link target="http://www.example.com">http://www.example.com</link>.</formattedref>
               <uri type='citation'>http://www.example.com</uri>
               <docidentifier>ISO&#xa0;712</docidentifier>
             </bibitem>
             <bibitem id='ISO713' type='standard' hidden="true">
               <formattedref><em>Cereals and cereal products</em>. <link target="https://www.iso.org/standard/3944.html">https://www.iso.org/standard/3944.html</link>.</formattedref>
             <uri type='src'>https://www.iso.org/standard/3944.html</uri>
              <uri type='rss'>https://www.iso.org/contents/data/standard/00/39/3944.detail.rss</uri>
               <docidentifier>ISO&#xa0;713</docidentifier>
             </bibitem>
           </references>
         </bibliography>
       </iso-standard>
    PRESXML
    html = <<~OUTPUT
      #{HTML_HDR}
             <br/>
             <div>
               <h1 class='ForewordTitle'>Foreword</h1>
               <p>
                 <a href='http://www.example.com'>ISO&#xa0;712</a>
                 <a href='http://www.example.com'>ISO&#xa0;712</a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Table 1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Table 1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Table 1 and Clause 1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Table 1&#8211;1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Clause 1, Table 1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Clause 1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Clause 1.5 </a>
                 <a href='https://www.iso.org/standard/3944.html'> A </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Whole of text </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Prelude 7 </a>
                 <a href='https://www.iso.org/standard/3944.html'>A</a>
                 <a href='https://www.iso.org/standard/3944.html#xyz'> ISO&#xa0;713 </a>
                 <a href='https://www.iso.org/standard/3944.html#xyz'> ISO&#xa0;713, Clause 1 </a>
               </p>
             </div>
             <p class='zzSTDTitle1'/>
           </div>
         </body>
       </html>
    OUTPUT
    word = <<~OUTPUT
      <html xmlns:epub='http://www.idpf.org/2007/ops' lang='en'>
        <head><style/></head>
             <body lang='EN-US' link='blue' vlink='#954F72'>
           <div class='WordSection1'>
             <p>&#160;</p>
           </div>
           <p>
             <br clear='all' class='section'/>
           </p>
           <div class='WordSection2'>
             <p>
               <br clear='all' style='mso-special-character:line-break;page-break-before:always'/>
             </p>
                   <div class="TOC" id="_">
        <p class="zzContents">Table of contents</p>
      </div>
      <p>
        <br clear="all" style="mso-special-character:line-break;page-break-before:always"/>
      </p>
             <div>
               <h1 class='ForewordTitle'>Foreword</h1>
               <p>
                 <a href='http://www.example.com'>ISO&#xa0;712</a>
                 <a href='http://www.example.com'>ISO&#xa0;712</a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Table 1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Table 1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Table 1 and Clause 1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Table 1&#8211;1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Clause 1, Table 1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Clause 1 </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Clause 1.5 </a>
                 <a href='https://www.iso.org/standard/3944.html'> A </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Whole of text </a>
                 <a href='https://www.iso.org/standard/3944.html'> ISO&#xa0;713, Prelude 7 </a>
                 <a href='https://www.iso.org/standard/3944.html'>A</a>
                 <a href='https://www.iso.org/standard/3944.html#xyz'> ISO&#xa0;713 </a>
                 <a href='https://www.iso.org/standard/3944.html#xyz'> ISO&#xa0;713, Clause 1 </a>
               </p>
             </div>
             <p>&#160;</p>
           </div>
           <p>
             <br clear='all' class='section'/>
           </p>
           <div class='WordSection3'>
             <p class='zzSTDTitle1'/>
           </div>
         </body>
       </html>
    OUTPUT

    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)))).to be_equivalent_to xmlpp(presxml)
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", presxml, true))).to be_equivalent_to xmlpp(html)
    expect(xmlpp(IsoDoc::WordConvert.new({})
      .convert("test", presxml, true))).to be_equivalent_to xmlpp(word)
  end

  it "processes eref content with Unicode characters" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml">
      <preface><foreword>
      <p>
      <eref type="inline" bibitemid="ISO712" citeas="BSI BS EN ISO 19011:2018&#8201;&#8212;&#8201;TC"/>
      </foreword></preface>
              <bibliography>
          <references id='_normative_references' obligation='informative' normative='true' displayorder="2">
          <title>Normative References</title>
            <bibitem id='ISO712' type='standard'>
              <title format='text/plain'>Cereals and cereal products</title>
              <uri type='citation'>http://www.example.com</uri>
              <docidentifier>ISO 712</docidentifier>
              <contributor>
                <role type='publisher'/>
                <organization>
                  <abbreviation>ISO</abbreviation>
                </organization>
              </contributor>
            </bibitem>
           </references></bibliography>
      </iso-standard>
    INPUT
    presxml = <<~OUTPUT
      <iso-standard xmlns='http://riboseinc.com/isoxml' type='presentation'>
        <preface>
        <clause type="toc" id="_" displayorder="1"> <title depth="1">Table of contents</title> </clause>
          <foreword displayorder='2'>
            <p>
              <link target='http://www.example.com'>BSI BS EN ISO 19011:2018&#x2009;&#x2014;&#x2009;TC</link>
            </p>
          </foreword>
          <bibliography displayorder='3'>
            <references id='_' obligation='informative' normative='true' displayorder='4'>
              <title depth='1'>
                1.
                <tab/>
                Normative References
              </title>
              <bibitem id='ISO712' type='standard'>
                 <formattedref><em>Cereals and cereal products</em>. <link target="http://www.example.com">http://www.example.com</link>.</formattedref>
                 <uri type='citation'>http://www.example.com</uri>
                <docidentifier>ISO&#xa0;712</docidentifier>
                <biblio-tag>ISO&#xa0;712,</biblio-tag>
              </bibitem>
            </references>
          </bibliography>
        </preface>
      </iso-standard>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)))).to be_equivalent_to xmlpp(presxml)
  end

  it "processes variant" do
    input = <<~INPUT
      <iso-standard xmlns="http://riboseinc.com/isoxml">
      <bibdata>
      <language>en</language>
      <script>Latn</script>
      </bibdata>
      <preface>
          <clause id="A"><title><variant lang="en" script="Latn">ABC</variant><variant lang="fr" script="Latn">DEF</variant></title></clause>
          <clause id="A1"><title><variant lang="en" script="Grek">ABC</variant><variant lang="fr" script="Grek">DEF</variant></title></clause>
          <clause id="A2"><title><variant lang="en">ABC</variant><variant lang="fr">DEF</variant></title></clause>
          <clause id="B"><title><variant lang="de" script="Latn">GHI</variant><variant lang="es" script="Latn">JKL</variant></title></clause>
          <clause id="C"><title><variant lang="fr" script="Latn">ABC</variant><variant lang="en" script="Latn">DEF</variant></title></clause>
          <clause id="C1"><title><variant lang="fr" script="Grek">ABC</variant><variant lang="en" script="Grek">DEF</variant></title></clause>
          <clause id="C2"><title><variant lang="fr">ABC</variant><variant lang="en">DEF</variant></title></clause>
          <p>A <variant><variant lang="en">B</variant><variant lang="fr">C</variant></variant> D <variant><variant lang="en" script="Latn">E</variant><variant lang="fr" script="Latn">F</variant></variant></p>
      </preface>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      <iso-standard xmlns='http://riboseinc.com/isoxml' type='presentation'>
        <bibdata>
          <language current='true'>en</language>
          <script current='true'>Latn</script>
        </bibdata>
        <preface>
          <clause type="toc" id="_" displayorder="1"> <title depth="1">Table of contents</title> </clause>
          <clause id='A' displayorder='2'>
            <title depth='1'>ABC</title>
          </clause>
          <clause id='A1' displayorder='3'>
            <title depth='1'>ABC/DEF</title>
          </clause>
          <clause id='A2' displayorder='4'>
            <title depth='1'>ABC</title>
          </clause>
          <clause id='B' displayorder='5'>
            <title depth='1'>GHI/JKL</title>
          </clause>
          <clause id='C' displayorder='6'>
            <title depth='1'>DEF</title>
          </clause>
          <clause id='C1' displayorder='7'>
            <title depth='1'>ABC/DEF</title>
          </clause>
          <clause id='C2' displayorder='8'>
            <title depth='1'>DEF</title>
          </clause>
          <p displayorder='9'>A B D E</p>
        </preface>
      </iso-standard>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)
      .sub(%r{<localized-strings>.*</localized-strings>}m, ""))))
      .to be_equivalent_to xmlpp(output)
  end

  it "cases xrefs" do
    input = <<~INPUT
          <iso-standard xmlns="http://riboseinc.com/isoxml">
          <preface>
          <clause id="CC"><title>Introduction</title></clause>
          </preface>
          <sections>
          <clause id="A">
          <table id="B">
          </table>
          <figure id="B1"/>
          <example id="B2"/>
          </clause>
          <clause id="C">
          <p>This is <xref target="A"/> and <xref target="B"/>.
          This is <xref target="A" case="capital"/> and <xref target="B" case="lowercase"/>.
          This is <xref target="A" case="lowercase"/> and <xref target="B" case="capital"/>.
          Downcasing an xref affects only the first letter: <xref target="B2" case="lowercase"/>.
          Capitalising an xref affects only the first letter: <xref target="B1" case="capital"/>.
          <xref target="A"/> is clause <em>initial.</em><br/>
          <xref target="A"/> is too.  </p>
          <p><xref target="A"/> is also.</p>
          <p>Annex has formatting, and crossreferences ignore it when determining casing. <xref target="AA"/>.</p>
          <p>Labels are not subject to casing: <xref target="CC" case="lowercase"/>
      </clause>
      <annex id="AA">
      <clause id="AA1"/>
      </annex>
      </sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      <iso-standard xmlns='http://riboseinc.com/isoxml' type='presentation'>
        <preface>
        <clause type="toc" id="_" displayorder="1"> <title depth="1">Table of contents</title> </clause>
          <clause id='CC' displayorder='2'>
            <title depth='1'>Introduction</title>
          </clause>
          </preface>
          <sections>
            <clause id='A' displayorder='3'>
              <title>1.</title>
              <table id='B'>
                <name>Tabelo 1</name>
              </table>
              <figure id='B1'>
                <name>Figur-etikedo duvorta 1</name>
              </figure>
              <example id='B2'>
                <name>Ekzempl-etikedo Duvorta</name>
              </example>
            </clause>
            <clause id='C' displayorder='4'>
              <title>2.</title>
              <p>
                This is
                <xref target='A'>kla&#x16D;zo 1</xref>
                 and
                <xref target='B'>tabelo 1</xref>
                . This is
                <xref target='A' case='capital'>Kla&#x16D;zo 1</xref>
                 and
                <xref target='B' case='lowercase'>tabelo 1</xref>
                . This is
                <xref target='A' case='lowercase'>kla&#x16D;zo 1</xref>
                 and
                <xref target='B' case='capital'>Tabelo 1</xref>
                . Downcasing an xref affects only the first letter:
                <xref target='B2' case='lowercase'>kla&#x16D;zo 1, Example</xref>
                . Capitalising an xref affects only the first letter:
                <xref target='B1' case='capital'>Figur-etikedo duvorta 1</xref>
                .
                <xref target='A'>Kla&#x16D;zo 1</xref>
                 is clause
                <em>initial.</em>
                <br/>
                <xref target='A'>Kla&#x16D;zo 1</xref>
                 is too.
              </p>
              <p>
                <xref target='A'>Kla&#x16D;zo 1</xref>
                 is also.
              </p>
              <p>
                Annex has formatting, and crossreferences ignore it when determining
                casing.
                <xref target='AA'>
                  <strong>Aldono</strong>
                   A
                </xref>
                .
              </p>
              <p>
                Labels are not subject to casing:
                <xref target='CC' case='lowercase'>Introduction</xref>
              </p>
              <annex id='AA' displayorder='5'>
                <title>
                  <strong>
                    <strong>Aldono</strong>
                     A
                  </strong>
                  <br/>
                  (informa)
                </title>
                <clause id='AA1'>
                  <title>A.1.</title>
                </clause>
              </annex>
            </clause>
          </sections>
      </iso-standard>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert
      .new({ i18nyaml: "spec/assets/i18n.yaml" }
      .merge(presxml_options))
      .convert("test", input, true)))).to be_equivalent_to xmlpp(output)
  end

  it "ignores casing of xrefs in unicameral scripts" do
    input = <<~INPUT
          <iso-standard xmlns="http://riboseinc.com/isoxml">
          <sections>
          <clause id="A">
          <table id="B">
          </table>
          </clause>
          <clause id="C">
          <p>This is <xref target="A"/> and <xref target="B"/>.
          This is <xref target="A" case="capital"/> and <xref target="B" case="lowercase"/>.
          This is <xref target="A" case="lowercase"/> and <xref target="B" case="capital"/>.
          <xref target="A"/> is clause <em>initial.</em><br/>
          <xref target="A"/> is too.  </p>
          <p><xref target="A"/> is also.</p>
      </clause>
      </sections>
      </iso-standard>
    INPUT
    output = <<~OUTPUT
      <?xml version='1.0'?>
      <iso-standard xmlns='http://riboseinc.com/isoxml' type="presentation">
             <preface><clause type="toc" id="_" displayorder="1"> <title depth="1">Table of contents</title> </clause></preface>
        <sections>
          <clause id='A' displayorder="2">
          <title>1.</title>
            <table id='B'>
              <name>Tabelo 1</name>
            </table>
          </clause>
          <clause id='C' displayorder="3">
          <title>2.</title>
            <p>
              This is
              <xref target='A'>kla&#x16D;zo 1</xref>
               and
              <xref target='B'>tabelo 1</xref>
              . This is
              <xref target='A' case='capital'>kla&#x16D;zo 1</xref>
               and
              <xref target='B' case='lowercase'>tabelo 1</xref>
              . This is
              <xref target='A' case='lowercase'>kla&#x16D;zo 1</xref>
               and
              <xref target='B' case='capital'>tabelo 1</xref>
              .
              <xref target='A'>kla&#x16D;zo 1</xref>
               is clause
              <em>initial.</em>
              <br/>
              <xref target='A'>kla&#x16D;zo 1</xref>
               is too.
            </p>
            <p>
              <xref target='A'>kla&#x16D;zo 1</xref>
               is also.
            </p>
          </clause>
        </sections>
      </iso-standard>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert
      .new({ i18nyaml: "spec/assets/i18n.yaml", script: "Hans" }
      .merge(presxml_options))
      .convert("test", input, true)))).to be_equivalent_to xmlpp(output)
  end

  it "processes add, del" do
    input = <<~INPUT
      <itu-standard xmlns="https://www.calconnect.org/standards/itu">
      <preface>
             <clause type="toc" id="_" displayorder="1"> <title depth="1">Table of contents</title> </clause>
       <foreword id="A">
      <add>ABC <xref target="A"></add> <del><strong>B</strong></del>
      </foreword></preface>
      </itu-standard>
    INPUT
    output = <<~OUTPUT
      #{HTML_HDR}
             <br/>
             <div id='A'>
               <h1 class='ForewordTitle'>Foreword</h1>
               <span class='addition'>
                 ABC
                 <a href='#A'/>
                 <span class='deletion'>
                   <b>B</b>
                 </span>
               </span>
             </div>
             <p class='zzSTDTitle1'/>
           </div>
         </body>
       </html>
    OUTPUT
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
      .convert("test", input, true))).to be_equivalent_to xmlpp(output)
  end

  it "processes formatting in eref/@citeas" do
    input = <<~INPUT
      <itu-standard xmlns="https://www.calconnect.org/standards/itu">
               <preface>
           <foreword id='_' obligation='informative'>
             <title>Foreword</title>
             <p id='_'>
               <eref type='inline' bibitemid='iso124' citeas='[&amp;#x3c;strong&amp;#x3e;A&amp;#x3c;/strong&amp;#x3e;.&amp;#x3c;fn reference=&amp;#x22;1&amp;#x22;&amp;#x3e;&amp;#xa;  &amp;#x3c;p&amp;#x3e;hello&amp;#x3c;/p&amp;#x3e;&amp;#xa;&amp;#x3c;/fn&amp;#x3e;]'/>
             </p>
           </foreword>
         </preface>
      </itu-standard>
    INPUT
    output = <<~OUTPUT
      <itu-standard xmlns='https://www.calconnect.org/standards/itu' type='presentation'>
         <preface>
             <clause type="toc" id="_" displayorder="1"> <title depth="1">Table of contents</title> </clause>
           <foreword id='_' obligation='informative' displayorder='2'>
             <title>Foreword</title>
             <p id='_'>
               <eref type='inline' bibitemid='iso124' citeas='[&amp;#x3c;strong&amp;#x3e;A&amp;#x3c;/strong&amp;#x3e;.&amp;#x3c;fn reference=&amp;#x22;1&amp;#x22;&amp;#x3e;&amp;#xa;  &amp;#x3c;p&amp;#x3e;hello&amp;#x3c;/p&amp;#x3e;&amp;#xa;&amp;#x3c;/fn&amp;#x3e;]'>
                 [
                 <strong>A</strong>
                 .
                 <fn reference='1'>
                   <p>hello</p>
                 </fn>
                 ]
               </eref>
             </p>
           </foreword>
         </preface>
       </itu-standard>
    OUTPUT
    expect(xmlpp(strip_guid(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true)))).to be_equivalent_to xmlpp(output)
  end

  it "combines locality stacks with connectives" do
    input = <<~INPUT
      <itu-standard xmlns="https://www.calconnect.org/standards/itu">
                  <p id='_'>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='from'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='from'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                  <locality type="table">
                    <referenceFrom>2</referenceFrom>
                  </locality>
                  </locality>
                </localityStack>
                text
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>7</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='annex'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='or'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
                text
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='from'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>8</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>10</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
            </p>
          </clause>
        </sections>
        <bibliography>
          <references id='_' normative='false' obligation='informative'>
            <title>Bibliography</title>
            <bibitem id='ref1'>
              <formattedref format='application/x-isodoc+xml'>
                <em>Standard</em>
              </formattedref>
              <docidentifier>XYZ</docidentifier>
            </bibitem>
          </references>
        </bibliography>
      </itu-standard>
    INPUT
    output = <<~OUTPUT
      <itu-standard xmlns="https://www.calconnect.org/standards/itu" type="presentation">
         <p id="_"><eref type="inline" bibitemid="ref1" citeas="XYZ"><localityStack connective="from"><locality type="clause"><referenceFrom>3</referenceFrom></locality></localityStack><localityStack connective="to"><locality type="clause"><referenceFrom>5</referenceFrom></locality></localityStack>XYZ,  Clauses  3 to  5</eref><eref type="inline" bibitemid="ref1" citeas="XYZ"><localityStack connective="from"><locality type="clause"><referenceFrom>3</referenceFrom></locality></localityStack><localityStack connective="to"><locality type="clause"><referenceFrom>5</referenceFrom></locality><locality type="table"><referenceFrom>2</referenceFrom></locality></localityStack>XYZ,  Clause 3 to  Clause 5,  Table 2</eref>
                 text
               </p>
         <eref type="inline" bibitemid="ref1" citeas="XYZ"><localityStack connective="and"><locality type="clause"><referenceFrom>3</referenceFrom></locality></localityStack><localityStack connective="and"><locality type="clause"><referenceFrom>5</referenceFrom></locality></localityStack>XYZ,  Clauses  3 and  5</eref>
         <eref type="inline" bibitemid="ref1" citeas="XYZ"><localityStack connective="and"><locality type="clause"><referenceFrom>3</referenceFrom></locality></localityStack><localityStack connective="and"><locality type="clause"><referenceFrom>5</referenceFrom></locality></localityStack><localityStack connective="and"><locality type="clause"><referenceFrom>7</referenceFrom></locality></localityStack>XYZ,  Clauses  3,  5, and  7</eref>
         <eref type="inline" bibitemid="ref1" citeas="XYZ"><localityStack connective="and"><locality type="clause"><referenceFrom>3</referenceFrom></locality></localityStack><localityStack connective="and"><locality type="annex"><referenceFrom>5</referenceFrom></locality></localityStack>XYZ,  Clause 3 and  Annex 5</eref>
         <eref type="inline" bibitemid="ref1" citeas="XYZ"><localityStack connective="and"><locality type="clause"><referenceFrom>3</referenceFrom></locality></localityStack><localityStack connective="or"><locality type="clause"><referenceFrom>5</referenceFrom></locality></localityStack>
                 text
               </eref>
         <eref type="inline" bibitemid="ref1" citeas="XYZ"><localityStack connective="from"><locality type="clause"><referenceFrom>3</referenceFrom></locality></localityStack><localityStack connective="to"><locality type="clause"><referenceFrom>5</referenceFrom></locality></localityStack><localityStack connective="and"><locality type="clause"><referenceFrom>8</referenceFrom></locality></localityStack><localityStack connective="to"><locality type="clause"><referenceFrom>10</referenceFrom></locality></localityStack>XYZ,  Clauses  3 to  5 and  8 to  10</eref>
       </itu-standard>
    OUTPUT
    expect(xmlpp(IsoDoc::PresentationXMLConvert.new(presxml_options)
      .convert("test", input, true))).to be_equivalent_to xmlpp(output)
  end

  it "ignores locations in xrefs" do
    input = <<~INPUT
      <itu-standard xmlns="https://www.calconnect.org/standards/itu">
      <preface><foreword>
                  <p id='_'>
              <xref target="item_6-4-a"><location target="item_6-4-a" connective="from"/><location target="item_6-4-i" connective="to"/>6.4 List 1.a) to 2.b)</xref>
              </p>
              </foreword></preface>
              </itu-standard>
    INPUT
    html = <<~OUTPUT
      <div><h1 class='ForewordTitle'>Foreword</h1>
          <p id='_'>
            <a href='#item_6-4-a'>6.4 List 1.a) to 2.b)</a>
          </p>
        </div>
    OUTPUT
    doc = <<~OUTPUT
      <div><h1 class='ForewordTitle'>Foreword</h1>
          <p id='_'>
            <a href='#item_6-4-a'>6.4 List 1.a) to 2.b)</a>
          </p>
        </div>
    OUTPUT
    expect(xmlpp(IsoDoc::HtmlConvert.new({})
    .convert("test", input, true))
    .sub(/^.*<h1/m, "<div><h1").sub(%r{</div>.*$}m, "</div>"))
      .to be_equivalent_to xmlpp(html)
    expect(xmlpp(IsoDoc::WordConvert.new({})
      .convert("test", input, true))
      .sub(/^.*<h1/m, "<div><h1").sub(%r{</div>.*$}m, "</div>"))
      .to be_equivalent_to xmlpp(doc)
  end
end
