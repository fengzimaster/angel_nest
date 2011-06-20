require 'spec_helper'

describe StartupsController do
  it_behaves_like "ensure_ownership"
  include_context "inherited_resources"

  authenticates_gets
  authenticates_posts

  let(:startup)      { Startup.make! }
  let(:current_user) { User.make! }
  let(:user)         { User.make! }
  let(:user2)        { User.make! }

  context "index" do
    before do
      2.times { Startup.make!.attach_user(current_user) }
      Startup.make!.attach_user(user)
    end

    it "lists the non-scoped collection" do
      get :index

      collection.count.should == 3
    end

    it "lists the scoped collection" do
      get :index, :user_id => user.id

      collection.count.should == 1
    end

    it "lists the scoped empty collection" do
      get :index, :user_id => user2.id

      collection.count.should == 0
    end

    it "lists the scoped collection for current user" do
      controller.stub(:current_user).and_return(current_user)

      get :my_index

      collection.count.should == 2
    end
  end

  context "CRUD" do
    before do
      startup.attach_user(current_user)
      startup.attach_user(user)
      sign_in_user(current_user)
    end

    hides_sidebar :get, :show
    hides_sidebar :get, :edit

    it "creates a startup profile with a member user attached" do
      post :create, :user_id => current_user.id,
                    :startup => Startup.make.attributes

      startup = Startup.last

      resource.should == startup
      startup.users.first.should == current_user
      startup.users.count.should == 1
    end

    it "edits a startup profile" do
      post :update, :user_id => current_user.id,
                    :id      => startup.id,
                    :startup => startup.attributes.merge(:name => 'Edited Name')

      startup.reload

      resource.should == startup
      startup.name.should == 'Edited Name'
    end

    context "users" do
      it "attaches a user" do
        pending
      end

      it "updates a user" do
        post :update_user, :id => startup.id,
                           :uid => user.id,
                           :attributes => { :member_title => 'CTO' }

        startup.user_meta(user).member_title.should == 'CTO'
      end

      it "detaches a user" do
        post :detach_user, :id => startup.id,
                           :uid => user.id

        startup.reload

        startup.users.include?(user).should == false
      end
    end
  end
end
