#!/bin/sh

if [ "${RAILS_ENV}" = "production" ]
then
    bundle exec rails assets:precompile
fi

bundle exec s -p ${PORT:-3000} -b 0.0.0.0