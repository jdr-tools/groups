RSpec.describe Controllers::Groups do

  before do
    DatabaseCleaner.clean
  end

  let!(:group) { create(:group) }
  let!(:category) { create(:category) }
  let!(:account) { create(:account) }
  let!(:right) {
    tmp_right = create(:right, category: category)
    tmp_right.groups << group
    tmp_right.save
    tmp_right
  }
  let!(:application) { create(:application, creator: account) }
  let!(:gateway) { create(:gateway) }
  let!(:service) { create(:service) }

  def app
    Controllers::Groups.new
  end

  describe 'GET /' do
    describe 'nominal case' do
      before do
        get '/groups', {app_key: 'test_key', token: 'test_token'}
      end
      it 'Returns a OK (200) status code when querying for the list of groups' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body for the list of groups' do
        expect(JSON.parse(last_response.body)).to eq({
          'count' => 1,
          'items' => [
            {
              'id' => group.id.to_s,
              'slug' => 'test_group',
              'is_default' => false,
              'rights' => 1,
              'routes' => 0
            }
          ]
        })
      end
    end

    it_should_behave_like 'a route', 'get', '/groups'
  end

  describe 'GET /:id' do
    describe 'nominal case' do
      before do
        get "/groups/#{group.id}", {app_key: 'test_key', token: 'test_token'}
      end
      it 'Returns a OK (200) status code when querying for the list of groups' do
        expect(last_response.status).to be 200
      end
      it 'returns the correct body for the list of groups' do
        expect(JSON.parse(last_response.body)).to eq({
          'id' => group.id.to_s,
          'slug' => 'test_group',
          'is_default' => false,
          'rights' => [right.id.to_s],
          'routes' => []
        })
      end
    end

    it_should_behave_like 'a route', 'get', '/groups/group_id'

    describe 'not_found errors' do
      describe 'group not found' do
        before do
          get '/groups/anything_but_existing_group', {app_key: 'test_key', token: 'test_token'}
        end
        it 'Raises a not found (404) error when the group does not exist' do
          expect(last_response.status).to be 404
        end
        it 'returns the correct body when the group doesn\'t exist' do
          expect(JSON.parse(last_response.body)).to eq({
            'status' => 404,
            'field' => 'group_id',
            'error' => 'unknown',
            'docs' => 'https://github.com/jdr-tools/wiki/wiki/Groups-API#group-id-not-found'
          })
        end
      end
    end
  end

  describe 'POST /' do
    describe 'Nominal case' do
      before do
        post '/groups', {app_key: 'test_key', token: 'test_token', slug: 'other_group'}
      end
      it 'gives the correct status code when successfully creating a right' do
        expect(last_response.status).to be 201
      end
      it 'returns the correct body when the right is successfully created' do
        expect(last_response.body).to include_json({
          message: 'created',
          item: {
            slug: 'other_group',
            is_default: false,
            rights: 0,
            routes: 0
          }
        })
      end
      describe 'created group attributes' do
        let!(:created_group) { Arkaan::Permissions::Group.last }
        it 'has the correct slug' do
          expect(created_group.slug).to eq 'other_group'
        end
        it 'is not a default group' do
          expect(created_group.is_default).to be false
        end
      end
    end

    describe 'Alternative cases' do
      describe 'When the is_default flag is given to false' do
        before do
          post '/groups', {app_key: 'test_key', token: 'test_token', slug: 'other_group', is_default: false}
        end
        it 'returns a 201 (Created) status' do
          expect(last_response.status).to be 201
        end
        it 'returns the correct body' do
          expect(last_response.body).to include_json({
            message: 'created',
            item: {
              slug: 'other_group',
              is_default: false,
              routes: 0,
              rights: 0
            }
          })
        end
        describe 'created group attributes' do
          let!(:created_group) { Arkaan::Permissions::Group.last }
          it 'has the correct slug' do
            expect(created_group.slug).to eq 'other_group'
          end
          it 'is not a default group' do
            expect(created_group.is_default).to be false
          end
        end
      end
      describe 'When the is_default flag is given to true' do
        before do
          post '/groups', {app_key: 'test_key', token: 'test_token', slug: 'other_group', is_default: true}
        end
        it 'returns a 201 (Created) status' do
          expect(last_response.status).to be 201
        end
        it 'returns the correct body' do
          expect(last_response.body).to include_json({
            message: 'created',
            item: {
              slug: 'other_group',
              is_default: true,
              routes: 0,
              rights: 0
            }
          })
        end
        describe 'created group attributes' do
          let!(:created_group) { Arkaan::Permissions::Group.last }
          it 'has the correct slug' do
            expect(created_group.slug).to eq 'other_group'
          end
          it 'is a default group' do
            expect(created_group.is_default).to be true
          end
        end
      end
    end

    it_should_behave_like 'a route', 'post', '/groups'

    describe 'Bad request errors' do
      describe 'already existing slug error' do
        before do
          post '/groups', {app_key: 'test_key', token: 'test_token', slug: 'test_group'}
        end
        it 'gives the correct status code when creating a right with an already existing slug' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body when creating a right with an already existing slug' do
          expect(JSON.parse(last_response.body)).to eq({
            'status' => 400,
            'field' => 'slug',
            'error' => 'uniq',
            'docs' => 'https://github.com/jdr-tools/wiki/wiki/Groups-API#slug-already-taken'
          })
        end
      end

      describe 'slug not given error' do
        before do
          post '/groups', {app_key: 'test_key', token: 'test_token'}
        end
        it 'Raises a bad request (400) error when the parameters don\'t contain the slug' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct response if the parameters do not contain a slug' do
          expect(JSON.parse(last_response.body)).to eq({
            'status' => 400,
            'field' => 'slug',
            'error' => 'required',
            'docs' => 'https://github.com/jdr-tools/wiki/wiki/Groups-API#slug-not-given'
          })
        end
      end
    end
  end

  describe 'DELETE /:id' do
    describe 'nominal case' do
      before do
        delete "/groups/#{group.id}", {app_key: 'test_key', token: 'test_token'}
      end
      it 'Returns a OK (200) status code when deleting a group' do
        expect(last_response.status).to be 200
      end
      it 'efficiently suppresses the group from the list of groups' do
        expect(Arkaan::Permissions::Group.where(id: group.id).first).to be nil
      end
    end

    it_should_behave_like 'a route', 'delete', '/groups/group_id'

    describe 'not_found errors' do
      describe 'group not found' do
        before do
          delete '/groups/anything_but_existing_group', {app_key: 'test_key', token: 'test_token'}
        end
        it 'Raises a not found (404) error when the group does not exist' do
          expect(last_response.status).to be 404
        end
        it 'returns the correct body when the group doesn\'t exist' do
          expect(JSON.parse(last_response.body)).to eq({
            'status' => 404,
            'field' => 'group_id',
            'error' => 'unknown',
            'docs' => 'https://github.com/jdr-tools/wiki/wiki/Groups-API#group-id-not-found-3'
          })
        end
      end
    end
  end

  describe 'PUT /:id' do
    it_should_behave_like 'a route', 'put', '/groups/group_id'

    describe 'Not found errors' do
      describe 'group not found' do
        before do
          put "/groups/any_unknown_group", {token: 'test_token', app_key: 'test_key'}
        end
        it 'Raises a not found (404) error when the group does not exist' do
          expect(last_response.status).to be 404
        end
        it 'returns the correct body if the group does not exist' do
          expect(last_response.body).to include_json(
            status: 404,
            field: 'group_id',
            error: 'unknown'
          )
        end
      end
    end

    describe 'When updating attributes' do
      before do
        put "/groups/#{group.id}", {token: 'test_token', app_key: 'test_key', slug: 'new_slug', is_default: true}
        group.reload
      end
      it 'Returns a OK (200) response code' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json(
          message: 'updated',
          item: {
            id: group.id.to_s,
            is_default: true,
            slug: 'new_slug'
          }
        )
      end
      it 'Has updated the slug correctly' do
        expect(group.slug).to eq('new_slug')
      end
      it 'Has updated the default flag correctly' do
        expect(group.is_default).to be true
      end
    end

    describe 'When updating the rights' do
      describe 'nominal case' do
        let!(:other_group) { create(:other_group, slug: 'other_slug_group') }
        let!(:other_right) { create(:right, slug: 'other_slug_right', category: category) }
        before do
          put "/groups/#{other_group.id.to_s}", {token: 'test_token', app_key: 'test_key', rights: [right.id.to_s]}
        end
        it 'Returns a OK (200) response code if the right has successfully been appended to the group' do
          expect(last_response.status).to be 200
        end
        it 'returns the correct body if the right has successfully been appended' do
          expect(last_response.body).to include_json(message: 'updated')
        end
        it 'has linked one right to the group' do
          expect(other_group.reload.rights.count).to be 1
        end
        it 'has linked the right right to the group' do
          expect(other_group.reload.rights.first.slug).to eq 'test_right'
        end
        describe 'overwriting the rights in a group' do
          before do
            put "/groups/#{other_group.id.to_s}", {token: 'test_token', app_key: 'test_key', rights: [other_right.id.to_s]}
          end
          it 'Returns a OK (200) response code when overwriting the rights' do
            expect(last_response.status).to be 200
          end
          it 'returns the correct body when overwriting the rights' do
            expect(last_response.body).to include_json(message: 'updated')
          end
          it 'has overwritten the rights associated to the group' do
            expect(other_group.reload.rights.count).to be 1
          end
          it 'has changed the right attached to this group' do
            expect(other_group.reload.rights.first.slug).to eq 'other_slug_right'
          end
        end
      end

      describe 'Not Found errors' do
        describe 'one of the rights has not been found' do
          let!(:other_group) { create(:other_group, slug: 'other_slug_group') }
          before do
            put "/groups/#{other_group.id.to_s}", {token: 'test_token', app_key: 'test_key', rights: [right.id.to_s, 'any_other_right']}
          end
          it 'Raises a not found (404) error when a right unique identifier is not found' do
            expect(last_response.status).to be 404
          end
          it 'returns the correct body if a right is not found' do
            expect(last_response.body).to include_json(
              status: 404,
              field: 'right_id',
              error: 'unknown'
            )
          end
          it 'has not associated a right with the given group' do
            expect(other_group.rights.count).to be 0
          end
        end
      end
    end

    describe 'When updating the routes' do
      let!(:route) { create(:route, service: service) }

      describe 'nominal case' do
        let!(:other_group) { create(:other_group, slug: 'other_slug_group') }
        before do
          put "/groups/#{other_group.id.to_s}", {token: 'test_token', app_key: 'test_key', routes: [route.id.to_s]}
        end
        it 'Returns a OK (200) response code if the route has successfully been appended to the group' do
          expect(last_response.status).to be 200
        end
        it 'returns the correct body if the route has successfully been appended' do
          expect(last_response.body).to include_json(message: 'updated')
        end
        it 'has linked one route to the group' do
          expect(other_group.reload.routes.count).to be 1
        end
        it 'has linked the right route to the group' do
          expect(other_group.reload.routes.first.path).to eq '/route'
        end
        describe 'overwriting the rights in a group' do
          before do
            put "/groups/#{other_group.id.to_s}", {token: 'test_token', app_key: 'test_key', routes: [route.id.to_s]}
          end
          it 'Returns a OK (200) response code when overwriting the rights' do
            expect(last_response.status).to be 200
          end
          it 'returns the correct body when overwriting the rights' do
            expect(last_response.body).to include_json({message: 'updated'})
          end
          it 'has overwritten the routes associated to the group' do
            expect(other_group.reload.routes.count).to be 1
          end
          it 'has changed the route attached to this group' do
            expect(other_group.reload.routes.first.path).to eq '/route'
          end
        end
      end

      describe 'Not Found errors' do
        describe 'one of the routes has not been found' do
          let!(:other_group) { create(:other_group, slug: 'other_slug_group') }
          before do
            put "/groups/#{other_group.id.to_s}", {token: 'test_token', app_key: 'test_key', routes: [route.id.to_s, 'any_other_route']}
          end
          it 'Raises a not found (404) error when a route unique identifier is not found' do
            expect(last_response.status).to be 404
          end
          it 'returns the correct body if a route is not found' do
            expect(last_response.body).to include_json(
              status: 404,
              field: 'route_id',
              error: 'unknown'
            )
          end
          it 'has not associated a route with the given group' do
            expect(other_group.routes.count).to be 0
          end
        end
      end
    end
  end
end