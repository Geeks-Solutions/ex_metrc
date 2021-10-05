# ex_metrc
ExMetrc is a library that serves to integrate Metrc API to the project.
To use the library:

1. Add ex_metrc to you `mix.exs`
2. Retrieve your vendor key from the metrc website.
3. Add ex_metrc configuration as follows:
 ```elixir
 config :ex_metrc,
 vendor_key: "your_vendor_key"
 ```

Now you are ready to use the library in your application.