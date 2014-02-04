shining-sea-multisite
=====================

Showcasing great tweets. Based on measuredvoice/shining-sea.

Shining Sea builds rankings of tweets written by lists of Twitter accounts around a theme. The first site was Great Gov Tweets, focused on U.S. federal government communication. 

The multi-site version allows multiple lists to be published from the same Rails administration server to static websites hosted as individual Amazon S3 buckets. Sites are configured in RailsAdmin, metrics are collected from Twitter hourly, and pages are published daily. Delayed Job is used to queue interactions with Twitter (for rate-limit protection) and other site-building tasks.

## ENV variables you will need

Specify these either using environment variables (a la Heroku or your own environment) or by copying config/too_many_secrets.rb to config/too_many_secrets.rb, which is imported by the application. See the too_many_secrets file for details.

```
RAILS_SECRET_TOKEN  (a string at least 30 characters long)
SHINING_SEA_MULTISITE_HOST (the hostname of the deployed server)

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

AWS_REGION
AWS_REGION_ZONE_ID
AWS_DNS_ZONE_ID

SHINING_SEA_ALPHA
SHINING_SEA_BETA
```


## Deploying to Heroku

Clone this repository.

Follow the instructions at Heroku to configure your local environment and deploy to Heroku. 

Shining Sea multi-site requires a Postgres database; a basic DB instance should suffice for a few dozen sites.

Shining Sea also requires a Delayed Job worker. Heroku allocates one to Rails tasks automatically; just make sure it's running with at least one worker.

Specify the environment variables (listed above and described in the too_many_secrets file):

```
heroku config:set RAILS_SECRET_TOKEN="my favorite 30-character phrase"
heroku config:set SHINING_SEA_MULTISITE_HOST="thebesttweets.example.com"
...
```

Run the Rails console to set up the first user:
```
heroku run rails console

irb> User.create!(:email => 'me@example.com', :password => 'correct horse battery staple', :password_confirmation => 'correct horse battery staple')
```

Visit the application's host for detailed instructions on setting up sites. 

Schedule the metrics collection and publishing tasks using Heroku Scheduler or similar. Each task should run hourly, but the specific timing isn't important:
```
rake site:update_accounts
rake site:fetch_recent_tweets
rake site:complete_tweet_metrics
rake site:set_up_publishing    
rake site:publish_site_files
rake site:clean_old_data 
rake site:send_congrats_tweets
```

