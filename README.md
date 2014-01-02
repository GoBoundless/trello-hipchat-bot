trello-hipchat-bot
==================

This bot is designed to be run as a free Heroku project. As with any good [12 Factor App](http://www.12factor.net/config), you will need to set a few environment variables. For example:

```bash
heroku config:set --app my-new-heroku-app \
  HIPCHAT_API_TOKEN=8w1cxvrvxitgvkoaq9clfqqzgy7n7g \
  HIPCHAT_ROOM=Engineering,QA,Engineering \
  TRELLO_OAUTH_PUBLIC_KEY=xre3rgsdbbvvjsy74axyqmtddgdnrr8e \
  TRELLO_TOKEN=pdwnbruojwrdvfxxuyu9vtzaea6vfojf9bfa6jcmutkdfomwlk2izmxwnvdcwgkv \
  TRELLO_BOARD=ododysnyxgfqsvtpky7fqqcz,sadnkjasbdksabfsafj32ssd,sadojfsdoerwogioj43
```

It runs as a worker process with no exposure to the web.

```bash
heroku ps:scale web=0 --app my-new-heroku-app
heroku ps:scale worker=1 --app my-new-heroku-app
```

Contributing
------------

**This project isn't actively in use by the original authors. Anyone interested in adopting it should contact @jelder.**

1. Fork it.
2. Create a branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request
