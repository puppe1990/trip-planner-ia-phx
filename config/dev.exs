import Config

# Polling backend avoids mac_listener spawn failures under heavy file-watcher load.
config :file_system, :backend, FileSystem.Backends.FSPoll

config :trip_planner_ia, TripPlannerIa.Repo,
  adapter: Ecto.Adapters.LibSql,
  database: "priv/data/trip_planner_ia_dev.db",
  pool_size: 5

config :trip_planner_ia, TripPlannerIaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "TiTsfnIQIlp/+0wO9VZmSxv4RSVH9uGiviSMX+YDoi600kdX1djuF73+XbHEU2Qd",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:trip_planner_ia, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:trip_planner_ia, ~w(--watch)]}
  ]

config :trip_planner_ia, TripPlannerIaWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$"E,
      ~r"priv/gettext/.*\.po$"E,
      ~r"lib/trip_planner_ia_web/router\.ex$"E,
      ~r"lib/trip_planner_ia_web/(controllers|live|components)/.*\.(ex|heex)$"E
    ]
  ]

config :trip_planner_ia, TripPlannerIa.Mailer, adapter: Swoosh.Adapters.Local

config :trip_planner_ia, dev_routes: true, load_dotenv: true
config :logger, :default_formatter, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true
