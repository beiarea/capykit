beiarea/capykit
==============================================================================

If you ever wanted to run Chrome inside of Ruby inside of Docker inside of Linux inside your MacBook... you get the idea.

Provides headless Chrome webkit driver to Capybara in a Docker container.

Performance and stability are about as you would expect so far.

Forked from [docker-capybara-webkit-chromedriver][upstream] by Maxwell Health (@maxwellhealth).

Specifically, [commit 43eb858][], which is the head of `master` there as of 2017.12.06.

[upstream]: https://github.com/maxwellhealth/docker-capybara-webkit-chromedriver

[commit 43eb858]: https://github.com/maxwellhealth/docker-capybara-webkit-chromedriver/tree/43eb858aa0af8a40d7aedfac3e9e0db6d1efb907


-----------------------------------------------------------------------------
Notes & Caveats
-----------------------------------------------------------------------------

##### xvfb-daemon-run and `bash -c '...'` Disagreements

The `xvfb-daemon-run` script that serves as the `ENTRYPOINT` does a decent enough job with simple commands, but can/does fail for nested/quoted commands like `bash -c '...'`, which I've found myself using for one-offs that need to run in the containers.

I'm sure this could be solved with the proper bash-fu, but that's def not my strength. For now, I've worked around it by specifying the entry point as weall as the command like:

    docker run \
      --rm \
      --entrypoint='/usr/bin/dumb-init' \
      --interactive \
      --tty \
      IMAGE -- bash -c SUBCMD


Stuff Max wrote...

# Usage

There is some cleanup required to make this image more flexible for
different use cases, but for now you can use it like this:

Create a new Dockerfile in the root of your Capybara-Cucumber test
suite. It should look like this:

```Dockerfile
FROM maxwellhealthofficial/docker-capybara-webkit-chromedriver

ADD Gemfile /usr/src/app/Gemfile
RUN bundle install
ADD . /usr/src/app/

CMD ["bundle exec cucumber"]
```

To use the image, build your Dockerfile in the repo where your capybara
suite lives and run it.

```console
docker build -t my-capybara-app .
docker run --rm my-capybara-app
```

With some tlc, it may be possible to use this image out of the box
(without a dependent Dockerfile).

*Where Credit is Due*

-   @maxwellhealth for [docker-capybara-webkit-chromedriver](https://github.com/RobCherry/docker-chromedriver)
    
-   @robcherry for [docker-chromedriver](https://github.com/RobCherry/docker-chromedriver)
    
-   @keyvanfatehi for [keyvanfatehi//chrome-xvfb](https://github.com/kfatehi/docker-chrome-xvfb)
