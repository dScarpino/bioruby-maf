require 'spec_helper'

module Bio
  module MAF

    describe SQLiteIndex do

      describe ".open" do
        it "raises an error on a nonexistent index" do
          expect {
            @idx = SQLiteIndex.open(TestData + 'no_such_file')
          }.to raise_error(/does not exist/)
        end
        it "raises an error on an index without name metadata" do
          expect {
            @idx = SQLiteIndex.open(TestData + 'empty.db')
          }.to raise_error(/not a usable index database/)
        end
        it "raises an error on an index DB without ref seq data" do
          expect {
            @idx = SQLiteIndex.open(TestData + 'mm8_chr7_tiny.nometa.index')
          }.to raise_error(/not a usable index database/)
        end
        it "sets the sequence name correctly" do
          @idx = SQLiteIndex.open(TestData + 'mm8_chr7_tiny.index')
          @idx.sequence.should == "mm8.chr7"
        end
        it "sets the table name correctly" do
          @idx = SQLiteIndex.open(TestData + 'mm8_chr7_tiny.index')
          @idx.table_name.should == "seq_mm8_chr7"
        end
        after(:each) do
          if @idx
            @idx.db.disconnect
          end
        end
      end

      describe "#search" do
        context "mm8_chr7" do
          it "returns a block given a range contained in the block"
          it "returns a block given its range exactly"
          it "returns adjoining blocks given a range partially in each"
          it "returns a block given a range ending in it"
          it "returns a block given a range beginning in it"
          it "returns no blocks given a range outside"
        end
      end

      describe ".build" do
        it "raises an error when trying to build an existing index" do
          expect {
            Bio::MAF::SQLiteIndex.build(nil, TestData + 'empty')
          }.to raise_error(/exists/)
        end
 
        context "mm8_chr7" do
          before(:each) do 
            @p = Parser.new(TestData + 'mm8_chr7_tiny.maf')
            @idx = Bio::MAF::SQLiteIndex.build(@p, ":memory:")
          end
          after(:each) do
            @idx.db.disconnect
          end

          it "uses the first sequence appearing as the reference sequence" do
            @idx.sequence.should == "mm8.chr7"
          end
          it "creates an index table named after the ref sequence" do
            @idx.count_tables("seq_mm8_chr7").should == 1
          end
          it "creates 8 index rows" do
            row = @idx.db.select_one("select count(*) from seq_mm8_chr7")
            count = row[0].to_i
            count.should == 8
          end
          it "creates an index" do
            r = @idx.db.select_one(<<-EOF)
SELECT COUNT(*) FROM sqlite_master
WHERE name = 'idx_seq_mm8_chr7'
AND type = 'index'
EOF
            r[0].to_i.should == 1
          end
        end
      end

      describe "#count_tables" do
        before(:each) do 
          @idx = SQLiteIndex.new(":memory:")
        end
        after(:each) do
          @idx.db.disconnect
        end
        it "reports no tables if none exist" do
          @idx.count_tables("xyzzy").should == 0
        end
        it "reports one table correctly" do
          @idx.db.do("create table abc (a numeric(4) primary key)")
          @idx.count_tables("abc").should == 1
        end
        it "does LIKE queries given a % escape" do
          @idx.db.do("create table abc1 (a numeric(4) primary key)")
          @idx.db.do("create table abc2 (a numeric(4) primary key)")
          @idx.count_tables("abc%").should == 2
        end
      end

      describe "#create_schema" do
        it "creates a metadata table" do
          idx = SQLiteIndex.new(":memory:")
          idx.create_schema
          idx.count_tables("metadata").should == 1
        end
      end

      describe "with mm8_chr7 data" do
        before(:each) do 
          @p = Parser.new(TestData + 'mm8_chr7_tiny.maf')
          @idx = SQLiteIndex.new(":memory:")
          @idx.sequence = "mm8.chr7"
        end
        after(:each) do
          @idx.db.disconnect
        end

        describe "#index_tuple" do
          it "preserves the start and end" do
            block = @p.parse_block
            seq = block.sequences.find { |s| s.source == @idx.sequence }
            tuple = @idx.index_tuple(block)
            tuple[1].should == seq.start
            tuple[2].should == seq.start + seq.size - 1
          end
          it "sets the bin correctly" do
            block = @p.parse_block
            seq = block.sequences.find { |s| s.source == @idx.sequence }
            tuple = @idx.index_tuple(block)
            # TODO: independently check this
            tuple[0].should == 1195
          end
          it "includes the block position" do
            block = @p.parse_block
            seq = block.sequences.find { |s| s.source == @idx.sequence }
            tuple = @idx.index_tuple(block)
            # TODO: independently check this
            tuple[3].should == 16
          end
        end
      end

    end # SQLiteIndex
    
  end # module MAF
  
end # module Bio
