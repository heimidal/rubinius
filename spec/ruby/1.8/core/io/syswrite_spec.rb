require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
require 'stringio'

describe "IO#syswrite on a file" do
  before :each do
    @filename = "/tmp/IO_syswrite_file" + $$.to_s
    File.open(@filename, "w") do |file|
      file.write("012345678901234567890123456789")
    end
    @file = File.open(@filename, "r+")
  end
  
  after :each do
    @file.close
    File.delete(@filename)
  end
  
  it "writes the given bytes to the file" do
    @file.syswrite("abcde").should == 5
    @file.seek(0)
    @file.sysread(10).should == "abcde56789"
  end
  
  it "invokes to_s on non-String argument" do
    data = "abcdefgh9876"
    (obj = mock(data)).should_receive(:to_s).and_return(data)
    @file.syswrite(obj)
    @file.seek(0)
    @file.sysread(data.length).should == data
  end
  
  it "advances the file position by the count of given bytes" do
    @file.syswrite("abcde")
    @file.sysread(10).should == "5678901234"
  end
  
  it "writes to the actual file position when called after buffered IO#read" do
    @file.read(5)
    @file.syswrite("abcde")
    File.open(@filename) do |file|
      file.sysread(10).should == "01234abcde"
    end
  end
 
  not_compliant_on :rubinius do
    it "warns if called immediately after a buffered IO#write" do
      @file.write("abcde")
      lambda { @file.syswrite("fghij") }.should complain(/syswrite/)
    end
  end
  
  it "does not warn if called after IO#write with intervening IO#sysread" do
    @file.write("abcde")
    @file.sysread(5)
    lambda { @file.syswrite("fghij") }.should_not complain
  end
  
  it "does not warn if called after IO#read" do
    @file.read(5)
    lambda { @file.syswrite("fghij") }.should_not complain
  end
  describe "IO#to_i" do
  it "return the numeric file descriptor of the given IO object" do
    $stdout.to_i.should == 1
  end

  it "raises IOError on closed stream" do
    lambda { IOSpecs.closed_file.syswrite("hello") }.should raise_error(IOError)
  end
end

end
