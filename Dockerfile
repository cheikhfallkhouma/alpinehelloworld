# Grab the latest alpine image
FROM alpine:latest

# Install python and pip
RUN apk add --no-cache --update python3 py3-pip bash

# Copy the requirements
ADD ./webapp/requirements.txt /tmp/requirements.txt

# Install dependencies (fixes PEP 668 error)
RUN pip3 install --no-cache-dir --break-system-packages -q -r /tmp/requirements.txt

# Add our code
ADD ./webapp /opt/webapp/
WORKDIR /opt/webapp

# Run the image as a non-root user
RUN adduser -D myuser
USER myuser

# Run the app. CMD is required to run on Heroku
CMD gunicorn --bind 0.0.0.0:$PORT wsgi

