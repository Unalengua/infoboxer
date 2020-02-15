require 'infoboxer/parser'

module Infoboxer
  describe Parser, 'tables' do
    let(:ctx) { Parser::Context.new(unindent(source)) }
    let(:parser) { Parser.new(ctx) }

    let(:nodes) { parser.paragraphs }
    let(:table) { nodes.first }

    subject { table }

    describe 'simplest: one cell, one row' do
      let(:source) {
        %{{|
        |one
        |}}
      }

      it { is_expected.to be_a(Tree::Table) }
      its(:'rows.count') { is_expected.to eq 1 }
      it 'should contain text' do
        expect(subject.rows.first.cells.first.children).to eq \
          [Tree::Text.new('one')]
      end
    end

    describe 'multiple cells' do
      let(:table) { nodes.first }
      let(:cells) { table.rows.first.cells }

      subject { cells }

      context 'all cells in one line' do
        let(:source) {
          %{
          {|
          |one||two||three: it's a long text, dude!
          |}
        }}

        its(:count) { is_expected.to eq 3 }
        it 'should preserve text' do
          expect(subject.map(&:text)).to eq ['one', 'two', "three: it's a long text, dude!"]
        end
      end

      context 'cells on separate lines' do
        let(:source) {
          %{
          {|
          |one||two
          |three: it's a long text, dude!||and four
          |}
        }}

        its(:count) { is_expected.to eq 4 }
        it 'should preserve text' do
          expect(subject.map(&:text)).to eq \
            ['one', 'two', "three: it's a long text, dude!", 'and four']
        end
      end

      context 'multiline cells' do
        let(:source) {
          %{
          {|
          |one||two
          three: it's a long text, dude!||and four
          |}
        }}

        its(:count) { is_expected.to eq 2 }
        describe 'last cell' do
          subject { cells.last }

          it 'should do bad things with next lines!' do
            expect(subject.children.map(&:class)).to eq \
              [Tree::Text, Tree::Paragraph]
            expect(subject.children.map(&:text)).to eq \
              ['two', "three: it's a long text, dude!||and four\n\n"]
          end
        end
      end

      context 'multiline with template' do
        let(:source) {
          %{
          {|
          |one||two {{template
          |it's content}}
          |}
        }}

        its(:count) { is_expected.to eq 2 }
        describe 'last cell' do
          subject { cells.last }

          it 'should do bad things with next lines!' do
            expect(subject.children.map(&:class)).to eq \
              [Tree::Text, Templates::Base]
          end
        end
      end
    end

    describe 'multiple rows' do
      let(:source) {
        %{
        {|
        |one
        |-
        |two
        |}
      }}

      its(:"rows.count") { is_expected.to eq 2 }
      it 'should preserve texts' do
        expect(subject.rows.map(&:text)).to eq %w[one two]
      end

      context 'row-level template' do
        let(:source) {
          %{
          {|
          |one
          |-
          {{!}}
          |}
        }}

        subject { table.rows.last.children.first.children.first }

        it { is_expected.to be_a(Tree::Template) }
      end

      context 'row-level template' do
        let(:source) {
          %{
          {|
          |one
          |-
          {{!}}
          x
          |}
        }}

        subject { table.rows.last.children.last.children }

        it { is_expected.to contain_exactly(Tree::Template, Tree::Paragraph) }
      end
    end

    describe 'headings' do
      context 'in first row' do
        let(:source) {
          %{
          {|
          ! one
          ! two
          ! three
          |}
        }}

        subject { table.rows.first.children }

        its(:count) { is_expected.to eq 3 }
        it 'should be headers' do
          expect(subject.map(&:class)).to eq \
            [Tree::TableHeading, Tree::TableHeading, Tree::TableHeading]
        end
      end

      context 'in next row' do
        let(:source) {
          %{
          {|
          |wtf
          |-
          ! one
          ! two
          ! three
          |}
        }}

        subject { table.rows[1].children }

        its(:count) { is_expected.to eq 3 }
        it 'should be headers' do
          expect(subject.map(&:class)).to eq \
            [Tree::TableHeading, Tree::TableHeading, Tree::TableHeading]
        end
      end

      context 'several headers in line' do
        let(:source) {
          %{
          {|
          ! one||two||three
          |}
        }}

        subject { table.rows.first.children }

        its(:count) { is_expected.to eq 3 }
        it 'should be headers' do
          expect(subject.map(&:class)).to eq \
            [Tree::TableHeading, Tree::TableHeading, Tree::TableHeading]
        end
      end

      context 'several headers in line -header separator' do
        let(:source) {
          %{
          {|
          ! one!!two!!three
          |}
        }}

        subject { table.rows.first.children }

        its(:count) { is_expected.to eq 3 }
        it 'should be headers' do
          expect(subject.map(&:class)).to eq \
            [Tree::TableHeading, Tree::TableHeading, Tree::TableHeading]
        end
      end

      context 'in the middle of a row' do
        let(:source) {
          %{
          {|
          | one
          ! two
          | three
          |}
        }}

        subject { table.rows.first.children }

        its(:count) { is_expected.to eq 3 }
        it 'should be headers' do
          expect(subject.map(&:class)).to eq \
            [Tree::TableCell, Tree::TableHeading, Tree::TableCell]
        end
      end
    end

    describe 'table caption' do
      subject { table.caption }

      context 'simple' do
        let(:source) {
          %{
          {|
          |+ test me
          |}
        }}

        it { is_expected.to be_a(Tree::TableCaption) }
        its(:text) { is_expected.to eq 'test me' }
      end

      context 'with formatting' do
        let(:source) {
          %{
          {|
          |+ test me ''please'' [[here]]
          |}
        }}

        it { is_expected.to be_a(Tree::TableCaption) }
        it 'should be formatted' do
          expect(subject.children.map(&:class)).to eq \
            [Tree::Text, Tree::Italic, Tree::Text, Tree::Wikilink]
        end
      end

      context 'multiline' do
        let(:source) {
          %{
          {|
          |+ test me
          please
          |}
        }}

        it { is_expected.to be_a(Tree::TableCaption) }
        its(:text) { is_expected.to eq "test me\nplease" }
      end

      # seems to be pretty exotic one, in fact.
      # neglect it (implementation anyways was dumb)
      xcontext 'with tag' do
        let(:source) {
          %{
          {|
          <caption>test me please</caption>
          |}
        }}

        it { is_expected.to be_a(Tree::TableCaption) }
        its(:text) { is_expected.to eq "test me please\n\n" }
      end

      context 'with style params' do
        let(:source) {
          %{
          {|
          |+ style="color: green;"|test me
          |}
        }}

        it { is_expected.to be_a(Tree::TableCaption) }
        its(:text) { is_expected.to eq 'test me' }
        its(:params) { are_expected.to eq(style: 'color: green;') }
      end

      context 'cells after' do
        let(:source) {
          %{
          {|
          |+ test me
          !Header
          |}
        }}

        it { is_expected.to be_a(Tree::TableCaption) }
        its(:text) { is_expected.to eq 'test me' }

        specify { expect(table.rows.count).to eq 1 }
      end
    end

    describe 'table-level params' do
      let(:source) {
        %{
        {| border="1" style="border-collapse:collapse;"
        |}
      }}

      subject { table.params }

      it { is_expected.to be_kind_of(Hash) }
      its(:keys) { are_expected.to contain_exactly(:border, :style) }
      its(:values) {
        are_expected.to \
          contain_exactly('1', 'border-collapse:collapse;')
      }
    end

    describe 'row-level params' do
      let(:source) {
        %{
        {|
        |- border="1" style="border-collapse:collapse;"
        |test
        |}
      }}

      subject { table.rows.first.params }

      it { is_expected.to be_kind_of(Hash) }
      its(:keys) { are_expected.to contain_exactly(:border, :style) }
      its(:values) {
        are_expected.to \
          contain_exactly('1', 'border-collapse:collapse;')
      }
    end

    describe 'cell-level params' do
      context 'when first' do
        let(:source) {
          %{
          {|
          | style="text-align:right;" |test
          |}
        }}

        subject { table.rows.first.cells.first.params }

        it { is_expected.to be_kind_of(Hash) }
        its(:keys) { are_expected.to contain_exactly(:style) }
        its(:values) {
          are_expected.to \
            contain_exactly('text-align:right;')
        }
      end

      context 'when several' do
        let(:source) {
          %{
          {|
          | style="text-align:right;" |test||border|one
          |}
        }}

        subject { table.rows.first.cells[1].params }

        it { is_expected.to be_kind_of(Hash) }
        its(:keys) { are_expected.to contain_exactly(:border) }
        its(:values) {
          are_expected.to \
            contain_exactly('border')
        }
      end

      context 'when uneven quotes' do
        # Example like this can be found at https://en.wikipedia.org/wiki/Chevrolet_Volt_(second_generation)
        let(:source) {
          %{
          {|
          | style="text-align:right; |test||border|one
          |}
        }}

        subject { table.rows.first.cells[1].params }

        it { is_expected.to be_kind_of(Hash) }
        its(:keys) { are_expected.to contain_exactly(:border) }
        its(:values) {
          are_expected.to \
            contain_exactly('border')
        }
      end
    end

    describe 'nested tables, damn them' do
      context 'when in empty cell' do
        let(:source) {
          %{
          {| style="width:98%; background:none;"
          |-
          |
          {| style="width:98%; background:none;"
          |-
          |test me
          |}
          |}
        }}

        subject { table.rows.first.cells.first.children.first }

        it { is_expected.to be_kind_of(Tree::Table) }
      end

      context 'when in multiline cell' do
        let(:source) {
          %{
          {| style="width:98%; background:none;"
          |-
          | some
          things
          complicated
          {| style="width:98%; background:none;"
          |-
          |test me
          |}
          |}
        }}

        it 'should still be reasonable!' do
          expect(table.rows.first.cells.count).to eq 1
          expect(table.rows.first.cells.first.children.last).to \
            be_a(Tree::Table)
          expect(table.rows.first.cells.first.children.map(&:class)).to \
            include(Tree::Paragraph)
        end
      end
    end

    describe 'implicitly closed table' do
      let(:source) {
        %[
        {|

        That's paragraph!
      ]
      }

      it 'works' do
        expect(table.rows).to be_empty
        expect(nodes.last).to eq Tree::Paragraph.new(Tree::Text.new("That's paragraph!"))
      end

      context 'not closed on empty lines' do
        let(:source) {
          %[
          {|

          |Still a cell!
        ]
        }

        subject { table.rows.first.cells.first }

        its(:text) { is_expected.to eq 'Still a cell!' }
      end
    end

    describe 'tables, Karl!' do
      # From
      # http://en.wikipedia.org/wiki/Comparison_of_relational_database_management_systems#General_information
      let(:source) { File.read('spec/fixtures/large_table.txt') }

      its(:"rows.count") { is_expected.to eq 61 }
      it 'should be cool' do
        expect(subject.rows.map(&:children).map(&:count)).to all(be > 1)
      end
    end

    describe 'broken table definition (issue #78)' do
      let(:source) {
        %[
          {|
           |+ ''A'' |
           ! B
          |}
        ]
      }

      its(:"rows.count") { is_expected.to eq 1 }
      its(:caption) { is_expected.to be_nil } # empty node, in fact
    end

    describe 'large broken table definition (issue #78)' do
      let(:source) { File.read('spec/fixtures/broken_table_caption.txt') }

      its(:"rows.count") { is_expected.to eq 1 }
      its(:caption) { is_expected.not_to be_nil } # we parse too complicated params as caption text... it is OK, table's broken anyways :)
    end

    describe 'auto-closing of tables (issue #81)' do
      let(:source) {
        %[
          {|
           |-
           |Text.
          ==Heading==
        ]
      }

      subject { nodes }

      it {
        is_expected.to contain_exactly(
          be_a(Tree::Table),
          be_a(Tree::Heading).and(have_attributes(text: "Heading\n\n"))
        )
      }
    end
  end
end
