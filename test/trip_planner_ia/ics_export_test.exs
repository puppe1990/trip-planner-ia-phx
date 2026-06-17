defmodule TripPlannerIa.IcsExportTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.Fixtures
  alias TripPlannerIa.IcsExport

  test "generates valid VCALENDAR with VEVENT entries" do
    plan =
      Fixtures.sample_trip_plan(%{
        id: "trip_ics",
        destination: "Barcelona, Espanha",
        duration_days: 1,
        days: [
          %{
            day_number: 1,
            theme: "Gaudí",
            morning: %{
              title: "Sagrada Família",
              description: "Basílica icônica",
              cost: "R$ 100",
              duration: "3h"
            },
            afternoon: %{
              title: "Park Güell",
              description: "Parque colorido",
              cost: "R$ 50",
              duration: "2h"
            },
            evening: %{
              title: "Las Ramblas",
              description: "Passeio noturno",
              cost: "Grátis",
              duration: "2h"
            },
            dining_spot: %{
              name: "Tapas Bar",
              type: "Espanhola",
              price_level: "R$ Moderado",
              description: "Paella"
            }
          }
        ]
      })

    ics = IcsExport.generate(plan, "2026-06-15")

    assert ics =~ "BEGIN:VCALENDAR"
    assert ics =~ "END:VCALENDAR"
    assert ics =~ "BEGIN:VEVENT"
    assert length(Regex.scan(~r/BEGIN:VEVENT/, ics)) == 4
  end

  test "escapes semicolons in text fields" do
    plan = Fixtures.sample_trip_plan()

    plan =
      put_in(
        plan,
        [:days, Access.at(0), :morning, :description],
        "Visita; com guia"
      )

    ics = IcsExport.generate(plan, "2026-06-15")
    assert ics =~ "Visita\\; com guia"
  end

  test "returns nil for invalid start date" do
    plan = Fixtures.sample_trip_plan()
    assert IcsExport.generate(plan, "invalid-date") == nil
  end
end
