#!/bin/sh

curl -X POST \
  -d token=SLACKTOKEN \
  -d team_id=SLACKTEAMID \
  -d team_domain=SLACKTEAMDOMAIN \
  -d channel_id=SLACKCHANNELID \
  -d channel_name=SLACKCHANNELNAME \
  -d user_id=USERID \
  -d user_name=marclennox \
  -d command=%2Fha \
  -d text=disarm \
  -d response_url=https%3A%2F%2Fhooks.slack.com%2Fcommands%2FT03KUC7L4%2F15720956322%2FTc9H1ckOTJul1gb5CiSuL5kj \
  http://ha-slackhooks.docker/hooks/ha
