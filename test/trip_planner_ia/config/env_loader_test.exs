defmodule TripPlannerIa.Config.EnvLoaderTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.Config.EnvLoader

  setup do
    tmp = System.tmp_dir!()
    path = Path.join(tmp, "env_loader_test_#{System.unique_integer([:positive])}.env")
    on_exit(fn -> File.rm(path) end)
    System.delete_env("ENV_LOADER_TEST_KEY")
    %{path: path}
  end

  test "loads unset variables from a dotenv file", %{path: path} do
    File.write!(path, "ENV_LOADER_TEST_KEY=from-dotenv\n")

    :ok = EnvLoader.load_dotenv(path)

    assert System.get_env("ENV_LOADER_TEST_KEY") == "from-dotenv"
  end

  test "does not override existing environment variables", %{path: path} do
    System.put_env("ENV_LOADER_TEST_KEY", "existing")
    File.write!(path, "ENV_LOADER_TEST_KEY=from-dotenv\n")

    :ok = EnvLoader.load_dotenv(path)

    assert System.get_env("ENV_LOADER_TEST_KEY") == "existing"
  end
end
