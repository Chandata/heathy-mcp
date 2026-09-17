# Heathy — nutrition data (MCP server)

[![heathy-mcp MCP server — quality and maintenance score on Glama](https://glama.ai/mcp/servers/Chandata/heathy-mcp/badges/score.svg)](https://glama.ai/mcp/servers/Chandata/heathy-mcp)

Nutrition for **1,174 whole plant foods** and **39 Ayurvedic herbs**, drawn from
**30 food-composition tables covering 26 countries** plus West Africa, the Pacific and
FAO's global biodiversity table — including **IFCT 2017 (India)**, which isn't available
as an API anywhere else. It also answers **which GB/EU and US nutrition claims** the
published data supports for a raw whole food.

**Endpoint:** `https://mcp.heathy.org/mcp` — Streamable HTTP (JSON-RPC 2.0)
**Website:** <https://heathy.org> · **Contact:** hello@heathy.org
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

**Indian foods are the standout.** IFCT 2017 isn't queryable as an API elsewhere, so
questions about karela, horse gram or millets get real data rather than a US
substitute.

### How far the cross-checking goes

Be aware of coverage when you use the data:

- **494 foods** are held by two or more tables — up to 25 for common produce.
- **680 foods** come from a **single table**. Their `sources` count is `1`; there is
  nothing to cross-check them against. Use `min_sources` on `nutrient_ranking` to
  keep these out of a ranking.
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

Full per-100 g nutrient profile for a whole plant food, with provenance.

| Argument | Type | |
|---|---|---|
| `food` | string | **required** — slug, common name, or regional alias |
| `nutrients` | string[] | optional — limit to specific nutrients rather than the full profile |

The full profile covers 130 nutrients, plus 67 research-tier ones marked
`tier: "research"` (thin coverage, or a restatement of another nutrient).

### `search_foods`

Resolve a name to a slug, including Hindi, Sanskrit and botanical aliases. Call this
first when you have a plain-English or local name.

| Argument | Type | |
|---|---|---|
| `query` | string | **required** |
| `kind` | `food` \| `herb` \| `any` | optional, default `any` |
| `limit` | integer | optional, 1–50, default 10 |

### `nutrient_ranking`

Rank foods by a nutrient per 100 g — the "highest in iron" question.

| Argument | Type | |
|---|---|---|
| `nutrient` | string | **required** — slug or name |
| `limit` | integer | optional, 1–100, default 20 |
| `category` | string | optional — e.g. `fruit`, `legume`, `millet` |
| `min_sources` | integer | optional — exclude single-source and thinly-sourced values |

### `herb_monograph`

An Ayurvedic herb monograph. Traditional use and modern research are kept **strictly
separate** — `traditional` records what the tradition claims, `modern` records what
research shows with an evidence tier. **Every response carries a mandatory `safety`
block** (cautions, pregnancy guidance, drug interactions).

| Argument | Type | |
|---|---|---|
| `herb` | string | **required** — English, Sanskrit, Hindi or botanical name |

### `check_claim`

For a **raw** whole food, which nutrition claims ("source of potassium", "high in
vitamin C") the data supports under **GB/EU** rules (Reg. 1924/2006, per 100 g) and
**US** rules (21 CFR 101.54, per RACC). It flags where the answer **depends on which
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
at the final product, not at a reference table. Never use it to pick whichever table
qualifies.

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
"anaemia"). Topics people reach for with a diagnosis carry an explicit note on what
the evidence does **and does not** support — reproduce it rather than summarising it
away. Omit `topic` to list every topic.

| Argument | Type | |
|---|---|---|
| `topic` | string | optional — goal slug or title, or a condition name |
| `include_recipes` | boolean | optional, default `true` |

## Examples

| Call | Result |
|---|---|
| `search_foods("karela")` | `gourd-karela-raw` |
| `lookup_food("guava", ["vitamin-c"])` | 222 mg · median of 13 tables · range 68–273 |
| `nutrient_ranking("iron", category: "legume", min_sources: 3)` | brown lentil 8 mg · white soya bean 7.6 mg · chickpea 5.4 mg |
| `check_claim("banana", nutrient: "potassium")` | GB/EU "source of" supported at 326 mg — but 5 tables support it and 4 don't |
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

**Please reproduce `attribution` and `disclaimer` when you use a response, and cite
`source_url`.** For herbs, surface the `safety` block alongside any information you
pass on.

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
no national table covers

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
