require "spec_helper"

describe Component do

  before :each do
    @component = Component.first
    @c1 = Component.new(:name => "C1")
    @c2 = Component.new(:name => "C1")
  end

  it 'should be valid' do
    @component.should be_valid
  end

  it 'should have a correct type' do
    @component.folder?.should be_true
  end
end
