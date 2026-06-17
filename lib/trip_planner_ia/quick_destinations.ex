defmodule TripPlannerIa.QuickDestinations do
  @moduledoc false

  @default_region :brazil

  @regions [
    %{id: :brazil, emoji: "🇧🇷", label_pt: "Brasil", label_en: "Brazil"},
    %{id: :europe, emoji: "🇪🇺", label_pt: "Europa", label_en: "Europe"},
    %{id: :asia, emoji: "🌏", label_pt: "Ásia", label_en: "Asia"},
    %{id: :americas, emoji: "🌎", label_pt: "Américas", label_en: "Americas"},
    %{id: :africa, emoji: "🌍", label_pt: "África", label_en: "Africa"},
    %{id: :oceania, emoji: "🏝️", label_pt: "Oceania", label_en: "Oceania"}
  ]

  @destinations_by_region %{
    brazil: [
      %{
        key: "rio",
        emoji: "🇧🇷",
        bg_gradient: "from-emerald-500 to-teal-600",
        name_pt: "Rio de Janeiro, Brasil",
        name_en: "Rio de Janeiro, Brazil",
        tagline_pt: "Energia tropical entre praias e montanhas",
        tagline_en: "Tropical energy between beaches and mountains",
        params: %{
          destination: "Rio de Janeiro, Brasil",
          duration: 3,
          budget: "Baixo",
          style: "Aventura",
          companion: "Amigos",
          season: "Verão",
          extra_notes: "Visitas ao Cristo, Pão de Açúcar e praias locais."
        }
      },
      %{
        key: "saoPaulo",
        emoji: "🇧🇷",
        bg_gradient: "from-slate-600 to-zinc-700",
        name_pt: "São Paulo, Brasil",
        name_en: "São Paulo, Brazil",
        tagline_pt: "Metrópole cultural, gastronomia e arte urbana",
        tagline_en: "Cultural metropolis, food and urban art",
        params: %{
          destination: "São Paulo, Brasil",
          duration: 4,
          budget: "Médio",
          style: "Gastronômico",
          companion: "Casal",
          season: "Outono",
          extra_notes: "Gastronomia diversa, museus e vida noturna em bairros como Vila Madalena."
        }
      },
      %{
        key: "salvador",
        emoji: "🇧🇷",
        bg_gradient: "from-amber-500 to-orange-600",
        name_pt: "Salvador, Bahia",
        name_en: "Salvador, Bahia",
        tagline_pt: "História afro-brasileira e praias do litoral",
        tagline_en: "Afro-Brazilian history and coastal beaches",
        params: %{
          destination: "Salvador, Bahia, Brasil",
          duration: 4,
          budget: "Baixo",
          style: "Cultural",
          companion: "Família",
          season: "Verão",
          extra_notes: "Pelourinho, culinária baiana e praias do litoral norte."
        }
      },
      %{
        key: "florianopolis",
        emoji: "🇧🇷",
        bg_gradient: "from-cyan-500 to-blue-600",
        name_pt: "Florianópolis, Brasil",
        name_en: "Florianópolis, Brazil",
        tagline_pt: "Ilha da magia com praias e trilhas",
        tagline_en: "Magic island with beaches and trails",
        params: %{
          destination: "Florianópolis, Brasil",
          duration: 3,
          budget: "Médio",
          style: "Relaxante",
          companion: "Amigos",
          season: "Verão",
          extra_notes: "Praias paradisíacas, trilhas e gastronomia frutos do mar."
        }
      }
    ],
    europe: [
      %{
        key: "paris",
        emoji: "🇫🇷",
        bg_gradient: "from-blue-500 to-indigo-600",
        name_pt: "Paris, França",
        name_en: "Paris, France",
        tagline_pt: "Romantismo, museus lendários e cafés de charme",
        tagline_en: "Romance, legendary museums and charming cafés",
        params: %{
          destination: "Paris, França",
          duration: 4,
          budget: "Alto",
          style: "Gastronômico",
          companion: "Casal",
          season: "Outono",
          extra_notes: "Cafés fofos e museus de arte clássicos (Louvre e d'Orsay)."
        }
      },
      %{
        key: "rome",
        emoji: "🇮🇹",
        bg_gradient: "from-amber-500 to-orange-600",
        name_pt: "Roma, Itália",
        name_en: "Rome, Italy",
        tagline_pt: "Uma jornada inesquecível pelo berço da civilização",
        tagline_en: "An unforgettable journey through the cradle of civilization",
        params: %{
          destination: "Roma, Itália",
          duration: 5,
          budget: "Médio",
          style: "Cultural",
          companion: "Família",
          season: "Primavera",
          extra_notes: "Muita culinária Italiana autêntica e passeios de baixo caminhar."
        }
      },
      %{
        key: "barcelona",
        emoji: "🇪🇸",
        bg_gradient: "from-rose-500 to-red-600",
        name_pt: "Barcelona, Espanha",
        name_en: "Barcelona, Spain",
        tagline_pt: "Arquitetura de Gaudí e vida mediterrânea",
        tagline_en: "Gaudí architecture and Mediterranean life",
        params: %{
          destination: "Barcelona, Espanha",
          duration: 4,
          budget: "Médio",
          style: "Cultural",
          companion: "Amigos",
          season: "Primavera",
          extra_notes: "Gaudí, Ramblas, tapas e praias urbanas."
        }
      },
      %{
        key: "lisbon",
        emoji: "🇵🇹",
        bg_gradient: "from-yellow-500 to-amber-600",
        name_pt: "Lisboa, Portugal",
        name_en: "Lisbon, Portugal",
        tagline_pt: "Colinas, elétricos e pastéis de nata",
        tagline_en: "Hills, trams and pastéis de nata",
        params: %{
          destination: "Lisboa, Portugal",
          duration: 3,
          budget: "Médio",
          style: "Gastronômico",
          companion: "Casal",
          season: "Outono",
          extra_notes: "Alfama, elétricos, pastéis de nata e miradouros."
        }
      }
    ],
    asia: [
      %{
        key: "tokyo",
        emoji: "🇯🇵",
        bg_gradient: "from-pink-500 to-rose-600",
        name_pt: "Tóquio, Japão",
        name_en: "Tokyo, Japan",
        tagline_pt: "Sinergia futurista e tradições milenares",
        tagline_en: "Futuristic synergy and ancient traditions",
        params: %{
          destination: "Tóquio, Japão",
          duration: 5,
          budget: "Médio",
          style: "Cultural",
          companion: "Solo",
          season: "Primavera (Cerejeiras)",
          extra_notes: "Quero ver templos históricos e tecnologia em Akihabara."
        }
      },
      %{
        key: "bangkok",
        emoji: "🇹🇭",
        bg_gradient: "from-violet-500 to-purple-600",
        name_pt: "Bangkok, Tailândia",
        name_en: "Bangkok, Thailand",
        tagline_pt: "Templos dourados e street food inesquecível",
        tagline_en: "Golden temples and unforgettable street food",
        params: %{
          destination: "Bangkok, Tailândia",
          duration: 4,
          budget: "Baixo",
          style: "Gastronômico",
          companion: "Amigos",
          season: "Inverno",
          extra_notes: "Templos, mercados de rua e vida noturna em rooftop bars."
        }
      },
      %{
        key: "bali",
        emoji: "🇮🇩",
        bg_gradient: "from-green-500 to-emerald-600",
        name_pt: "Bali, Indonésia",
        name_en: "Bali, Indonesia",
        tagline_pt: "Templos, arrozais e praias paradisíacas",
        tagline_en: "Temples, rice terraces and paradise beaches",
        params: %{
          destination: "Bali, Indonésia",
          duration: 5,
          budget: "Médio",
          style: "Relaxante",
          companion: "Casal",
          season: "Verão",
          extra_notes: "Templos, arrozais em Ubud e praias em Uluwatu."
        }
      },
      %{
        key: "seoul",
        emoji: "🇰🇷",
        bg_gradient: "from-indigo-500 to-blue-600",
        name_pt: "Seul, Coreia do Sul",
        name_en: "Seoul, South Korea",
        tagline_pt: "Tradição e modernidade em perfeita harmonia",
        tagline_en: "Tradition and modernity in perfect harmony",
        params: %{
          destination: "Seul, Coreia do Sul",
          duration: 4,
          budget: "Médio",
          style: "Cultural",
          companion: "Solo",
          season: "Outono",
          extra_notes: "Palácios, K-pop, street food e bairros tradicionais."
        }
      }
    ],
    americas: [
      %{
        key: "newYork",
        emoji: "🇺🇸",
        bg_gradient: "from-slate-700 to-slate-900",
        name_pt: "Nova York, EUA",
        name_en: "New York, USA",
        tagline_pt: "A cidade que nunca dorme",
        tagline_en: "The city that never sleeps",
        params: %{
          destination: "Nova York, EUA",
          duration: 5,
          budget: "Alto",
          style: "Equilibrado",
          companion: "Amigos",
          season: "Outono",
          extra_notes: "Broadway, Central Park, museus e diversidade gastronômica."
        }
      },
      %{
        key: "buenosAires",
        emoji: "🇦🇷",
        bg_gradient: "from-sky-500 to-blue-600",
        name_pt: "Buenos Aires, Argentina",
        name_en: "Buenos Aires, Argentina",
        tagline_pt: "Tango, bife e paixão portenha",
        tagline_en: "Tango, steak and porteño passion",
        params: %{
          destination: "Buenos Aires, Argentina",
          duration: 4,
          budget: "Médio",
          style: "Gastronômico",
          companion: "Casal",
          season: "Primavera",
          extra_notes: "Tango, bife de chorizo, San Telmo e La Boca."
        }
      },
      %{
        key: "cancun",
        emoji: "🇲🇽",
        bg_gradient: "from-teal-500 to-cyan-600",
        name_pt: "Cancún, México",
        name_en: "Cancún, Mexico",
        tagline_pt: "Caribe azul e ruínas maias",
        tagline_en: "Caribbean blue and Mayan ruins",
        params: %{
          destination: "Cancún, México",
          duration: 4,
          budget: "Médio",
          style: "Relaxante",
          companion: "Família",
          season: "Inverno",
          extra_notes: "Praias do Caribe, Chichén Itzá e cenotes."
        }
      },
      %{
        key: "lima",
        emoji: "🇵🇪",
        bg_gradient: "from-orange-500 to-red-600",
        name_pt: "Lima, Peru",
        name_en: "Lima, Peru",
        tagline_pt: "Capital gastronômica da América Latina",
        tagline_en: "Latin America's gastronomic capital",
        params: %{
          destination: "Lima, Peru",
          duration: 3,
          budget: "Baixo",
          style: "Gastronômico",
          companion: "Solo",
          season: "Verão",
          extra_notes: "Ceviche, Miraflores, centro histórico e culinária peruana."
        }
      }
    ],
    africa: [
      %{
        key: "marrakech",
        emoji: "🇲🇦",
        bg_gradient: "from-red-600 to-orange-700",
        name_pt: "Marrakech, Marrocos",
        name_en: "Marrakech, Morocco",
        tagline_pt: "Souks vibrantes e arquitetura mourisca",
        tagline_en: "Vibrant souks and Moorish architecture",
        params: %{
          destination: "Marrakech, Marrocos",
          duration: 4,
          budget: "Médio",
          style: "Cultural",
          companion: "Casal",
          season: "Primavera",
          extra_notes: "Medina, souks, riads e excursão ao deserto do Saara."
        }
      },
      %{
        key: "capeTown",
        emoji: "🇿🇦",
        bg_gradient: "from-blue-600 to-indigo-700",
        name_pt: "Cidade do Cabo, África do Sul",
        name_en: "Cape Town, South Africa",
        tagline_pt: "Montanhas, vinícolas e costa selvagem",
        tagline_en: "Mountains, vineyards and wild coast",
        params: %{
          destination: "Cidade do Cabo, África do Sul",
          duration: 5,
          budget: "Médio",
          style: "Aventura",
          companion: "Amigos",
          season: "Verão",
          extra_notes: "Table Mountain, vinícolas de Stellenbosch e Chapmans Peak."
        }
      },
      %{
        key: "cairo",
        emoji: "🇪🇬",
        bg_gradient: "from-amber-600 to-yellow-700",
        name_pt: "Cairo, Egito",
        name_en: "Cairo, Egypt",
        tagline_pt: "Pirâmides milenares e história faraônica",
        tagline_en: "Ancient pyramids and pharaonic history",
        params: %{
          destination: "Cairo, Egito",
          duration: 4,
          budget: "Baixo",
          style: "Cultural",
          companion: "Família",
          season: "Inverno",
          extra_notes: "Pirâmides de Gizé, Museu Egípcio e cruzeiro no Nilo."
        }
      },
      %{
        key: "zanzibar",
        emoji: "🇹🇿",
        bg_gradient: "from-emerald-600 to-teal-700",
        name_pt: "Zanzibar, Tanzânia",
        name_en: "Zanzibar, Tanzania",
        tagline_pt: "Praias de águas cristalinas no Índico",
        tagline_en: "Crystal-clear beaches on the Indian Ocean",
        params: %{
          destination: "Zanzibar, Tanzânia",
          duration: 5,
          budget: "Médio",
          style: "Relaxante",
          companion: "Casal",
          season: "Verão",
          extra_notes: "Praias de águas cristalinas, Stone Town e mergulho."
        }
      }
    ],
    oceania: [
      %{
        key: "sydney",
        emoji: "🇦🇺",
        bg_gradient: "from-blue-500 to-sky-600",
        name_pt: "Sydney, Austrália",
        name_en: "Sydney, Australia",
        tagline_pt: "Opera House, Bondi e estilo de vida ao ar livre",
        tagline_en: "Opera House, Bondi and outdoor lifestyle",
        params: %{
          destination: "Sydney, Austrália",
          duration: 5,
          budget: "Alto",
          style: "Equilibrado",
          companion: "Amigos",
          season: "Verão",
          extra_notes: "Opera House, Bondi Beach, Blue Mountains e cafés."
        }
      },
      %{
        key: "queenstown",
        emoji: "🇳🇿",
        bg_gradient: "from-green-600 to-emerald-700",
        name_pt: "Queenstown, Nova Zelândia",
        name_en: "Queenstown, New Zealand",
        tagline_pt: "Aventura extrema em paisagens épicas",
        tagline_en: "Extreme adventure in epic landscapes",
        params: %{
          destination: "Queenstown, Nova Zelândia",
          duration: 4,
          budget: "Alto",
          style: "Aventura",
          companion: "Amigos",
          season: "Inverno",
          extra_notes: "Esportes radicais, Milford Sound e paisagens de tirar o fôlego."
        }
      },
      %{
        key: "fiji",
        emoji: "🇫🇯",
        bg_gradient: "from-cyan-500 to-teal-600",
        name_pt: "Fiji",
        name_en: "Fiji",
        tagline_pt: "Ilhas tropicais e hospitalidade do Pacífico",
        tagline_en: "Tropical islands and Pacific hospitality",
        params: %{
          destination: "Fiji",
          duration: 5,
          budget: "Alto",
          style: "Relaxante",
          companion: "Casal",
          season: "Verão",
          extra_notes: "Resorts em ilhas paradisíacas, snorkeling e cultura local."
        }
      },
      %{
        key: "melbourne",
        emoji: "🇦🇺",
        bg_gradient: "from-violet-600 to-purple-700",
        name_pt: "Melbourne, Austrália",
        name_en: "Melbourne, Australia",
        tagline_pt: "Cafés de especialidade e arte de rua",
        tagline_en: "Specialty coffee and street art",
        params: %{
          destination: "Melbourne, Austrália",
          duration: 4,
          budget: "Médio",
          style: "Gastronômico",
          companion: "Solo",
          season: "Primavera",
          extra_notes: "Cafés de especialidade, street art e Great Ocean Road."
        }
      }
    ]
  }

  def default_region, do: @default_region

  def regions, do: @regions

  def destinations_for_region(region) when is_atom(region) do
    Map.get(@destinations_by_region, region, [])
  end

  def destinations_for_region(region) when is_binary(region) do
    destinations_for_region(String.to_existing_atom(region))
  rescue
    ArgumentError -> []
  end
end
