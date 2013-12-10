shining-sea-multisite
=====================

Showcasing great tweets. Based on measuredvoice/shining-sea.

## ENV variables you will need

```
RAILS_SECRET_TOKEN  (a string at least 30 characters long)
SHINING_SEA_MULTISITE_HOST (the hostname of the deployed server)
```


## Deploying to Heroku

Clone this repository.

Follow the instructions at Heroku to configure your local environment.

Specify the environment variables:

```
heroku config:set RAILS_SECRET_TOKEN="my favorite 30-character phrase"
heroku config:set SHINING_SEA_MULTISITE_HOST="thebesttweets.example.com"
```

Run the Rails console to set up the first user:
```
heroku run rails console

irb> User.create!(:email => 'me@example.com', :password => 'correct horse battery staple', :password_confirmation => 'correct horse batter staple')
```
