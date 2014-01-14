# Either use a copy of this too_many_secrets file
# or specify these ENV variables in your application host's config. 

# A secret for Rails to use when securing forms
ENV['RAILS_SECRET_TOKEN'] = "a token with at least 30 random digits"

# Amazon Web Services access keys for your buckets and DNS
ENV['AWS_ACCESS_KEY_ID'] = "your AWS S3 access key"
ENV['AWS_SECRET_ACCESS_KEY'] = "your AWS S3 access secret"

# The Amazon Web Services region to specify for your S3 buckets
# See http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region for options.
ENV['AWS_REGION'] = "us-east-1"
ENV['AWS_REGION_ZONE_ID'] = "Z3AQBSTGFYJSTF"

# The Amazon Route 53 zone ID to use for DNS entries
ENV['AWS_DNS_ZONE_ID'] = "/hostedzone/SOMEEXAMPLE"

# The host name to use in email links back to this app
ENV['SHINING_SEA_MULTISITE_HOST'] = "shining-sea-multisite.example.com"
