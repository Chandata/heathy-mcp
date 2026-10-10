# Heathy — nutrition data (MCP server)

[![heathy-mcp MCP server — quality and maintenance score on Glama](https://glama.ai/mcp/servers/Chandata/heathy-mcp/badges/score.svg)](https://glama.ai/mcp/servers/Chandata/heathy-mcp)

Nutrition for **more than 1,100 whole plant foods and their flours** and **39 Ayurvedic
herbs**, drawn from **30 food-composition tables covering 26 countries** plus West Africa,
the Pacific and FAO's global biodiversity table — including **IFCT 2017 (India)**. It also
answers **which GB/EU and US nutrition claims** the published data supports for a raw whole
food or an unfortified flour.

**Endpoint:** `https://mcp.heathy.org/mcp` — Streamable HTTP (JSON-RPC 2.0)
**Website:** <https://heathy.org> · **Contact:** hello@heathy.org
**Operated by** CCT Technologies Ltd (England & Wales, company no. 06337577)
**Free while in preview.**

> This repository contains no server code — only the manifest, these notes and a
> `Dockerfile`. The server is hosted; there is nothing to install. The `Dockerfile`
> only bridges stdio to the hosted endpoint, for directories that inspect servers in
> a container.

---

## What makes it different

Most nutrition APIs hand back a single number from a single national table. This one
returns the number *and its provenance*:

- the **median** across the datasets that have the food,
- **how many** sources contributed and **which** ones,
- the **min–max spread** between them, and every source's own value.

So an agent can cite a figure instead of asserting it, and can tell when the sources
disagree. Guava vitamin C, for example, comes back as `222 mg` — the median of
**13 tables**, ranging `68–273` — with 20 national values listed side by side.
That spread is real: soil, cultivar and analytical method differ between countries,
and it is worth knowing before stating a figure as fact.

**Indian foods are covered from IFCT 2017**, so questions about karela, horse gram or
millets are answered from Indian data rather than a US substitute.

### How far the cross-checking goes

Be aware of coverage when you use the data:

- **Fewer than half the foods** are held by two or more tables — up to 26 for common
  produce.
- **More than half** come from a **single table**. Their `sources` count is `1`; there is
  nothing to cross-check them against. Use `min_sources` on `nutrient_ranking` to
  keep these out of a ranking; they are then listed beside it.
- Some tables' licences allow their figures to be **shown but not averaged**. Those
  values appear under `by_source` but are not folded into the median, which is why
  `sources` can be lower than the number of values listed.

## Connecting

Add to any MCP client that supports remote servers:

```json
{
  "mcpServers": {
    "heathy": {
      "type": "streamable-http",
      "url": "https://mcp.heathy.org/mcp"
    }
  }
}
```

No API key, no signup. A service card describing the server is at
<https://mcp.heathy.org/.well-known/mcp/server-card.json>.

## Tools

### `lookup_food`

Full per-100 g nutrient profile for a whole plant food or flour, with provenance.

| Argument | Type | |
|---|---|---|
| `food` | string | **required** — slug, common name, or regional alias |
| `nutrients` | string[] | optional — limit to specific nutrients rather than the full profile |

The full profile covers about 130 nutrients, plus a research tier marked
`tier: "research"` (thin coverage, or a restatement of another nutrient).

What comes back when the name is not an exact match:

- **An everyday name** ("potato", "kela", "besan") opens the food most national tables
  carry. When the match was loose, the answer says so in `matched_from`, with the other
  foods it could have meant.
- **Everyday nutrient names** ("fiber", "omega 3", "calories", "vit c") are understood. A
  name that is not is listed in `unrecognised_nutrients`; the rest of the answer is returned.
- **A cooked or prepared form** ("lentils boiled", "brown rice cooked") is refused, and the
  reply names the unprepared food that is held. The unprepared figures are not returned in
  its place: per 100 g they are a different food.
- **A food that is not held** — animal foods, foods made from plants (tofu, pasta, sugar),
  refined wheat flours — gets a reply saying which of those it is.

### `search_foods`

Resolve a name to a slug, including Hindi, Sanskrit and botanical aliases. Returns
ranked candidates for a plain-English or local name.

| Argument | Type | |
|---|---|---|
| `query` | string | **required** |
| `kind` | `food` \| `herb` \| `any` | optional, default `any` |
| `limit` | integer | optional, 1–50, default 10 |

### `nutrient_ranking`

Rank foods by a nutrient per 100 g — the "highest in iron" question. Each row also gives
the typical serving heathy.org holds for the food and the amount in it; the order is per
100 g.

Foods eaten a few grams at a time — dried herbs, spices, tea leaves, and dried seaweed,
mushrooms and vegetables, 102 foods — are not ranked in `results`. They are reported
beside it in `also_higher.small_amounts`: a count of those holding more per 100 g than the
last row, and the first five. They are ranked in `results` when `include_small_amounts` is
true, and when the category asked for is mostly such foods (`spice`, `tea`, `seaweed`).

| Argument | Type | |
|---|---|---|
| `nutrient` | string | **required** — slug or name |
| `limit` | integer | optional, 1–100, default 20 |
| `category` | string | optional — e.g. `fruit`, `legume`, `millet` |
| `min_sources` | integer | optional, default 1 — smallest number of sources for a food to be ranked; foods below it are reported in `also_higher.fewer_sources` |
| `include_small_amounts` | boolean | optional, default false — rank spices, tea and dried seaweed with every other food |

### `herb_monograph`

An Ayurvedic herb monograph. Traditional use and modern research are kept **strictly
separate** — `traditional` records what the tradition claims, `modern` records what
research shows with an evidence tier. **Every response carries a mandatory `safety`
block** (cautions, pregnancy guidance, drug interactions).

| Argument | Type | |
|---|---|---|
| `herb` | string | **required** — English, Sanskrit, Hindi or botanical name |

### `check_claim`

For a **raw** whole food or an **unfortified single-ingredient flour**, which nutrition
claims ("source of potassium", "high in vitamin C") the data supports under **GB/EU** rules
(Reg. 1924/2006, per 100 g) and **US** rules (21 CFR 101.54, per RACC). It flags where the answer **depends on which
national table was used**, listing the tables that do and don't support it.

| Argument | Type | |
|---|---|---|
| `food` | string | **required** — slug or name |
| `nutrient` | string | optional — check one nutrient only |
| `market` | `uk` \| `us` \| `both` | optional, default `both` |
| `only_permitted` | boolean | optional — return only supported claims |
| `preparation` | `raw` | optional, and the only value accepted |

**Scope.** This is a screening tool, not permission to make a claim. It refuses cooked
and manufactured products, whose composition depends on recipe and processing. A
supported claim still needs an analysis of the producer's own produce: the law looks
at the final product, not at a reference table. It lists the tables that do and do not
support a claim; it does not choose one that qualifies.

### `search_recipes`

Find original raw / no-cook vegan recipes on Heathy by free text, health goal,
category, ingredient, time or allergen. Per-serving nutrition is computed from the
same food rows `lookup_food` returns.

| Argument | Type | |
|---|---|---|
| `query` | string | optional — free text, e.g. `breakfast` |
| `goal` | string | optional — e.g. `immune`, `bone`, `gut`, `heart` |
| `category` | string | optional — e.g. `smoothies`, `salads`, `chutneys` |
| `ingredient` | string | optional — food slug or name that must appear |
| `max_time` | integer | optional — total minutes |
| `exclude_allergens` | string[] | optional — e.g. `["tree-nuts","sesame"]` |
| `limit` | integer | optional, 1–50, default 10 |

### `get_recipe`

One recipe in full: ingredients with food slugs and gram weights, method,
per-serving nutrition, allergens and carbon footprint.

| Argument | Type | |
|---|---|---|
| `recipe` | string | **required** — slug or name |

### `health_topic`

What to eat for a health goal — the nutrients involved, why each one, and which raw
recipes carry them. Accepts a goal ("gut health") or a named condition ("PCOS",
"anaemia"). Topics people reach for with a diagnosis carry a note on what the evidence
does **and does not** support, with its own evidence rating. Omit `topic` to list every
topic.

| Argument | Type | |
|---|---|---|
| `topic` | string | optional — goal slug or title, or a condition name |
| `include_recipes` | boolean | optional, default `true` |

## Examples

| Call | Result |
|---|---|
| `search_foods("karela")` | `gourd-karela-raw` |
| `lookup_food("guava", ["vitamin-c"])` | 222 mg · median of 13 tables · range 68–273 |
| `lookup_food("besan", ["protein"])` | `chickpea-flour` · 22.39 g · 3 tables |
| `lookup_food("lentils boiled")` | refused — names `lentil-whole-brown`, held unprepared |
| `nutrient_ranking("iron", category: "legume", min_sources: 3)` | brown lentil 8 mg · white soybean 7.91 mg · chickpea 5.4 mg |
| `nutrient_ranking("magnesium")` | hulled hemp seed 591.5 mg (177.4 mg per 30 g) first · 37 foods eaten a few grams at a time counted beside the list, led by dried sea lettuce 3,200 mg |
| `check_claim("banana", nutrient: "potassium")` | GB/EU "source of" supported at 335 mg — 16 of 21 tables support it and 5 don't |
| `health_topic("anaemia")` | `iron-deficiency-anaemia` — nutrients, reasons, recipes |
| `herb_monograph("haldi")` | turmeric — traditional, research, safety |

## Response shape

Every tool returns the same envelope:

```jsonc
{
  "data":        { /* the payload */ },
  "attribution": ["USDA FoodData Central …", "IFCT 2017, ICMR–NIN …"],
  "source_url":  "https://heathy.org/food/guava-flesh-only-raw/",
  "disclaimer":  "Informational only — not medical advice.",
  "license":     "https://heathy.org/terms/"
}
```

Each response includes `attribution`, `disclaimer` and `source_url`; herb responses
also include a `safety` block with cautions, pregnancy guidance and drug interactions.
The terms at <https://heathy.org/terms/> ask that figures you republish carry the
attribution.

## Data sources

**Americas** — USDA FoodData Central (Foundation Foods and SR Legacy) · Canadian
Nutrient File · TACO (Brazil) · INCMNSZ (Mexico) · ARGENFOODS (Argentina)

**Europe** — UK CoFID · ANSES-Ciqual (France) · BLS (Germany) · Frida (Denmark) ·
Matvaretabellen (Norway) · Livsmedelsverket (Sweden) · Fineli (Finland) · NEVO
(Netherlands) · CREA (Italy) · Swiss FCDB · NutriData (Estonia)

**Asia** — **IFCT 2017 (ICMR–NIN, India)** · MEXT (Japan) · China CFCT · Korea MFDS ·
Singapore SG FoodID · Pakistan FCT · Sri Lanka FCT

**Africa and Oceania** — FAO/INFOODS WAFCT (West Africa) · Kenya KFCT · Ethiopia
EFCT · Australia AFCD (FSANZ) · Pacific Nutrient Database

**Global** — FAO/INFOODS BioFoodComp · open-licence (CC BY) research papers for foods
no national table covers · Phenol-Explorer (polyphenol content, shown but not averaged)

Full credits and licence terms: <https://heathy.org/sources/>

## Licence and terms

The files in this repository (documentation, manifest and Dockerfile) are released under
the [MIT licence](LICENSE). That licence covers this repository only. Composition figures
come from the published tables above, each under its own terms, and are credited per
response and at the link above. The reconciliation, recipes, herb monographs and
original content are © Heathy — see <https://heathy.org/terms/>. Use of the hosted
service at mcp.heathy.org is governed by those terms.

**Not medical advice.** The data is informational and does not diagnose or treat
anything. A 100% raw-vegan diet does not supply adequate vitamin B12 or vitamin D.
