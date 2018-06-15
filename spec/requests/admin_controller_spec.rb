require 'rails_helper'

RSpec.describe DockerManager::AdminController do
  describe 'anonymous user' do
    it 'should be a 404' do
      get '/admin/upgrade'

      expect(response.status).to eq(404)
    end
  end

  describe 'when user is not an admin' do
    it 'should 404' do
      sign_in(Fabricate(:user))

      get '/admin/upgrade'
      expect(response.status).to eq(404)
    end
  end

  describe 'when user is an admin' do
    it 'should return the right response' do
      sign_in(Fabricate(:admin))

      get '/admin/upgrade'
      expect(response.status).to eq(200)
    end
  end

  describe '#repos' do
    it 'should return the right response' do
      sign_in(Fabricate(:admin))

      get '/admin/docker/repos'
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body["repos"].first["official"]).to eq(false)
    end
  end
end
