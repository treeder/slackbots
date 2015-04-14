# This is abstracted into it's own class so you could swap it out for any other datastore without having to change the bot.

require 'google/api_client'

class GoogleDatastore

  attr_accessor :config, :dataset_id, :datastore, :client

  def initialize(gconfig)
    @config = gconfig
    # Same as project_id
    @dataset_id = gconfig.project_id

    # Google::APIClient.logger.level = Logger::INFO
    gclient = Google::APIClient.new(:application_name => 'Slacker', :application_version => '1.0.0')
    @datastore = gclient.discovered_api('datastore', 'v1beta2')

    # Load our credentials for the service account
    key = Google::APIClient::KeyUtils.load_from_pkcs12("gkey.p12", "notasecret")

    # Set authorization scopes and credentials.
    gclient.authorization = Signet::OAuth2::Client.new(
        :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
        :audience => 'https://accounts.google.com/o/oauth2/token',
        :scope => ['https://www.googleapis.com/auth/datastore',
                   'https://www.googleapis.com/auth/userinfo.email'],
        :issuer => gconfig.service_account_id,
        :signing_key => key)

    # Authorize the client.
    puts "authorizing to google..."
    gclient.authorization.fetch_access_token!

    @client = gclient

  end

  def lckey
    return {:path => [{:kind => 'CheckDates', :name => 'last_check'}]} # this name should be unique per user
  end

  # Returns the last date we checked Salesforce
  def get_last_check

    resp = client.execute(
        :api_method => datastore.datasets.lookup,
        :parameters => {:datasetId => dataset_id},
        :body_object => {
            # Set the transaction, so we get a consistent snapshot of the
            # value at the time the transaction started.
            # :readOptions => {:transaction => tx},
            # Add one entity key to the lookup request, with only one
            # :path element (i.e. no parent)
            :keys => [lckey]
        })
    if !resp.data.found.empty?
      # Get the entity from the response if found.
      entity = resp.data.found[0].entity
      puts "Found last_check entity: #{entity.inspect}"
      # Get `question` property value.
      last_check = entity.properties.last_check.dateTimeValue.to_datetime
    else
      last_check = Date.today.prev_day.to_datetime # "2015-01-01T00:00:01z"
    end
    puts "last_check: #{last_check.inspect} class=#{last_check.class.name}"
    return last_check
  end

  def insert_new_check_date(t=Time.now)
    # If the entity is not found create it.
    entity = {
        # Set the entity key with only one `path` element: no parent.
        :key => lckey,
        # Set the entity properties:
        # - a utf-8 string: `question`
        # - a 64bit integer: `answer`
        :properties => {
            :last_check => {:dateTimeValue => t.to_datetime.rfc3339()},
        }
    }
    # Build a mutation to insert the new entity.
    mutation = {:upsert => [entity]}

    # Commit the transaction and the insert mutation if the entity was not found.
    resp = client.execute(
        :api_method => datastore.datasets.commit,
        :parameters => {:datasetId => dataset_id},
        :body_object => {
            # :transaction => tx,
            # todo: I couldn't get transactions to work?!?! get this: \"reason\": \"INVALID_ARGUMENT\",\n    \"message\": \"unknown transaction handle\"\n
            :mode => 'NON_TRANSACTIONAL',
            :mutation => mutation
        })
    puts "body=#{resp.body.inspect}"
  end
end
