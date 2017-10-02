require 'rails_helper'

RSpec.describe DockerManager::AdminController do
  describe 'anonymous user' do
    it 'should redirect to login page' do
      get '/admin/upgrade'

      expect(response.status).to eq(302)
      expect(response).to redirect_to('/login')
    end
  end

  describe 'when user is not an admin' do
    it 'should redirect to login page' do
      sign_in(Fabricate(:user))

      get '/admin/upgrade'

      expect(response.status).to eq(404)
      expect(response.body).to eq(I18n.t('invalid_access'))
    end
  end

  describe 'when user is an admin' do
    it 'should return the right response' do
      sign_in(Fabricate(:admin))

      get '/admin/upgrade'

      expect(response.status).to eq(200)
    end
  end
end
