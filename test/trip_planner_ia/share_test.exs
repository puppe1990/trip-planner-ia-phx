defmodule TripPlannerIa.ShareTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.Fixtures
  alias TripPlannerIa.Share

  test "round-trips trip plan through base64 encoding" do
    plan = Fixtures.sample_trip_plan()
    encoded = Share.encode_trip_plan(plan)
    decoded = Share.decode_shared_trip_plan(encoded)

    assert decoded.destination == plan.destination
    assert length(decoded.days) == 1
  end

  test "parses share hash from URL fragment" do
    plan = Fixtures.sample_trip_plan()
    url = Share.build_share_url(plan, "http://localhost:4000", "/")
    hash = url |> String.split("#", parts: 2) |> List.last()
    parsed = Share.parse_share_hash("#" <> hash)

    assert parsed.id == "trip_test"
  end

  test "returns nil for invalid hash" do
    assert Share.parse_share_hash("#share=not-valid-base64!!!") == nil
    assert Share.parse_share_hash("#other=abc") == nil
  end
end