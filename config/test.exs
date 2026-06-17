import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

config :trip_planner_ia, TripPlannerIa.Repo,
  adapter: Ecto.Adapters.LibSql,
  database: "priv/data/trip_planner_ia_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool_size: 5

config :trip_planner_ia, TripPlannerIaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "1gBoXKGLH769D++EQwqpRMT8bv6FRbRQh/WuUbnul4vCcnZCFv6CGPG6yCleNNdB",
  server: false

config :trip_planner_ia, TripPlannerIa.Mailer, adapter: Swoosh.Adapters.Test
config :swoosh, :api_client, false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :phoenix,
  sort_verified_routes_query_params: true