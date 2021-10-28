# ex_metrc
ExMetrc is a library that serves to integrate Metrc API to the project.
To use the library:
1. This library is dependant on Oban and Hammer, so you will need to import them and configure them for the library to function properly.
```elixir
config :my_app, Oban,
  prefix: "your_database_schema",
  repo: MyApp.Repo,
  queues: [ex_metrc_get: 30],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 86_400}
  ]

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 8_000, cleanup_interval_ms: 7_900]}
```

2. Add ex_metrc to you `mix.exs`
3. Retrieve your vendor key from the metrc website.
4. Add ex_metrc configuration as follows:
 ```elixir
 config :ex_metrc,
 vendor_key: "your_vendor_key",
 requests_per_second: 150,
 repo: MyApp.Repo
 ```
Requests_per_second is used to configure how many requests to send per second, as the Metrc API has rate limiting on the number of requests. 

Repo is your host project's repo module, to be used in the Oban jobs when performed to get and/or update from your database

For the user_key, you need to pass it in the functions dynamically alongside the license number.
This way, you can access multiple stores without the need to restart the server to change the user key

Now you are ready to use the library in your application.