##
# beiarea/chrapy-wangkit
# 
# See that README.md for general background and maybe even instructions at some
# point.
# 
# Major changes are (so far):
# 
# 1.  Aesthetic -- 80 character line limit where sensible, and using line 
#     breaks to emphasize where chained commands connect.
#     
# 2.  Build Args -- Configuration values broken out into [build args][] so they
#     can be specified and changed as part of the build process without 
#     branching / forking / copy-pasta-ing.
#     
#     The idea is to make it a generalized utility layer that doesn't require
#     modification by the projects using it.
# 
# [build args]: https://docs.docker.com/engine/reference/builder/#arg
# 

# Expose `FROM` as an optional `FROM_IMAGE` build arg, allowing you to specify
# the base image at build.
# 
# This is useful because we have a base image for each project providing basic
# packages and configuration that we use as much as possible, so this lets us
# slot that in "beneath" this and "above" the `ruby:M.m.p` image.
# 
# Default to `ruby:2.3.4` since it's the one we've tested these changes on.
# 
# @maxwellhealth was at `ruby:2.2.1` when we forked.
# 
ARG FROM_IMAGE="ruby:2.3.4"
FROM "${FROM_IMAGE}"


ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true


# Set timezone.
# 
# Also exposed as the optional `TIMEZONE` build arg.
# 
# Max had it set to "US/Eastern", but I switched the default to UTC because
# there's not much else that makes sense for a universal default.
# 
# Examples: "US/Eastern", "Asia/Shanghai", "Etc/UTC"
# 
ARG TIMEZONE="Etc/UTC"
RUN echo "${TIMEZONE}" > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata


RUN apt-get update -y \
    && apt-get install -y \
        unzip \
        xvfb \
        qt5-default \
        libqt5webkit5-dev \
        gstreamer1.0-plugins-base \
        gstreamer1.0-tools \
        gstreamer1.0-x


# Install Chrome WebDriver
# 
# ChromeDriver exposed as an optional build arg.
# 
# Default of "2.21" is what it came with from Max. 
# 
# There are more recent versions of ChromeDriver available at the time of 
# writing, but I left this as is to try and change as little as possible 
# until we've gotten it up and running smoothly, assuming that the state it 
# came in was at least usable by someone at some point.
# 
# Example: "2.21"
# 
ARG CHROMEDRIVER_VERSION="2.21"
RUN mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION \
    && curl -sS -o \
        /tmp/chromedriver_linux64.zip \
        http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip \
    && unzip -qq \
        /tmp/chromedriver_linux64.zip \
        -d /opt/chromedriver-$CHROMEDRIVER_VERSION \
    && rm /tmp/chromedriver_linux64.zip \
    && chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver \
    && ln -fs \
        /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver \
        /usr/local/bin/chromedriver


# Install Google Chrome
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub \
        | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" \
        >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get -y update \
    && apt-get -y install google-chrome-stable \ 
    && rm -rf /var/lib/apt/lists/*


# Disable the SUID sandbox so that Chrome can launch without being in a 
# privileged container.
# 
# One unfortunate side effect is that `google-chrome --help` will no longer 
# work.
# 
RUN dpkg-divert --add --rename --divert \
        /opt/google/chrome/google-chrome.real \
        /opt/google/chrome/google-chrome \
    && echo \
        "#!/bin/bash\nexec /opt/google/chrome/google-chrome.real --disable-setuid-sandbox \"\$@\"" \
        > /opt/google/chrome/google-chrome \
    && chmod 755 /opt/google/chrome/google-chrome


# Default configuration
# 
# We switched these to build args for the reasons outlined in the header.
# 

# `DISPLAY` was :20.0 but seems to need to match value in `xvfb-daemon-run`, 
# which is `:99`, so think this should be `:99.0`, which I've seen in some
# examples online.
ARG DISPLAY=":99.0"

ARG SCREEN_GEOMETRY="1440x900x24"

ARG CHROMEDRIVER_PORT="4444"

ARG CHROMEDRIVER_WHITELISTED_IPS="127.0.0.1"

# Set working directory to canonical directory
ARG WORKDIR="/usr/src/app"
WORKDIR "${WORKDIR}"

# Bind the args to env vars.
ENV WORKDIR="${WORKDIR}" \
    DISPLAY="${DISPLAY}" \
    SCREEN_GEOMETRY="${SCREEN_GEOMETRY}" \
    CHROMEDRIVER_PORT="${CHROMEDRIVER_PORT}" \
    CHROMEDRIVER_WHITELISTED_IPS="${CHROMEDRIVER_WHITELISTED_IPS}"


# Adds ability to run xvfb in daemonized mode
ADD xvfb_init /etc/init.d/xvfb
RUN chmod a+x /etc/init.d/xvfb
ADD xvfb-daemon-run /usr/bin/xvfb-daemon-run
RUN chmod a+x /usr/bin/xvfb-daemon-run

# WARNING!  This script is... problematic as a general entry point. It won't
#           
ENTRYPOINT ["/usr/bin/xvfb-daemon-run"]
