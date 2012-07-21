## How this skeleton is different

lolwut is just like the default Monk skeleton, except for these differences:

### Testing with RSpec

Testing is done with RSpec and Webrat instead of Webrat and Contest/Stories.

### Session security

The default Monk skeleton doesn't use a secret key for ensuring session data
integrity.  I think a lot of people don't realize how much of a security threat
this is, so my skeleton creates a random key in `config/secret.txt` the first
time the app is run.

### Compass and SASS CSS framework

It is almost wired that these two are not included by default. I thought
everyone would need them.

## Using this skeleton

Add this line to ~/.monk:

    monk add spec-corp git://github.com/roylez/spec-corp.git

Then, use this command to create a new Sinatra app:

    monk init -s spec-corp my_app_name
