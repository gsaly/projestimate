require "spec_helper"

describe AdminSetting do
  before :each do
    @admin_setting = FactoryGirl.create(:welcome_message_ad, :key => "test", :value => "test1")
    @proposed_status = FactoryGirl.build(:proposed_status)
  end

  it 'should be valid' do
    @admin_setting.should be_valid
  end

  it "should be not valid without key" do
    @admin_setting.key=""
    @admin_setting.should_not be_valid
  end

  it "should not have duplicated keys" do
    @admin_setting2 = @admin_setting.dup
    @admin_setting2.record_status = @proposed_status
    @admin_setting2.save
    @admin_setting2.should_not be_valid
  end

  it "should be not valid without value" do
    @admin_setting.value=""
    @admin_setting.should_not be_valid
  end


end