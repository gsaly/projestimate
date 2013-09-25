#require "spec_helper"
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MasterDataHelper do

  before :each do
    proposed_status = FactoryGirl.build(:proposed_status, :record_status => nil)
    defined_status = FactoryGirl.build(:defined_status, :record_status => nil)
    in_review_status = FactoryGirl.build(:inReview_status, :record_status => nil)
    draft_status = FactoryGirl.build(:draft_status, :record_status => nil)
    retired_status = FactoryGirl.build(:retired_status, :record_status => nil)
    custom_status = FactoryGirl.build(:custom_status, :record_status => nil)

    @proposed_status = FactoryGirl.build(:proposed_status, :record_status => proposed_status)
    @defined_status = FactoryGirl.build(:defined_status, :record_status => proposed_status)
    @in_review_status = FactoryGirl.build(:inReview_status, :record_status => proposed_status)
    @draft_status = FactoryGirl.build(:draft_status, :record_status => proposed_status)
    @retired_status = FactoryGirl.build(:retired_status, :record_status => proposed_status)
    @custom_status = FactoryGirl.build(:custom_status, :record_status => proposed_status)

    @language = FactoryGirl.create(:en_language)
  end

  specify "records should be valid" do
    @language.should be_valid
  end

  specify "Record should have proposed status on :create" do
    @language.record_status.name.should eql(@proposed_status.name)
  end

  specify "Record should be proposed" do
    @language.record_status = @proposed_status
    @language.is_proposed?.should be_true
  end

  specify "should be defined" do
    @language.record_status = @defined_status
    @language.is_defined?.should be_true
  end

  it "should be inReview" do
    @language.record_status = @in_review_status
    @language.is_inReview?.should be_true
  end

  it "should be drafted" do
    @language.record_status = @draft_status
    @language.is_draft?.should be_true
  end

  it "should be retired" do
    @language.record_status = @retired_status
    @language.is_retired?.should be_true
  end

  it "should be defined or nil" do
    @language.record_status = @defined_status
    @language.is_defined_or_nil?.should be_true
  end

  it "should show custom value if record status is custom" do
    @language.record_status = @custom_status
    @language.custom_value = "Test"
    @language.show_custom_value.should eql(" (Test) ")
  end

end