# Heathy — nutrition data (MCP server)

Nutrition for **917 whole plant foods** and **39 Ayurvedic herbs**, reconciled across
**11 national food-composition datasets** — including **IFCT 2017 (India)**, which
isn't available as an API anywhere else.

**Endpoint:** `https://mcp.heathy.org/mcp` — Streamable HTTP (JSON-RPC 2.0)
**Website:** <https://heathy.org> · **Contact:** hello@heathy.org
**Free while in preview.**

> This repository contains **documentation only** — the manifest and these notes.
> The server is hosted; there is nothing to install.

---

## What makes it different

Most nutrition APIs hand back a single number from a single national table. This one
returns the number *and its provenance*:

- the **median** across every dataset that has the food,
- **how many** sources contributed and **which** ones,
- the **min–max spread** between them.

So an agent can cite a figure instead of asserting it, and can tell when the sources
disagree. Guava vitamin C, for example, comes back as `228 mg` from **10 sources**
with a range of `99.2–273` — a spread worth knowing about before stating it as fact.

**Indian foods are the standout.** IFCT 2017 isn't queryable as an API elsewhere, so
questions about karela, horse gram or millets get real data rather than a US
substitute.

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
<https://mcp.heathy.org/>.

## Tools

### `lookup_food`

Full per-100 g nutrient profile for a whole plant food, with provenance.

| Argument | Type | |
|---|---|---|
| `food` | string | **required** — slug, common name, or regional alias |
| `nutrients` | string[] | optional — limit to specific nutrients rather than all ~168 |

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
| `min_sources` | integer | optional — exclude thinly-sourced outliers |

### `herb_monograph`

An Ayurvedic herb monograph. Traditional use and modern research are kept **strictly
separate** — `traditional` records what the tradition claims, `modern` records what
research shows with an evidence tier. **Every response carries a mandatory `safety`
block** (cautions, pregnancy guidance, drug interactions).

| Argument | Type | |
|---|---|---|
| `herb` | string | **required** — English, Sanskrit, Hindi or botanical name |

## Examples

| Call | Result |
|---|---|
| `search_foods("karela")` | `gourd-karela-raw` |
| `lookup_food("guava", ["vitamin-c"])` | 228 mg · 10 sources · range 99.2–273 |
| `nutrient_ranking("iron", category: "legume")` | horse gram 8.76 mg · soya bean 8.29 mg |
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

USDA FoodData Central · UK CoFID · **IFCT 2017 (ICMR–NIN, India)** · ANSES-Ciqual
(France) · BLS (Germany) · Frida (Denmark) · Matvaretabellen (Norway) · MEXT (Japan)
· TACO (Brazil) · FAO/INFOODS WAFCT (West Africa).

Full credits and licence terms: <https://heathy.org/sources/>

## Licence and terms

Repository documentation is released under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Composition figures
are open government data, credited per response and at the link above. The
reconciliation, recipes, herb monographs and original content are © Heathy — see
<https://heathy.org/terms/>. Use of the hosted service at mcp.heathy.org is governed
by those terms.

**Not medical advice.** The data is informational and does not diagnose or treat
anything. A 100% raw-vegan diet does not supply adequate vitamin B12 or vitamin D.
