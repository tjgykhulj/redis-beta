require File.dirname(__FILE__) + '/spec_helper'

describe "redis" do
  before do
    @r = Redis.new
    @r.select_db(15) # use database 15 for testing so we dont accidentally step on you real data
    @r['foo'] = 'bar'
  end  
  
  after do
    @r.keys('*').each {|k| @r.delete k }
  end  
  
  it "should be able to GET a key" do
    @r['foo'].should == 'bar'
  end
  
  it "should be able to SET a key" do
    @r['foo'] = 'nik'
    @r['foo'].should == 'nik'
  end
  
  it "should be able to SETNX(set_unless_exists)" do
    @r['foo'] = 'nik'
    @r['foo'].should == 'nik'
    @r.set_unless_exists 'foo', 'bar'
    @r['foo'].should == 'nik'
  end
  
  it "should be able to INCR(increment) a key" do
    @r.delete('counter')
    @r.incr('counter').should == 1
    @r.incr('counter').should == 2
    @r.incr('counter').should == 3
  end
  
  it "should be able to DECR(decrement) a key" do
    @r.delete('counter')
    @r.incr('counter').should == 1
    @r.incr('counter').should == 2
    @r.incr('counter').should == 3
    @r.decr('counter').should == 2
    @r.decr('counter').should == 1
    @r.decr('counter').should == 0
  end
  
  it "should be able to RANDKEY(return a random key)" do
    @r.randkey.should_not be_nil
  end
  
  it "should be able to RENAME a key" do
    @r.delete 'foo'
    @r.delete 'bar'
    @r['foo'] = 'hi'
    @r.rename! 'foo', 'bar'
    @r['bar'].should == 'hi'
  end
  
  it "should be able to RENAMENX(rename unless the new key already exists) a key" do
    @r.delete 'foo'
    @r.delete 'bar'
    @r['foo'] = 'hi'
    @r['bar'] = 'ohai'
    lambda {@r.rename 'foo', 'bar'}.should raise_error(RedisError)
    @r['bar'].should == 'ohai'
  end
  
  it "should be able to EXISTS(check if key exists)" do
    @r['foo'] = 'nik'
    @r.key?('foo').should be_true
    @r.delete 'foo'
    @r.key?('foo').should be_false
  end
  
  it "should be able to KEYS(glob for keys)" do
    @r.keys("f*").each do |key|
      @r.delete key
    end  
    @r['f'] = 'nik'
    @r['fo'] = 'nak'
    @r['foo'] = 'qux'
    @r.keys("f*").sort.should == ['f','fo', 'foo'].sort
  end
  
  it "should be able to check the TYPE of a key" do
    @r['foo'] = 'nik'
    @r.type?('foo').should == "string"
    @r.delete 'foo'
    @r.type?('foo').should == "none"
  end
  
  it "should be able to push to the head of a list" do
    @r.push_head "list", 'hello'
    @r.type?('list').should == "list"
    @r.list_length('list').should == 1
    @r.delete('list')
  end
  
  it "should be able to push to the tail of a list" do
    @r.push_tail "list", 'hello'
    @r.type?('list').should == "list"
    @r.list_length('list').should == 1
    @r.delete('list')
  end
  
  it "should be able to pop the tail of a list" do
    @r.push_tail "list", 'hello'
    @r.push_tail "list", 'goodbye'
    @r.type?('list').should == "list"
    @r.list_length('list').should == 2
    @r.pop_tail('list').should == 'goodbye'
    @r.delete('list')
  end
  
  it "should be able to pop the head of a list" do
    @r.push_tail "list", 'hello'
    @r.push_tail "list", 'goodbye'
    @r.type?('list').should == "list"
    @r.list_length('list').should == 2
    @r.pop_head('list').should == 'hello'
    @r.delete('list')
  end
  
  it "should be able to get the length of a list" do
    @r.push_tail "list", 'hello'
    @r.push_tail "list", 'goodbye'
    @r.type?('list').should == "list"
    @r.list_length('list').should == 2
    @r.delete('list')
  end
  
  it "should be able to get a range of values from a list" do
    @r.push_tail "list", 'hello'
    @r.push_tail "list", 'goodbye'
    @r.push_tail "list", '1'
    @r.push_tail "list", '2'
    @r.push_tail "list", '3'
    @r.type?('list').should == "list"
    @r.list_length('list').should == 5
    @r.list_range('list', 2, -1).should == ['1', '2', '3']
    @r.delete('list')
  end

  it "should be able to trim a list" do
    @r.push_tail "list", 'hello'
    @r.push_tail "list", 'goodbye'
    @r.push_tail "list", '1'
    @r.push_tail "list", '2'
    @r.push_tail "list", '3'
    @r.type?('list').should == "list"
    @r.list_length('list').should == 5
    @r.list_trim 'list', 0, 1
    @r.list_length('list').should == 2
    @r.list_range('list', 0, -1).should == ['hello', 'goodbye']
    @r.delete('list')
  end
  
  it "should be able to get a value by indexing into a list" do
    @r.push_tail "list", 'hello'
    @r.push_tail "list", 'goodbye'
    @r.type?('list').should == "list"
    @r.list_length('list').should == 2
    @r.list_index('list', 1).should == 'goodbye'
    @r.delete('list')
  end
  
  it "should be able to set a value by indexing into a list" do
    @r.push_tail "list", 'hello'
    @r.push_tail "list", 'hello'
    @r.type?('list').should == "list"
    @r.list_length('list').should == 2
    @r.list_set('list', 1, 'goodbye').should be_true
    @r.list_index('list', 1).should == 'goodbye'
    @r.delete('list')
  end
  
  it "should be able add members to a set" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.type?('set').should == "set"
    @r.set_count('set').should == 2
    @r.set_members('set').sort.should == ['key1', 'key2'].sort
    @r.delete('set')
  end
  
  it "should be able delete members to a set" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.type?('set').should == "set"
    @r.set_count('set').should == 2
    @r.set_members('set').sort.should == ['key1', 'key2'].sort
    @r.set_delete('set', 'key1')
    @r.set_count('set').should == 1
    @r.set_members('set').sort.should == ['key2'].sort
    @r.delete('set')
  end
  
  it "should be able count the members of a set" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.type?('set').should == "set"
    @r.set_count('set').should == 2
    @r.delete('set')
  end
  
  it "should be able test for set membership" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.type?('set').should == "set"
    @r.set_count('set').should == 2
    @r.set_member?('set', 'key1').should be_true
    @r.set_member?('set', 'key2').should be_true
    @r.set_member?('set', 'notthere').should be_false
    @r.delete('set')
  end
  
  it "should be able to do set intersection" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.set_add "set2", 'key2'
    @r.set_intersect('set', 'set2').should == ['key2']
    @r.delete('set')
  end
end