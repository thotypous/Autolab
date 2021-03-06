class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    if user_signed_in?
      if data = request.env["omniauth.auth"]
        # add this authentication object to current user
        if current_user.authentications.where(provider: data["provider"],
                                              uid: data["uid"]).empty?
          current_user.authentications.create(provider: data["provider"],
                                              uid: data["uid"])
        end
      end
      redirect_to(root_path) && return
    else
      @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user)

      if @user
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: "Facebook") if is_navigational_format?
        return
      else
        # automatic cleanup of devise.* after sign in
        session["devise.facebook_data"] = request.env["omniauth.auth"].except("extra")
        redirect_to(new_user_registration_url) && return
      end
    end
  end

  def google_oauth2
    if user_signed_in?
      if data = request.env["omniauth.auth"]
        if current_user.authentications.where(provider: data["provider"],
                                              uid: data["uid"]).empty?
          current_user.authentications.create(provider: data["provider"],
                                              uid: data["uid"])
        end
      end
      redirect_to root_path
    else
      @user = User.find_for_google_oauth2_oauth(request.env["omniauth.auth"], current_user)

      if @user
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: "Google_OAuth2") if is_navigational_format?
      else
        # automatic cleanup of devise.* after sign in
        session["devise.google_oauth2_data"] = request.env["omniauth.auth"].except("extra")
        redirect_to new_user_registration_url
      end
    end
  end

  def shibboleth
    if user_signed_in?
      if data = request.env["omniauth.auth"]
        if current_user.authentications.where(provider: "CMU-Shibboleth",
                                              uid: data["uid"]).empty?
          current_user.authentications.create(provider: "CMU-Shibboleth",
                                              uid: data["uid"])
        end
      end
      redirect_to root_path
    else
      @user = User.find_for_shibboleth_oauth(request.env["omniauth.auth"], current_user)

      if @user
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: "Shibboleth") if is_navigational_format?
      else
        # Skip sign up for CMU Shibboleth user
        data = request.env["omniauth.auth"]

        @user = User.new
        @user.email = data["info"]["email"]  # will fail if email is already taken
        @user.first_name = data["info"]["name"]
        @user.last_name = data["info"]["last_name"]

        # If info not provided by Shibboleth, use (blank) as place holder
        @user.first_name = "(blank)" if @user.first_name.nil?
        @user.last_name = "(blank)" if @user.last_name.nil?

        temp_pass = Devise.friendly_token[0, 20]    # generate a random token
        @user.password = temp_pass
        @user.password_confirmation = temp_pass
        @user.skip_confirmation!

        @user.authentications.new(provider: "CMU-Shibboleth",
                                  uid: data["uid"])
        @user.save!
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: "Shibboleth") if is_navigational_format?
      end
    end
  end
end
