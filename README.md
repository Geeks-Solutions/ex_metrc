# ex_metrc
ExMetrc is a library that serves to integrate Metrc API to the project.
To use the library:

1. Add ex_metrc to you `mix.exs`
2. Retrieve your vendor key from the metrc website.
3. Add ex_metrc configuration as follows:
 ```elixir
 config :ex_metrc,
 vendor_key: "your_vendor_key",
 requests_per_second: 3
 ```
Requests_per_second is used to configure how many requests to send per second, as the Metrc API has rate limiting on the number of requests. 

For the user_key, you need to pass it in the functions dynamically alongside the license number.
This way, you can access multiple stores without the need to restart the server to change the user key

Now you are ready to use the library in your application.