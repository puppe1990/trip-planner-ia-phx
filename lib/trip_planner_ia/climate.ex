defmodule TripPlannerIa.Climate do
  @moduledoc false

  @alpine_keywords [
    "suíça",
    "switzerland",
    "alp",
    "neve",
    "ski",
    "bariloche",
    "lap",
    "islând",
    "noruega",
    "finlând",
    "canadá",
    "alpes",
    "chamonix",
    "aspen",
    "siberia",
    "patagônia",
    "ushuaia",
    "himalaia",
    "alaska",
    "alasca"
  ]

  @tropical_keywords [
    "rio de janeiro",
    "copacabana",
    "bahia",
    "nordeste",
    "praia",
    "beach",
    "cancún",
    "caribe",
    "maldivas",
    "miami",
    "hawaii",
    "havaí",
    "tailândia",
    "phuket",
    "bali",
    "ceará",
    "recife",
    "salvador",
    "porto de galinhas",
    "natal",
    "jericoacoara",
    "maragogi",
    "fernando de noronha",
    "caravelas",
    "ibiza",
    "grécia",
    "santorini",
    "amazon",
    "manaus",
    "pantanal"
  ]

  @desert_keywords [
    "egito",
    "egypt",
    "cairo",
    "dubai",
    "emirados",
    "saara",
    "atacama",
    "arizona",
    "las vegas",
    "marrocos",
    "marrakech",
    "petra",
    "jordânia",
    "machu picchu",
    "lima",
    "texas",
    "utah",
    "grand canyon"
  ]

  @southern_hemisphere_keywords [
    "são paulo",
    "buenos aires",
    "santiago",
    "curitiba",
    "gramado",
    "porto alegre",
    "florianópolis",
    "sul",
    "austrália",
    "sidney",
    "melbourne",
    "áfrica do sul",
    "montevid",
    "bariloche"
  ]

  @spec get_destination_climate(String.t()) :: %{
          climate_type: String.t(),
          description: String.t(),
          best_months: String.t(),
          months: [
            %{
              month: String.t(),
              temp_max: integer(),
              temp_min: integer(),
              precip: integer(),
              sun_hours: integer(),
              recommendation: String.t()
            }
          ]
        }
  def get_destination_climate(destination) when is_binary(destination) do
    dest = destination |> String.downcase()

    cond do
      matches_keywords?(dest, @alpine_keywords) -> alpine_profile()
      matches_keywords?(dest, @tropical_keywords) -> tropical_profile()
      matches_keywords?(dest, @desert_keywords) -> desert_profile()
      matches_keywords?(dest, @southern_hemisphere_keywords) -> southern_temperate_profile()
      true -> northern_temperate_profile()
    end
  end

  def get_destination_climate(nil), do: get_destination_climate("")

  defp matches_keywords?(dest, keywords) do
    Enum.any?(keywords, &String.contains?(dest, &1))
  end

  defp month(month, temp_max, temp_min, precip, sun_hours, recommendation) do
    %{
      month: month,
      temp_max: temp_max,
      temp_min: temp_min,
      precip: precip,
      sun_hours: sun_hours,
      recommendation: recommendation
    }
  end

  defp alpine_profile do
    %{
      climate_type: "Alpino / Frio de Montanha",
      description:
        "Clima caracterizado por invernos rigorosos com neve abundante e verões amenos. O ar é seco e os ventos de altitude podem intensificar consideravelmente a sensação de frio.",
      best_months: "Dezembro a Março (para Neve e Esqui) ou Julho a Agosto (para Trilhas)",
      months: [
        month(
          "Jan",
          1,
          -6,
          65,
          3,
          "Extremo: Use 3 camadas (térmica, fleece, corta-vento impermeável). Gorro, luvas e botas forradas."
        ),
        month(
          "Fev",
          2,
          -5,
          60,
          4,
          "Frio e neve: Casacos de pluma grossos, meias térmicas e botas com antiderrapante."
        ),
        month(
          "Mar",
          6,
          -2,
          70,
          5,
          "Transição fria: Jaquetas acolchoadas, calçados resistentes e blusas de lã grossa."
        ),
        month(
          "Abr",
          11,
          2,
          75,
          6,
          "Fresco e instável: Capa de chuva leve, jaqueta corta-vento e sapatos fechados impermeáveis."
        ),
        month(
          "Mai",
          15,
          6,
          90,
          7,
          "Agradável com chuva: Suéteres leves, lenços, e sapatos confortáveis para caminhar."
        ),
        month(
          "Jun",
          19,
          10,
          100,
          8,
          "Verão ameno: Roupas leves para o dia e cardigan/jaqueta leve para o entardecer."
        ),
        month(
          "Jul",
          22,
          12,
          95,
          9,
          "Perfeito para trilhas: Camisetas dry-fit, shorts/calças leves, óculos de sol, boné e bota de trilha."
        ),
        month(
          "Ago",
          21,
          12,
          95,
          8,
          "Quente de dia, fresco à noite: Estilo cebola (camadas fáceis de tirar). Traga óculos e protetor."
        ),
        month(
          "Set",
          17,
          9,
          85,
          6,
          "Fresco de outono: Jaqueta leve ou suéter aconchegante, calças jeans e botas."
        ),
        month(
          "Out",
          12,
          5,
          75,
          4,
          "Frio moderado: Casaco corta-vento de outono, cachecol leve e sapatos totalmente fechados."
        ),
        month(
          "Nov",
          6,
          0,
          70,
          3,
          "Frio acentuado: Sobretudo ou jaqueta invernal pesada, luvas finas e golas altas."
        ),
        month(
          "Dez",
          2,
          -4,
          65,
          2,
          "Inverno rigoroso de neve: Proteção total contra congelamento. Segunda pele é indispensável."
        )
      ]
    }
  end

  defp tropical_profile do
    %{
      climate_type: "Tropical Marítimo / Quente",
      description:
        "Clima ensolarado e úmido quase todo o ano. Os verões são quentes e podem trazer pancadas de chuva de fim de tarde. Os invernos são bastante amenos e ótimos para praia.",
      best_months:
        "Janeiro a Setembro (fuga de chuvas fortes de entardecer dependendo da região)",
      months: [
        month(
          "Jan",
          31,
          23,
          80,
          8,
          "Muito quente: Trajes de banho, shorts, camisetas bem leves, chinelos, chapéu e muito protetor solar."
        ),
        month(
          "Fev",
          32,
          24,
          75,
          8,
          "Calor intenso: Prefira tecidos super respiráveis (linho/viscose). Óculos escuros e hidratação constante."
        ),
        month(
          "Mar",
          31,
          23,
          90,
          7,
          "Úmido e abafado: Guarda-chuva de bolso ou capa leve é uma boa pedida para pancadas rápidas de verão."
        ),
        month(
          "Abr",
          29,
          22,
          65,
          7,
          "Super agradável: Ótimo clima para passear. Roupas de praia de dia, blusa fina para ar condicionado à noite."
        ),
        month(
          "Mai",
          27,
          20,
          50,
          6,
          "Fresco tropical: Perfeito para explorar a pé. Use calçados confortáveis e roupas casuais respiráveis."
        ),
        month(
          "Jun",
          26,
          19,
          40,
          6,
          "Noites frescas: Jaqueta jeans ou cardigan leve para noites na orla marítima. Roupa de praia de dia."
        ),
        month(
          "Jul",
          26,
          18,
          35,
          6,
          "Época seca e fresca: Dias lindos de sol suave. Excelente para passeios ao ar livre sem calor sufocante."
        ),
        month(
          "Ago",
          27,
          19,
          30,
          7,
          "Sol garantido: Dias limpos e ventos agradáveis. Protetor solar e óculos continuam indispensáveis."
        ),
        month(
          "Set",
          28,
          20,
          45,
          7,
          "Primavera quente: Clima esquentando rapidamente. Roupas frescas para o dia e calça leve para a noite."
        ),
        month(
          "Out",
          29,
          21,
          60,
          7,
          "Calor de volta: Vestidos leves, shorts curtos, sandálias anatômicas e chapéu de praia."
        ),
        month(
          "Nov",
          30,
          22,
          75,
          7,
          "Quente e úmido: Camisas leves de algodão. Carregue água e repelente de insetos se for caminhar na natureza."
        ),
        month(
          "Dez",
          31,
          23,
          85,
          8,
          "Verão de férias: Trajes de banho, chinelos de dedo, roupas soltas e protetor solar de alto fator facial."
        )
      ]
    }
  end

  defp desert_profile do
    %{
      climate_type: "Desértico / Árido Extremo",
      description:
        "Marcado por temperaturas escaldantes sob o sol direto e noites que resfriam rapidamente. A precipitação é quase nula, e a umidade do ar é extremamente baixa.",
      best_months: "Outubro a Abril (evitando o calor insuportável de deserto do meio do ano)",
      months: [
        month(
          "Jan",
          19,
          9,
          5,
          8,
          "Inverno desértico: Dias frescos e deliciosos, mas noites bem frias! Vista jaqueta corta-vento e bota."
        ),
        month(
          "Fev",
          21,
          10,
          4,
          9,
          "Clima perfeito de dia: Óculos escuro, protetor labial super-hidratante e jaqueta grossa para a noite."
        ),
        month(
          "Mar",
          25,
          13,
          5,
          9,
          "Transição excelente: Use calças finas e camisas de linho compridas contra sol, e casaco quente à noite."
        ),
        month(
          "Abr",
          30,
          17,
          2,
          10,
          "Esquentando: Roupas soltas de cores claras, lenço de pescoço para poeira, óculos de sol e chapéu abas largas."
        ),
        month(
          "Mai",
          35,
          21,
          1,
          11,
          "Aquecimento extremo: Proteções com manga longa anti-UV e garrafas térmicas com gelo."
        ),
        month(
          "Jun",
          39,
          24,
          0,
          12,
          "Auge escaldante: Evite sol das 11h às 16h. Roupas de proteção solar total e sapatos fechados grossos."
        ),
        month(
          "Jul",
          41,
          25,
          0,
          12,
          "Ardor desértico: Tecidos de algodão leve, óculos polarizados, hidratação extrema com eletrólitos."
        ),
        month(
          "Ago",
          40,
          25,
          0,
          11,
          "Extremo calor: Planeje passeios em locais com ar-condicionado. Use filtro solar FPS 60."
        ),
        month(
          "Set",
          36,
          23,
          0,
          10,
          "Sol escaldante constante: Roupas respiráveis e bonés. Noites ficam respiráveis para passeios ao luar."
        ),
        month(
          "Out",
          31,
          19,
          1,
          9,
          "Clima espetacular de volta: Shorts leves, calçados resistentes de trilha, jaqueta leve aconchegante para as noites."
        ),
        month(
          "Nov",
          25,
          14,
          3,
          8,
          "Clima super ameno: Ideal para turismo arqueológico. Traga moletom ou blazer para as noites."
        ),
        month(
          "Dez",
          20,
          10,
          5,
          8,
          "Noites frias desérticas: Camisola térmica, blusa grossa de lã, corta-vento com capuz e calça comprida."
        )
      ]
    }
  end

  defp southern_temperate_profile do
    %{
      climate_type: "Temperado Subtropical / Sul",
      description:
        "Estações bem definidas com verões quentes e chuvosos (Dezembro a Março) e invernos mais secos e refrescantes (Junho a Agosto). Clima muito confortável que se adapta a atividades a pé.",
      best_months:
        "Abril a Novembro (frescor ameno, noites agradáveis com menos chuvas torrenciais)",
      months: [
        month(
          "Jan",
          29,
          20,
          85,
          7,
          "Verão quente e úmido: Leve shorts, vestidos leves, sandálias e guarda-chuva robusto na mochila."
        ),
        month(
          "Fev",
          29,
          20,
          80,
          7,
          "Alta umidade/Calor: Roupas frescas de algodão, óculos de sol e protetor solar frequente."
        ),
        month(
          "Mar",
          28,
          19,
          75,
          6,
          "Fim do verão: Clima abafado, traga calças confortáveis e capas finas de chuva para passeios na rua."
        ),
        month(
          "Abr",
          25,
          16,
          50,
          6,
          "Outono agradável: Dias lindos de céu azul ameno. Vista jaqueta leve de nylon ou cardigan para o fim de tarde."
        ),
        month(
          "Mai",
          22,
          13,
          45,
          5,
          "Fresco e adorável: Suéter fino, jaquetas jeans ou casacos de moletom médios. Sapatos confortáveis de couro/tênis."
        ),
        month(
          "Jun",
          21,
          11,
          40,
          5,
          "Inverno fresco: Casacos médios de lã ou jaquetas de couro. Cachecol leve é ótimo ao anoitecer."
        ),
        month(
          "Jul",
          21,
          10,
          35,
          5,
          "Frio moderado e seco: Ótimos dias de sol com vento gelado. Vista camadas (camiseta + suéter + jaqueta)."
        ),
        month(
          "Ago",
          23,
          11,
          30,
          6,
          "Vento seco de inverno: Use protetor solar e hidratante labial. Prepare jaqueta leve caso esquente ao meio dia."
        ),
        month(
          "Set",
          24,
          13,
          55,
          6,
          "Primavera amena: Noites deliciosas, dias secos. Roupas versáteis de camadas fáceis de carregar na mochila."
        ),
        month(
          "Out",
          26,
          15,
          65,
          6,
          "Esquentando gradativamente: Camisas polos do dia a dia, blusas leves de viscose e óculos escuros."
        ),
        month(
          "Nov",
          27,
          17,
          70,
          7,
          "Clima pré-verão: Pratique esportes com sapatos confortáveis. Leve shorts e roupas confortáveis para caminhadas demoradas."
        ),
        month(
          "Dez",
          28,
          19,
          80,
          7,
          "Início do verão: Chapéu, boné e garrafa térmica para caminhadas. Alertas de chuvas de verão rápidas."
        )
      ]
    }
  end

  defp northern_temperate_profile do
    %{
      climate_type: "Temperado Continental / Norte",
      description:
        "Quatro estações perfeitamente distintas. Invernos charmosos com neblinas ou geadas e verões quentes de sol tardio. A primavera e outono oferecem cenários deslumbrantes com temperaturas amenas.",
      best_months:
        "Maio a Junho (temperaturas ótimas) ou Setembro a Outubro (folhagens de outono douradas)",
      months: [
        month(
          "Jan",
          6,
          1,
          60,
          3,
          "Inverno frio: Casaco grosso (puffer/lã), luvas quentes, gorro cobrindo orelhas e meias térmicas grossas."
        ),
        month(
          "Fev",
          7,
          1,
          55,
          4,
          "Vento e geada: Casaco de lã pesada ou jaqueta de pluma, cachecol volumoso e calçados forrados confortáveis."
        ),
        month(
          "Mar",
          12,
          4,
          50,
          5,
          "Frio de transição: Casacos médios (estilo casaco jeans pesado ou trenchcoat), calça jeans reforçada e suéter."
        ),
        month(
          "Abr",
          16,
          7,
          55,
          6,
          "Primavera fresca: Cenário lindo! Vista casaco corta-vento leve por cima de blusas básicas e leve guarda-chuva."
        ),
        month(
          "Mai",
          20,
          11,
          65,
          7,
          "Clima glorioso: Perfeito para turismo! Use calça leve, sapatilhas ou tênis e traga jaqueta fina extra."
        ),
        month(
          "Jun",
          24,
          14,
          60,
          8,
          "Verão agradabilíssimo: Roupas leves (shorts, camisetas), óculos escuros e calçados anatômicos para pedestres."
        ),
        month(
          "Jul",
          27,
          16,
          55,
          9,
          "Sol abundante e quente: Use protetor solar facial, boné, vestidos soltos e óculos escuros."
        ),
        month(
          "Ago",
          27,
          16,
          50,
          8,
          "Dias quentes e ensolarados: Perfeito para parques e praias. Chapéu, óculos e hidratantes pós-sol."
        ),
        month(
          "Set",
          22,
          13,
          55,
          6,
          "Clima perfeito de outono: Jaquetas de veludo, lenços charmosos para vento e tênis excelente de caminhada."
        ),
        month(
          "Out",
          16,
          9,
          60,
          4,
          "Outono fresco: Jaquetas acolchoadas finas, meias de algodão confortáveis, blusas de gola alta e cachecol leve."
        ),
        month(
          "Nov",
          10,
          5,
          60,
          3,
          "Frio chegando forte: Sobretudo grosso pronto para vento, luvas de couro ou lã fina, sapatos fechados isolados."
        ),
        month(
          "Dez",
          7,
          2,
          65,
          2,
          "Inverno natalino: Jaqueta puffer pesada impermeável, segunda pele térmica (calça e blusa) e botas antiderrapantes."
        )
      ]
    }
  end
end
